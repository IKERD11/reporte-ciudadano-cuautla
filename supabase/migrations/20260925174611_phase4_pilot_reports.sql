begin;
create extension if not exists pg_jsonschema with schema extensions;
alter table public.settings add column pilot_reports_enabled boolean not null default false;
alter table public.reports add column is_pilot boolean not null default false;
create table private.report_uploads (
 id uuid primary key default gen_random_uuid(), actor uuid not null references public.profiles(id),
 municipality_id uuid not null references public.municipalities(id), request_key uuid not null,
 payload jsonb not null, created_at timestamptz not null default now(),
 expires_at timestamptz not null default now()+interval '24 hours', committed_at timestamptz,
 purged_at timestamptz, unique(actor,request_key)
);
alter table private.report_uploads enable row level security;
revoke all on private.report_uploads from public,anon,authenticated;
create index report_uploads_municipality_idx on private.report_uploads(municipality_id);
create index report_uploads_expiry_idx on private.report_uploads(expires_at) where committed_at is null and purged_at is null;

create function private.report_pilot(p_actor uuid,p_session uuid,p_action text,p_key uuid default null,p_payload jsonb default '{}',p_report uuid default null,p_offset integer default 0,p_filter text default 'ALL') returns jsonb
language plpgsql security definer set search_path='' as $$
declare pr public.profiles; cat public.categories; ticket private.report_uploads; d jsonb; im jsonb; output jsonb; paths jsonb;
 sid uuid; lat double precision; lon double precision; n integer; path text; r public.reports;
