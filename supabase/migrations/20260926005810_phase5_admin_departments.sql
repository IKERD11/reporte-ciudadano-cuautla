begin;
create function private.admin_department(p_name text) returns jsonb language plpgsql security definer set search_path='' as $$
declare home uuid; target uuid;
begin
 perform private.admin_pilot('context','{}');
 select municipality_id into home from public.profiles where id=auth.uid();
 if not private.has_permission(home,'settings.manage') then raise exception 'Sin permiso' using errcode='42501'; end if;
 if p_name is null or length(trim(p_name)) not between 2 and 100 then raise exception 'Usa un nombre de 2 a 100 caracteres' using errcode='22023'; end if;
 insert into public.departments(municipality_id,name) values(home,trim(p_name)) on conflict(municipality_id,name) do nothing returning id into target;
 if target is not null then
 insert into public.audit_logs(municipality_id,actor_id,action,entity_type,entity_id) values(home,auth.uid(),'department.create','departments',target);
 end if;
 return jsonb_build_object('saved',true);
end;$$;
create function public.admin_department(p_name text) returns jsonb language sql security invoker set search_path='' as $$select private.admin_department(p_name);$$;
revoke all on function private.admin_department(text),public.admin_department(text) from public,anon,authenticated;
grant execute on function private.admin_department(text),public.admin_department(text) to authenticated;
commit;
