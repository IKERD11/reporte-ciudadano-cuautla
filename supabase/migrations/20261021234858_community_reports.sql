-- Community projection: no profile identity, private attachments, internal notes or form data.
create or replace function private.community_report_view(r public.reports) returns jsonb
language sql stable set search_path='' as $$
 select jsonb_build_object('id',r.id,'folio',r.folio,'is_pilot',r.is_pilot,
 'community',true,'description',r.description,'created_at',r.created_at,
 'address',coalesce(z.name,'Ubicación aproximada, Cuautla'),
 'latitude',round(extensions.st_y(r.location::extensions.geometry)::numeric,3),
 'longitude',round(extensions.st_x(r.location::extensions.geometry)::numeric,3),
 'category',c.name,'status',s.name,'status_code',s.code,'priority',p.name,
 'additional_data','{}'::jsonb,'schema','{}'::jsonb,'images','[]'::jsonb,
 'timeline',(select coalesce(jsonb_agg(jsonb_build_object('status',st.name,'created_at',h.created_at) order by h.created_at),'[]'::jsonb)
 from public.report_status_history h join public.report_statuses st on st.id=h.new_status_id where h.report_id=r.id))
 from public.categories c join public.report_statuses s on s.id=r.status_id
 join public.priorities p on p.id=r.priority_id
 left join public.zones z on z.id=r.zone_id where c.id=r.category_id;
$$;
revoke all on function private.community_report_view(public.reports) from public,anon,authenticated;

create or replace function public.community_report_service(p_actor uuid,p_session uuid,p_action text,p_report uuid default null,p_offset integer default 0,p_filter text default 'ALL') returns jsonb
language plpgsql security definer set search_path='' as $$
declare ctx jsonb; home uuid; output jsonb; selected public.reports; more boolean;
begin
 ctx:=public.report_pilot_service(p_actor=>p_actor,p_session=>p_session,p_action=>'context');
 if not coalesce((ctx->>'enabled')::boolean,false) then raise exception 'Piloto no habilitado' using errcode='42501'; end if;
 select municipality_id into home from public.profiles where id=p_actor and is_active and deleted_at is null;
 if home is null then raise exception 'Perfil no disponible' using errcode='42501'; end if;
 if p_action not in ('list','detail') or p_offset is null or p_offset<0 or p_offset>10000
 or p_filter not in ('ALL','PENDING','EN_ATENCION','RESUELTO','CERRADO') then raise exception 'Consulta inválida' using errcode='22023'; end if;
 if p_action='detail' then
 select r.* into selected from public.reports r join public.categories c on c.id=r.category_id
 where r.id=p_report and r.municipality_id=home and r.is_pilot and c.is_public and c.is_active;
 if not found then raise exception 'Reporte no disponible' using errcode='42501'; end if;
 return private.community_report_view(selected);
 end if;
 with visible as (
 select r.* from public.reports r join public.categories c on c.id=r.category_id
 join public.report_statuses s on s.id=r.status_id
 where r.municipality_id=home and r.is_pilot and c.is_public and c.is_active
 and (p_filter='ALL' or s.code=p_filter or (p_filter='PENDING' and not s.is_terminal and s.code<>'EN_ATENCION'))
 order by r.created_at desc,r.id desc limit 21 offset p_offset
 ), page as (select * from visible order by created_at desc,id desc limit 20)
 select jsonb_build_object('reports',coalesce((select jsonb_agg(private.community_report_view(page) order by page.created_at desc,page.id desc) from page),'[]'::jsonb),
 'has_more',(select count(*)>20 from visible),'offset',p_offset) into output;
 return output;
end;
$$;
revoke all on function public.community_report_service(uuid,uuid,text,uuid,integer,text) from public,anon,authenticated;
grant execute on function public.community_report_service(uuid,uuid,text,uuid,integer,text) to service_role;
