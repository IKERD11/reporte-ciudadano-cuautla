begin;
-- Catálogos estructurales, no datos de demostración.
insert into public.roles(code, description) values
('SUPER_ADMIN','Administración global explícita'),('MUNICIPAL_ADMIN','Administración municipal'),
('SUPERVISOR','Supervisión por asignación'),('OPERATOR','Operación por asignación'),
('VIEWER','Lectura municipal'),('CITIZEN','Ciudadano');
insert into public.permissions(code, description)
select code, code from unnest(array[
  'reports.read','reports.read_all','reports.create','reports.update','reports.assign','reports.resolve','reports.close',
  'categories.manage','users.read','users.manage','identity.read','identity.review',
  'audit.read','analytics.read','settings.manage'
]) code;
insert into public.role_permissions(role_id, permission_id)
select r.id,p.id from public.roles r cross join public.permissions p
where r.code = 'SUPER_ADMIN'
or (r.code = 'MUNICIPAL_ADMIN' and p.code not in ('identity.read','identity.review'))
or (r.code = 'SUPERVISOR' and p.code in ('reports.read','reports.update','reports.assign','reports.resolve','reports.close'))
or (r.code = 'OPERATOR' and p.code in ('reports.read','reports.update','reports.resolve'))
or (r.code = 'VIEWER' and p.code in ('reports.read','reports.read_all','analytics.read'))
or (r.code = 'CITIZEN' and p.code = 'reports.create');
insert into public.report_statuses(code, name, is_terminal) values
('RECIBIDO','Recibido',false),('EN_REVISION','En revisión',false),('VALIDADO','Validado',false),
('ASIGNADO','Asignado',false),('EN_ATENCION','En atención',false),('RESUELTO','Resuelto',false),
('CERRADO','Cerrado',true),('RECHAZADO','Rechazado',true),('DUPLICADO','Duplicado',true);

create function private.is_member(p_municipality uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles p join public.municipalities m on m.id = p.municipality_id
    where p.id = auth.uid() and p.municipality_id = p_municipality
    and p.is_active and p.deleted_at is null and m.is_active
  );
$$;
create function private.has_permission(p_municipality uuid, p_permission text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.user_roles ur
    join public.profiles p on p.id = ur.user_id
    join public.municipalities home on home.id = p.municipality_id
    join public.roles r on r.id = ur.role_id
    join public.role_permissions rp on rp.role_id = r.id
    join public.permissions perm on perm.id = rp.permission_id
    join public.municipalities target on target.id = p_municipality
    where ur.user_id = auth.uid() and p.is_active and p.deleted_at is null
    and home.is_active and target.is_active and perm.code = p_permission
    and (ur.municipality_id = p_municipality or (ur.municipality_id is null and r.code = 'SUPER_ADMIN'))
  );
$$;
create function private.can_read_report(p_report uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.reports r where r.id = p_report and (
      (r.citizen_id = auth.uid() and private.is_member(r.municipality_id))
      or private.has_permission(r.municipality_id, 'reports.read_all')
      or (private.has_permission(r.municipality_id, 'reports.read') and exists (
        select 1 from public.report_assignments a where a.report_id = r.id
        and a.assigned_to = auth.uid() and a.unassigned_at is null
      ))
    )
  );
$$;
create function private.validate_role_scope() returns trigger
language plpgsql set search_path = '' as $$
declare role_code text; home uuid;
begin
  select code into role_code from public.roles where id = new.role_id;
  select municipality_id into home from public.profiles where id = new.user_id;
  if (role_code = 'SUPER_ADMIN') <> (new.municipality_id is null) then
    raise exception 'SUPER_ADMIN requiere alcance global; otros roles requieren municipio' using errcode = '23514';
  end if;
  if new.municipality_id is not null and new.municipality_id <> home then
    raise exception 'Rol fuera del municipio del perfil' using errcode = '23514';
  end if;
  return new;
end;
$$;
create trigger user_roles_scope before insert or update on public.user_roles
for each row execute function private.validate_role_scope();

create function private.touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end;
$$;
do $$ declare t text; begin
  foreach t in array array['municipalities','profiles','departments','categories','settings','identity_verifications','reports'] loop
    execute format('create trigger touch_updated_at before update on public.%I for each row execute function private.touch_updated_at()',t);
  end loop;
end $$;

create function private.assign_folio() returns trigger
language plpgsql security definer set search_path = '' as $$
declare n text;
begin
  n := nextval('private.report_folio_seq')::text;
  new.folio := 'REP-' || to_char(now() at time zone 'UTC','YYYY') || '-' || lpad(n, greatest(6,length(n)), '0');
  return new;
