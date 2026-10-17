begin;
-- Existing session checks and municipal scope remain authoritative.
create function private.admin_team(p_action text, p_data jsonb default '{}') returns jsonb
language plpgsql security definer set search_path='' as $$
declare home uuid; actor uuid:=auth.uid(); target uuid; wanted text; previous jsonb; result jsonb; off integer; q text;
begin
 perform private.admin_pilot('context','{}');
 select municipality_id into home from public.profiles where id=actor;
 if not private.has_permission(home,'users.manage') then raise exception 'Sin permiso para administrar personal' using errcode='42501'; end if;
 if p_data is null or jsonb_typeof(p_data)<>'object' or length(p_data::text)>4000 then raise exception 'Datos inválidos' using errcode='22023'; end if;
 if p_action='list' then
   off:=coalesce((p_data->>'offset')::integer,0); q:=trim(coalesce(p_data->>'query',''));
   if off<0 or off>100000 or length(q)>160 then raise exception 'Filtros inválidos' using errcode='22023'; end if;
   with people as (
     select p.id,trim(p.first_name||' '||p.last_name) as name,
       coalesce((select jsonb_agg(r.code order by r.code) from public.user_roles u join public.roles r on r.id=u.role_id where u.user_id=p.id),'[]') as roles,
       (select count(*) from public.report_assignments a join public.reports rep on rep.id=a.report_id join public.report_statuses s on s.id=rep.status_id where a.assigned_to=p.id and a.unassigned_at is null and not s.is_terminal and s.code<>'RESUELTO') as cases
     from public.profiles p where p.municipality_id=home and p.is_active and p.deleted_at is null
       and (q='' or strpos(lower(p.first_name||' '||p.last_name),lower(q))>0)
   ) select jsonb_build_object('actor',actor,'total',(select count(*) from people),'members',
       (select coalesce(jsonb_agg(to_jsonb(x) order by x.name,x.id),'[]') from (select * from people order by name,id limit 20 offset off) x),
       'roles',(select jsonb_agg(jsonb_build_object('code',r.code,'description',r.description,'permissions',
         (select coalesce(jsonb_agg(p.code order by p.code),'[]') from public.role_permissions rp join public.permissions p on p.id=rp.permission_id where rp.role_id=r.id)) order by r.code)
         from public.roles r where r.code<>'SUPER_ADMIN')) into result;
   return result;
 end if;
 if p_action<>'set_role' then raise exception 'Acción inválida' using errcode='22023'; end if;
 -- Serialize municipal role changes; recheck authority after waiting for the lock.
 perform 1 from public.municipalities where id=home for update;
 perform private.admin_pilot('context','{}');
 if not private.has_permission(home,'users.manage') then raise exception 'Sin permiso' using errcode='42501'; end if;
 target:=(p_data->>'id')::uuid; wanted:=p_data->>'role';
 if target=actor then raise exception 'No puedes cambiar tu propio acceso' using errcode='42501'; end if;
 if wanted is null or wanted not in ('MUNICIPAL_ADMIN','SUPERVISOR','OPERATOR','VIEWER','CITIZEN') then raise exception 'Rol no permitido' using errcode='22023'; end if;
 perform 1 from public.profiles where id=target and municipality_id=home and is_active and deleted_at is null for update;
 if not found or exists(select 1 from public.user_roles u join public.roles r on r.id=u.role_id where u.user_id=target and r.code='SUPER_ADMIN') then raise exception 'Cuenta no disponible' using errcode='42501'; end if;
 select coalesce(jsonb_agg(r.code order by r.code),'[]') into previous from public.user_roles u join public.roles r on r.id=u.role_id where u.user_id=target;
 if p_data->'expected_roles' is distinct from previous then raise exception 'Los permisos cambiaron. Recarga el equipo.' using errcode='40001'; end if;
 if wanted in ('CITIZEN','VIEWER') and exists(select 1 from public.report_assignments a join public.reports rep on rep.id=a.report_id join public.report_statuses s on s.id=rep.status_id where a.assigned_to=target and a.unassigned_at is null and not s.is_terminal and s.code<>'RESUELTO') then raise exception 'Reasigna sus casos activos antes de retirar el acceso operativo' using errcode='22023'; end if;
 delete from public.user_roles where user_id=target and municipality_id=home;
 insert into public.user_roles(user_id,municipality_id,role_id) select target,home,id from public.roles where code in ('CITIZEN',wanted);
 insert into public.audit_logs(municipality_id,actor_id,action,entity_type,entity_id,old_values,new_values)
 values(home,actor,'team.set_role','profiles',target,jsonb_build_object('roles',previous),jsonb_build_object('role',wanted));
 return jsonb_build_object('saved',true);