begin
 if not exists(select 1 from auth.users u join auth.sessions s on s.user_id=u.id
   where u.id=p_actor and s.id=p_session and (s.not_after is null or s.not_after>now())
   and u.email_confirmed_at is not null and not coalesce(u.is_anonymous,false)
   and u.deleted_at is null and (u.banned_until is null or u.banned_until<=now())) then
   raise exception 'Sesión no autorizada' using errcode='42501'; end if;
 select * into pr from public.profiles where id=p_actor and is_active and deleted_at is null;
 if not found or not exists(select 1 from public.municipalities where id=pr.municipality_id and is_active) then
   raise exception 'Perfil no disponible' using errcode='42501'; end if;
 if p_action='context' then
   select coalesce(jsonb_agg(jsonb_build_object('id',c.id,'name',c.name,'description',c.description,'requires_photo',c.requires_photo,
     'requires_location',c.requires_location,'schema',c.dynamic_form_schema,'subcategories',
     (select coalesce(jsonb_agg(jsonb_build_object('id',s.id,'name',s.name) order by s.sort_order,s.name),'[]') from public.subcategories s where s.category_id=c.id and s.is_active)) order by c.sort_order,c.name),'[]') into output
   from public.categories c where c.municipality_id=pr.municipality_id and c.is_active and c.is_public;
   return jsonb_build_object('categories',output,'enabled',coalesce((select pilot_reports_enabled from public.settings where municipality_id=pr.municipality_id),false),'max_images',3,'mode','pilot');
 end if;
 if p_action='list' then
   if p_offset is null or p_offset<0 or p_offset>10000 or p_filter not in ('ALL','PENDING','EN_ATENCION','RESUELTO','CERRADO') then raise exception 'Filtro inválido' using errcode='22023'; end if;
   select coalesce(jsonb_agg(x.v order by x.created_at desc,x.id desc),'[]') into output from (
    select r.id,r.created_at,jsonb_build_object('id',r.id,'folio',r.folio,'category',c.name,'status',s.name,'status_code',s.code,'priority',p.name,'created_at',r.created_at,'address',r.approximate_address,'is_pilot',r.is_pilot,
     'image_id',(select i.id from public.report_images i where i.report_id=r.id order by i.created_at,i.id limit 1)) v
    from public.reports r join public.categories c on c.id=r.category_id join public.report_statuses s on s.id=r.status_id join public.priorities p on p.id=r.priority_id
    where r.citizen_id=p_actor and r.municipality_id=pr.municipality_id and (p_filter='ALL' or s.code=p_filter or (p_filter='PENDING' and not s.is_terminal and s.code<>'EN_ATENCION'))
    order by r.created_at desc,r.id desc limit 20 offset p_offset) x;
   return jsonb_build_object('reports',output,'page_size',20);
 end if;
 if p_action in ('detail','image') then
   select * into r from public.reports where id=p_report and citizen_id=p_actor and municipality_id=pr.municipality_id;
   if not found then raise exception 'Reporte no disponible' using errcode='42501'; end if;
   if p_action='image' then
    select storage_path into path from public.report_images where report_id=r.id and id=(p_payload->>'image_id')::uuid;
    if path is null then raise exception 'Imagen no disponible' using errcode='42501'; end if;
    return jsonb_build_object('path',path);
   end if;
   return jsonb_build_object('id',r.id,'folio',r.folio,'is_pilot',r.is_pilot,'description',r.description,'address',r.approximate_address,'created_at',r.created_at,
    'latitude',extensions.st_y(r.location::extensions.geometry),'longitude',extensions.st_x(r.location::extensions.geometry),'additional_data',r.additional_data,'schema',r.form_schema_snapshot,
    'category',(select name from public.categories where id=r.category_id),'priority',(select name from public.priorities where id=r.priority_id),'status',(select name from public.report_statuses where id=r.status_id),
    'images',(select coalesce(jsonb_agg(jsonb_build_object('id',id)),'[]') from public.report_images where report_id=r.id),
    'timeline',(select coalesce(jsonb_agg(jsonb_build_object('status',s.name,'created_at',h.created_at) order by h.created_at),'[]') from public.report_status_history h join public.report_statuses s on s.id=h.new_status_id where h.report_id=r.id));
 end if;
 if p_action not in ('reserve','commit') or p_key is null then raise exception 'Acción inválida' using errcode='22023'; end if;
 if not exists(select 1 from public.settings where municipality_id=pr.municipality_id and pilot_reports_enabled)
   or not private.identity_permission(p_actor,pr.municipality_id,'reports.create') then
   raise exception 'Piloto no habilitado' using errcode='42501'; end if;
 -- Serializar cuota e idempotencia por ciudadano; nunca confiar en estado/prioridad del cliente.
 perform 1 from public.profiles where id=p_actor for update;
 select * into ticket from private.report_uploads where actor=p_actor and request_key=p_key for update;
 if found then
   if ticket.payload is distinct from p_payload then raise exception 'El reintento debe conservar los datos' using errcode='22023'; end if;
   if ticket.committed_at is not null then
    return (select jsonb_build_object('id',id,'folio',folio,'committed',true) from public.reports where id=ticket.id);
   end if;
   if ticket.expires_at<=now() or ticket.purged_at is not null then raise exception 'Solicitud vencida' using errcode='42501'; end if;
 elsif p_action='commit' then raise exception 'Reserva requerida' using errcode='42501';
 end if;
 d:=p_payload;
 if jsonb_typeof(d) is distinct from 'object' or d->'consent' is distinct from 'true'::jsonb or length(d::text)>20000
  or length(trim(coalesce(d->>'description',''))) not between 10 and 5000 or length(coalesce(d->>'address',''))>500
  or jsonb_typeof(d->'images') is distinct from 'array' or jsonb_array_length(d->'images')>3 then
  raise exception 'Datos del reporte inválidos' using errcode='22023'; end if;
 select * into cat from public.categories where id=(d->>'category_id')::uuid and municipality_id=pr.municipality_id and is_active and is_public;
 if not found or not exists(select 1 from public.priorities where id=cat.default_priority_id and is_active) then raise exception 'Categoría no disponible' using errcode='22023'; end if;
 if nullif(d->>'subcategory_id','') is not null and not exists(select 1 from public.subcategories where id=(d->>'subcategory_id')::uuid and category_id=cat.id and municipality_id=pr.municipality_id and is_active) then raise exception 'Subcategoría inválida' using errcode='22023'; end if;
 if not coalesce(extensions.jsonb_matches_schema(cat.dynamic_form_schema::json,d->'additional_data'),false) then raise exception 'Revisa los campos adicionales' using errcode='22023'; end if;
 lat:=(d->>'latitude')::double precision; lon:=(d->>'longitude')::double precision;
 if (lat is null)<>(lon is null) or (cat.requires_location and lat is null) or lat not between -90 and 90 or lon not between -180 and 180 then raise exception 'Ubicación inválida' using errcode='22023'; end if;
 if d->>'gps_accuracy' is not null and (d->>'gps_accuracy')::numeric not between 0 and 100000 then raise exception 'Precisión inválida' using errcode='22023'; end if;
 if d->>'captured_at' is not null and ((d->>'captured_at')::timestamptz>now()+interval '5 minutes' or (d->>'captured_at')::timestamptz<now()-interval '7 days') then raise exception 'Fecha GPS inválida' using errcode='22023'; end if;
 if cat.requires_photo and jsonb_array_length(d->'images')=0 then raise exception 'Fotografía requerida' using errcode='22023'; end if;
 for im in select value from jsonb_array_elements(d->'images') loop
  if (im->>'size')::integer not between 1 and 700000 or coalesce(im->>'sha256','') !~ '^[0-9a-f]{64}$' then raise exception 'Foto inválida' using errcode='22023'; end if;
 end loop;
 if ticket.id is null then
  if (select count(*) from private.report_uploads where actor=p_actor and created_at>now()-interval '1 day')>=5 then raise exception 'Límite de cinco reportes diarios' using errcode='54000'; end if;
  insert into private.report_uploads(actor,municipality_id,request_key,payload) values(p_actor,pr.municipality_id,p_key,d) returning * into ticket;
 end if;
 select coalesce(jsonb_agg(pr.municipality_id::text||'/'||p_actor::text||'/'||ticket.id::text||'/'||i::text||'.jpg' order by i),'[]') into paths from generate_series(0,jsonb_array_length(d->'images')-1) i;
 if p_action='reserve' then return jsonb_build_object('id',ticket.id,'paths',paths,'committed',false); end if;
 for path in select jsonb_array_elements_text(paths) loop
  if not exists(select 1 from storage.objects where bucket_id='report-evidence' and name=path) then raise exception 'Carga incompleta' using errcode='22023'; end if;
 end loop;
 select id into strict sid from public.report_statuses where code='RECIBIDO';
 insert into public.reports(id,municipality_id,citizen_id,category_id,subcategory_id,priority_id,status_id,description,location,approximate_address,gps_accuracy,captured_at,additional_data,form_schema_snapshot,idempotency_key,is_pilot)
 values(ticket.id,pr.municipality_id,p_actor,cat.id,nullif(d->>'subcategory_id','')::uuid,cat.default_priority_id,sid,trim(d->>'description'),case when lat is not null then extensions.st_setsrid(extensions.st_makepoint(lon,lat),4326)::extensions.geography end,nullif(d->>'address',''),(d->>'gps_accuracy')::numeric,(d->>'captured_at')::timestamptz,d->'additional_data',cat.dynamic_form_schema,p_key,true) returning * into r;
 n:=0;
 for im in select value from jsonb_array_elements(d->'images') loop
  insert into public.report_images(municipality_id,report_id,storage_path,mime_type,size) values(pr.municipality_id,r.id,paths->>n,'image/jpeg',(im->>'size')::integer); n:=n+1;
 end loop;
 update private.report_uploads set committed_at=now() where id=ticket.id;
 insert into public.consents(municipality_id,user_id,consent_type,privacy_notice_version) values(pr.municipality_id,p_actor,'REPORT_PILOT','pilot-v1') on conflict do nothing;
 insert into public.audit_logs(municipality_id,actor_id,action,entity_type,entity_id) values(pr.municipality_id,p_actor,'report.pilot_created','reports',r.id);
 return jsonb_build_object('id',r.id,'folio',r.folio,'committed',true);