end;
$$;
create trigger reports_folio before insert on public.reports for each row execute function private.assign_folio();
create function private.log_report_status() returns trigger
language plpgsql security definer set search_path = '' as $$
declare prev uuid;
begin
  if tg_op = 'UPDATE' then
    if new.status_id = old.status_id then return new; end if;
    prev := old.status_id;
  end if;
  insert into public.report_status_history(municipality_id,report_id,previous_status_id,new_status_id,changed_by)
  values(new.municipality_id,new.id,prev,new.status_id,auth.uid());
  insert into public.audit_logs(municipality_id,actor_id,action,entity_type,entity_id,old_values,new_values)
  values(new.municipality_id,auth.uid(),'report.status','reports',new.id,
    jsonb_build_object('status_id',prev),jsonb_build_object('status_id',new.status_id));
  return new;
end;
$$;
create trigger reports_status_audit after insert or update of status_id on public.reports
for each row execute function private.log_report_status();

grant usage on schema private to authenticated;
revoke all on all functions in schema private from public, anon, authenticated;
grant execute on function private.is_member(uuid), private.has_permission(uuid,text), private.can_read_report(uuid) to authenticated;
-- Solo lecturas: sin INSERT/UPDATE/DELETE/TRUNCATE para los clientes.
grant select on all tables in schema public to authenticated;

create policy municipalities_read on public.municipalities for select to authenticated
using (private.is_member(id) or private.has_permission(id,'settings.manage'));
create policy profiles_read on public.profiles for select to authenticated
using ((id = (select auth.uid()) and private.is_member(municipality_id)) or private.has_permission(municipality_id,'users.read'));
create policy roles_read on public.roles for select to authenticated using (true);
create policy permissions_read on public.permissions for select to authenticated using (true);
create policy role_permissions_read on public.role_permissions for select to authenticated using (true);
create policy user_roles_read on public.user_roles for select to authenticated
using ((user_id = (select auth.uid()) and exists(select 1 from public.profiles where id = (select auth.uid()) and is_active and deleted_at is null)) or private.has_permission(municipality_id,'users.read'));
create policy priorities_read on public.priorities for select to authenticated
using ((is_active and private.is_member(municipality_id)) or private.has_permission(municipality_id,'categories.manage'));
create policy statuses_read on public.report_statuses for select to authenticated using (true);
create policy departments_read on public.departments for select to authenticated
using (private.has_permission(municipality_id,'reports.read'));
create policy zones_read on public.zones for select to authenticated
using (private.is_member(municipality_id) or private.has_permission(municipality_id,'reports.read'));
create policy categories_read on public.categories for select to authenticated
using ((is_public and is_active and private.is_member(municipality_id)) or private.has_permission(municipality_id,'reports.read') or private.has_permission(municipality_id,'categories.manage'));
create policy subcategories_read on public.subcategories for select to authenticated
using ((is_active or private.has_permission(municipality_id,'categories.manage'))
  and exists(select 1 from public.categories c where c.id = category_id));
create policy settings_read on public.settings for select to authenticated
using (private.is_member(municipality_id) or private.has_permission(municipality_id,'settings.manage'));
create policy consents_read on public.consents for select to authenticated
using ((user_id = (select auth.uid()) and private.is_member(municipality_id)) or private.has_permission(municipality_id,'identity.read'));
-- Ciudadano ve su estado en profiles, no metadatos internos ni referencia del proveedor.
create policy identity_read on public.identity_verifications for select to authenticated
using (private.has_permission(municipality_id,'identity.read'));
create policy reports_read on public.reports for select to authenticated using (private.can_read_report(id));
create policy images_read on public.report_images for select to authenticated using (private.can_read_report(report_id));
create policy history_read on public.report_status_history for select to authenticated using (private.can_read_report(report_id));
create policy assignments_read on public.report_assignments for select to authenticated
using (private.can_read_report(report_id) and private.has_permission(municipality_id,'reports.read'));
create policy comments_read on public.report_comments for select to authenticated
using (private.can_read_report(report_id) and (not is_internal or private.has_permission(municipality_id,'reports.read')));
create policy notifications_read on public.notifications for select to authenticated
using (user_id = (select auth.uid()) and private.is_member(municipality_id));
create policy audit_read on public.audit_logs for select to authenticated using (private.has_permission(municipality_id,'audit.read'));
create policy sla_read on public.sla_rules for select to authenticated using (private.has_permission(municipality_id,'reports.read'));
commit;