end;$$;
create function public.admin_team(p_action text,p_data jsonb default '{}') returns jsonb language sql security invoker set search_path='' as $$select private.admin_team(p_action,p_data);$$;
revoke all on function private.admin_team(text,jsonb),public.admin_team(text,jsonb) from public,anon,authenticated;
grant execute on function private.admin_team(text,jsonb),public.admin_team(text,jsonb) to authenticated;
create or replace function private.admin_pilot(p_action text,p_data jsonb default '{}') returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid(); home uuid; pr public.profiles; rr public.reports; result jsonb; rows_json jsonb; total bigint; all_access boolean;
 target uuid; next_id uuid; old_code text; next_code text; dep uuid; assignee uuid; wanted bigint; q text; cat uuid; st text; date_from timestamptz; date_to timestamptz; off integer;
begin
 if actor is null or not exists(select 1 from auth.users u join auth.sessions s on s.user_id=u.id
 where u.id=actor and s.id=nullif(auth.jwt()->>'session_id','')::uuid and (s.not_after is null or s.not_after>now())
 and u.email_confirmed_at is not null and u.deleted_at is null and not coalesce(u.is_anonymous,false) and (u.banned_until is null or u.banned_until<=now())) then
 raise exception 'Sesión no autorizada' using errcode='42501'; end if;
 select * into pr from public.profiles where id=actor and is_active and deleted_at is null;
 home:=pr.municipality_id;
 if home is null or not private.has_permission(home,'reports.read') then raise exception 'Acceso administrativo no autorizado' using errcode='42501'; end if;
 all_access:=private.has_permission(home,'reports.read_all');
 if p_data is null or jsonb_typeof(p_data)<>'object' or length(p_data::text)>10000 then raise exception 'Datos inválidos' using errcode='22023'; end if;
 if p_action='context' then
 return jsonb_build_object('name',trim(pr.first_name||' '||pr.last_name),'municipality',(select name from public.municipalities where id=home),
 'permissions',(select coalesce(jsonb_agg(code),'[]') from public.permissions where private.has_permission(home,code)),
 'roles',(select jsonb_agg(r.code) from public.user_roles u join public.roles r on r.id=u.role_id where u.user_id=actor and (u.municipality_id=home or r.code='SUPER_ADMIN')),
 'categories',(select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name,'description',description,'is_active',is_active) order by sort_order,name),'[]') from public.categories where municipality_id=home),
 'priorities',(select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name) order by rank),'[]') from public.priorities where municipality_id=home and is_active),
 'statuses',(select jsonb_agg(jsonb_build_object('id',id,'code',code,'name',name,'terminal',is_terminal)) from public.report_statuses),
 'departments',(select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name) order by name),'[]') from public.departments where municipality_id=home and is_active),
 'team',case when private.has_permission(home,'reports.assign') or private.has_permission(home,'users.read') then
 (select coalesce(jsonb_agg(x.v),'[]') from (select jsonb_build_object('id',p.id,'name',trim(p.first_name||' '||p.last_name),
 'roles',(select jsonb_agg(r.code) from public.user_roles u join public.roles r on r.id=u.role_id where u.user_id=p.id and r.code<>'CITIZEN'),
 'cases',(select count(*) from public.report_assignments a join public.reports rep on rep.id=a.report_id join public.report_statuses s on s.id=rep.status_id where a.assigned_to=p.id and a.unassigned_at is null and rep.is_pilot and not s.is_terminal and s.code<>'RESUELTO')) v
 from public.profiles p where p.municipality_id=home and p.is_active and p.deleted_at is null and private.identity_permission(p.id,home,'reports.read') order by p.first_name limit 200) x) else '[]'::jsonb end);
 end if;
 if p_action in ('list','summary','export') then
 q:=trim(coalesce(p_data->>'query','')); cat:=nullif(p_data->>'category','')::uuid; st:=nullif(p_data->>'status','');
 date_from:=nullif(p_data->>'from','')::timestamptz; date_to:=nullif(p_data->>'to','')::timestamptz; off:=coalesce((p_data->>'offset')::integer,0);
 if length(q)>160 or off<0 or off>100000 or (date_from is not null and date_to is not null and date_from>date_to) then raise exception 'Filtros inválidos' using errcode='22023'; end if;
 with filtered as (
 select r.id,r.folio,r.description,r.approximate_address as address,r.created_at,r.admin_version,r.resolved_at,
 c.name as category,c.id as category_id,s.name as status,s.code as status_code,s.is_terminal,p.name as priority,
 extensions.st_y(r.location::extensions.geometry) as latitude,extensions.st_x(r.location::extensions.geometry) as longitude,
 (select trim(u.first_name||' '||u.last_name) from public.report_assignments a join public.profiles u on u.id=a.assigned_to where a.report_id=r.id and a.unassigned_at is null) as assigned_name
 from public.reports r join public.categories c on c.id=r.category_id join public.report_statuses s on s.id=r.status_id join public.priorities p on p.id=r.priority_id
 where r.municipality_id=home and r.is_pilot and (all_access or exists(select 1 from public.report_assignments a where a.report_id=r.id and a.assigned_to=actor and a.unassigned_at is null))
 and (q='' or strpos(lower(r.folio||' '||r.description||' '||coalesce(r.approximate_address,'')),lower(q))>0)
 and (cat is null or r.category_id=cat) and (st is null or s.code=st) and (date_from is null or r.created_at>=date_from) and (date_to is null or r.created_at<date_to+interval '1 day'))
 select case when p_action in ('list','export') then jsonb_build_object('total',(select count(*) from filtered),'reports',
 (select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc,x.id desc),'[]') from (select * from filtered order by created_at desc,id desc limit (case when p_action='export' then 5000 else 20 end) offset (case when p_action='export' then 0 else off end)) x))
 else jsonb_build_object('total',count(*),'pending',count(*) filter(where status_code in ('RECIBIDO','EN_REVISION','VALIDADO','ASIGNADO')),
 'progress',count(*) filter(where status_code='EN_ATENCION'),'resolved',count(*) filter(where status_code in ('RESUELTO','CERRADO')),
 'categories',(select coalesce(jsonb_agg(to_jsonb(x)),'[]') from (select category as name,count(*) as count from filtered group by category order by count(*) desc) x),
 'statuses',(select coalesce(jsonb_agg(to_jsonb(x)),'[]') from (select status as name,count(*) as count from filtered group by status) x),
 'weeks',(select coalesce(jsonb_agg(to_jsonb(x) order by x.week),'[]') from (select date_trunc('week',created_at at time zone 'America/Mexico_City')::date as week,count(*) as count from filtered where created_at>=now()-interval '8 weeks' group by 1) x),
 'resolution_days',round(avg(extract(epoch from (resolved_at-created_at))/86400) filter(where resolved_at is not null)::numeric,1)) end into result from filtered;
 if p_action='export' and (result->>'total')::bigint>5000 then raise exception 'Limita el filtro a 5000 reportes para exportar' using errcode='22023'; end if;
 return result;
 end if;
 target:=nullif(p_data->>'id','')::uuid;
 select * into rr from public.reports where id=target and municipality_id=home and is_pilot for update;
 if not found or not (all_access or exists(select 1 from public.report_assignments where report_id=target and assigned_to=actor and unassigned_at is null)) then raise exception 'Reporte no disponible' using errcode='42501'; end if;
 if p_action='detail' then
 return jsonb_build_object('id',rr.id,'folio',rr.folio,'description',rr.description,'address',rr.approximate_address,'created_at',rr.created_at,'version',rr.admin_version,
 'status',(select code from public.report_statuses where id=rr.status_id),'category',(select name from public.categories where id=rr.category_id),'priority_id',rr.priority_id,
 'latitude',extensions.st_y(rr.location::extensions.geometry),'longitude',extensions.st_x(rr.location::extensions.geometry),
 'citizen',(select jsonb_build_object('name',trim(first_name||' '||last_name),'phone',phone) from public.profiles where id=rr.citizen_id),
 'images',(select coalesce(jsonb_agg(jsonb_build_object('id',id,'path',storage_path)),'[]') from public.report_images where report_id=target),
 'timeline',(select coalesce(jsonb_agg(jsonb_build_object('status',s.name,'created_at',h.created_at) order by h.created_at,h.id),'[]') from public.report_status_history h join public.report_statuses s on s.id=h.new_status_id where h.report_id=target),
 'assignment',(select jsonb_build_object('department_id',department_id,'assigned_to',assigned_to) from public.report_assignments where report_id=target and unassigned_at is null));
 end if;
 wanted:=(p_data->>'version')::bigint;
 if wanted is null or wanted<>rr.admin_version then raise exception 'El reporte cambió. Recarga antes de guardar.' using errcode='40001'; end if;
 select code into old_code from public.report_statuses where id=rr.status_id;
 if old_code in ('CERRADO','RECHAZADO','DUPLICADO') then raise exception 'El reporte está finalizado' using errcode='22023'; end if;
 if p_action='status' then
 next_code:=p_data->>'status';
 if not private.has_permission(home,case when next_code='RESUELTO' then 'reports.resolve' when next_code in ('CERRADO','RECHAZADO','DUPLICADO') then 'reports.close' else 'reports.update' end) then raise exception 'Sin permiso' using errcode='42501'; end if;
 if not coalesce((old_code='RECIBIDO' and next_code in ('EN_REVISION','RECHAZADO','DUPLICADO')) or (old_code='EN_REVISION' and next_code in ('VALIDADO','RECHAZADO','DUPLICADO')) or (old_code='ASIGNADO' and next_code='EN_ATENCION') or (old_code='EN_ATENCION' and next_code='RESUELTO') or (old_code='RESUELTO' and next_code in ('CERRADO','EN_ATENCION')),false) then raise exception 'Transición no permitida' using errcode='22023'; end if;
 select id into next_id from public.report_statuses where code=next_code;
 update public.reports set status_id=next_id,admin_version=admin_version+1,
 resolved_at=case when next_code='RESUELTO' then now() when next_code='EN_ATENCION' then null else resolved_at end,
 closed_at=case when next_code='CERRADO' then now() else closed_at end where id=target;
 elsif p_action='priority' then
 if not private.has_permission(home,'reports.update') then raise exception 'Sin permiso' using errcode='42501'; end if;
 next_id:=(p_data->>'priority_id')::uuid;
 if not exists(select 1 from public.priorities where id=next_id and municipality_id=home and is_active) then raise exception 'Prioridad inválida' using errcode='22023'; end if;
 update public.reports set priority_id=next_id,admin_version=admin_version+1 where id=target;
 insert into public.audit_logs(municipality_id,actor_id,action,entity_type,entity_id,old_values,new_values) values(home,actor,'report.priority','reports',target,jsonb_build_object('priority_id',rr.priority_id),jsonb_build_object('priority_id',next_id));
 elsif p_action='assign' then
 if not private.has_permission(home,'reports.assign') then raise exception 'Sin permiso' using errcode='42501'; end if;
 if old_code not in ('VALIDADO','ASIGNADO','EN_ATENCION') then raise exception 'Valida el reporte antes de asignarlo' using errcode='22023'; end if;
 dep:=(p_data->>'department_id')::uuid; assignee:=nullif(p_data->>'assigned_to','')::uuid;
 if not exists(select 1 from public.departments where id=dep and municipality_id=home and is_active) or (assignee is not null and not (exists(select 1 from public.profiles where id=assignee and municipality_id=home and is_active and deleted_at is null) and private.identity_permission(assignee,home,'reports.update'))) then raise exception 'Destino no autorizado' using errcode='22023'; end if;
 update public.report_assignments set unassigned_at=now() where report_id=target and unassigned_at is null;
 insert into public.report_assignments(municipality_id,report_id,department_id,assigned_to,assigned_by) values(home,target,dep,assignee,actor);
 update public.reports set admin_version=admin_version+1,status_id=case when old_code='VALIDADO' then (select id from public.report_statuses where code='ASIGNADO') else status_id end where id=target;
 insert into public.audit_logs(municipality_id,actor_id,action,entity_type,entity_id,new_values) values(home,actor,'report.assign','reports',target,jsonb_build_object('department_id',dep,'assigned_to',assignee));
 else raise exception 'Acción inválida' using errcode='22023'; end if;
 return jsonb_build_object('saved',true);
end; $$;

commit;