end; $$;
create function public.report_pilot_service(p_actor uuid,p_session uuid,p_action text,p_key uuid default null,p_payload jsonb default '{}',p_report uuid default null,p_offset integer default 0,p_filter text default 'ALL') returns jsonb
language sql security invoker set search_path='' as $$ select private.report_pilot(p_actor,p_session,p_action,p_key,p_payload,p_report,p_offset,p_filter); $$;
revoke all on function private.report_pilot(uuid,uuid,text,uuid,jsonb,uuid,integer,text),public.report_pilot_service(uuid,uuid,text,uuid,jsonb,uuid,integer,text) from public,anon,authenticated;
grant execute on function private.report_pilot(uuid,uuid,text,uuid,jsonb,uuid,integer,text),public.report_pilot_service(uuid,uuid,text,uuid,jsonb,uuid,integer,text) to service_role;

create function private.report_upload_purge(p_token text,p_case uuid default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare t private.report_uploads; result jsonb;
begin
 if p_token is null or not exists(select 1 from vault.decrypted_secrets where name='identity_purge_token' and extensions.digest(decrypted_secret,'sha256')=extensions.digest(p_token,'sha256')) then raise exception 'No autorizado' using errcode='42501'; end if;
 if p_case is null then
  select coalesce(jsonb_agg(jsonb_build_object('id',x.id,'paths',(select coalesce(jsonb_agg(x.municipality_id::text||'/'||x.actor::text||'/'||x.id::text||'/'||i::text||'.jpg'),'[]') from generate_series(0,jsonb_array_length(x.payload->'images')-1) i))),'[]') into result
  from (select * from private.report_uploads where committed_at is null and purged_at is null and expires_at<now()-interval '10 minutes' order by expires_at limit 25) x;
  return result;
 end if;
 select * into t from private.report_uploads where id=p_case and committed_at is null and purged_at is null and expires_at<now()-interval '10 minutes' for update;
 if not found then raise exception 'No disponible' using errcode='42501'; end if;
 if exists(select 1 from storage.objects where bucket_id='report-evidence' and name like t.municipality_id::text||'/'||t.actor::text||'/'||t.id::text||'/%') then raise exception 'Archivos pendientes'; end if;
 update private.report_uploads set purged_at=now(),payload='{}' where id=t.id;
 return jsonb_build_object('purged',true);
end; $$;
create function public.report_upload_purge(p_token text,p_case uuid default null) returns jsonb language sql security invoker set search_path='' as $$ select private.report_upload_purge(p_token,p_case); $$;
revoke all on function private.report_upload_purge(text,uuid),public.report_upload_purge(text,uuid) from public,anon,authenticated;
grant execute on function private.report_upload_purge(text,uuid),public.report_upload_purge(text,uuid) to service_role;

-- Configuración explícita del piloto autorizado; no se activa en otros municipios.
update public.settings set pilot_reports_enabled=true where municipality_id in(select id from public.municipalities where name='Cuautla' and state='Morelos');
insert into public.priorities(municipality_id,name,rank)
select m.id,v.name,v.rank from public.municipalities m cross join (values ('Baja',1),('Media',2),('Alta',3),('Crítica',4)) v(name,rank) where m.name='Cuautla' and m.state='Morelos' on conflict do nothing;
insert into public.categories(municipality_id,name,description,default_priority_id,requires_photo,sort_order,dynamic_form_schema)
select m.id,v.name,'Categoría del piloto: sin atención municipal real.',p.id,v.photo,v.ord,v.schema::jsonb
from public.municipalities m join public.priorities p on p.municipality_id=m.id and p.rank=2
cross join (values
 ('Baches',true,1,'{"type":"object","properties":{"referencia":{"type":"string","title":"Referencia del lugar","maxLength":200}},"additionalProperties":false}'),
 ('Alumbrado público',true,2,'{"type":"object","properties":{"lamparas":{"type":"integer","title":"Número de lámparas","minimum":1,"maximum":100},"intermitente":{"type":"boolean","title":"¿La falla es intermitente?"}},"required":["lamparas"],"additionalProperties":false}'),
 ('Recolección de residuos',false,3,'{"type":"object","properties":{"tipo":{"type":"string","title":"Tipo de residuos","enum":["Domésticos","Escombro","Otro"]}},"required":["tipo"],"additionalProperties":false}')
) v(name,photo,ord,schema) where m.name='Cuautla' and m.state='Morelos' on conflict do nothing;
commit;
