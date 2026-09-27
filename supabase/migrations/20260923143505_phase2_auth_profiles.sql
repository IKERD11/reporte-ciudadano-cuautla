begin;
-- Registro habilitado expresamente por municipio; no inscribe usuarios en otros tenants.
alter table public.settings add column citizen_registration_enabled boolean not null default false;

create function private.confirmed_user_id() returns uuid
language plpgsql stable security definer set search_path = '' as $$
declare uid uuid := auth.uid();
begin
  if uid is null or not exists (
    select 1 from auth.users u where u.id=uid and u.email_confirmed_at is not null
      and coalesce(u.is_anonymous,false)=false and u.deleted_at is null
      and (u.banned_until is null or u.banned_until <= now())
  ) then
    raise exception 'Confirma tu correo antes de continuar' using errcode='42501';
  end if;
  return uid;
end;
$$;

create function private.registration_municipalities()
returns table(id uuid,name text,state text)
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.confirmed_user_id();
  return query select m.id,m.name,m.state from public.municipalities m
    join public.settings s on s.municipality_id=m.id
    where m.is_active and s.citizen_registration_enabled order by m.name,m.id;
end;
$$;

create function private.complete_citizen_profile(p_municipality_id uuid,p_first_name text,p_last_name text)
returns public.profiles
language plpgsql security definer set search_path = '' as $$
declare uid uuid := private.confirmed_user_id(); profile public.profiles; citizen_role uuid;
begin
  -- Serializa reintentos concurrentes por usuario, sin confiar en user_metadata.
  perform 1 from auth.users where id=uid for update;
  select * into profile from public.profiles where id=uid for update;
  if found then
    if not profile.is_active or profile.deleted_at is not null
      or not exists(select 1 from public.municipalities where id=profile.municipality_id and is_active)
    then raise exception 'Perfil no disponible' using errcode='42501'; end if;
    if profile.municipality_id is distinct from p_municipality_id then
      raise exception 'No puedes cambiar el municipio del perfil' using errcode='42501';
    end if;
    return profile;
  end if;
  if p_first_name is null or length(trim(p_first_name)) not between 1 and 120
    or p_last_name is null or length(trim(p_last_name)) not between 1 and 160 then
    raise exception 'Nombre y apellidos requeridos' using errcode='22023';
  end if;
  perform 1 from public.municipalities m join public.settings s on s.municipality_id=m.id
    where m.id=p_municipality_id and m.is_active and s.citizen_registration_enabled
    for share of m,s;
  if not found then raise exception 'Registro no disponible en este municipio' using errcode='42501'; end if;
  select id into strict citizen_role from public.roles where code='CITIZEN';
  insert into public.profiles(id,municipality_id,first_name,last_name)
    values(uid,p_municipality_id,trim(p_first_name),trim(p_last_name)) returning * into profile;
  insert into public.user_roles(user_id,municipality_id,role_id) values(uid,p_municipality_id,citizen_role);
  insert into public.audit_logs(municipality_id,actor_id,action,entity_type,entity_id)
    values(p_municipality_id,uid,'profile.created','profiles',uid);
  return profile;
end;
$$;

create function private.update_my_profile(p_first_name text,p_last_name text,p_phone text)
returns public.profiles
language plpgsql security definer set search_path = '' as $$
declare uid uuid := private.confirmed_user_id(); profile public.profiles;
begin
  select * into profile from public.profiles where id=uid for update;
  if not found or not profile.is_active or profile.deleted_at is not null
    or not exists(select 1 from public.municipalities where id=profile.municipality_id and is_active)
  then raise exception 'Perfil no disponible' using errcode='42501'; end if;
  if p_first_name is null or length(trim(p_first_name)) not between 1 and 120
    or p_last_name is null or length(trim(p_last_name)) not between 1 and 160
    or (nullif(trim(p_phone),'') is not null and trim(p_phone) !~ '^\+[1-9][0-9]{7,14}$') then
    raise exception 'Datos de perfil inválidos' using errcode='22023';
  end if;
  update public.profiles set first_name=trim(p_first_name),last_name=trim(p_last_name),phone=nullif(trim(p_phone),'')
    where id=uid returning * into profile;
  insert into public.audit_logs(municipality_id,actor_id,action,entity_type,entity_id)
    values(profile.municipality_id,uid,'profile.updated','profiles',uid);
  return profile;
end;
$$;

-- Fachada API invoker; lógica privilegiada mínima en esquema no expuesto.
create function public.list_registration_municipalities()
returns table(id uuid,name text,state text)
language sql stable security invoker set search_path = '' as $$
  select id,name,state from private.registration_municipalities();
$$;
create function public.complete_citizen_profile(p_municipality_id uuid,p_first_name text,p_last_name text)
returns public.profiles
language sql security invoker set search_path = '' as $$
  select private.complete_citizen_profile(p_municipality_id,p_first_name,p_last_name);
$$;
create function public.update_my_profile(p_first_name text,p_last_name text,p_phone text default null)
returns public.profiles
language sql security invoker set search_path = '' as $$
  select private.update_my_profile(p_first_name,p_last_name,p_phone);
$$;

revoke all on function private.confirmed_user_id() from public,anon,authenticated;
revoke all on function private.registration_municipalities(),private.complete_citizen_profile(uuid,text,text),private.update_my_profile(text,text,text) from public,anon,authenticated;
grant execute on function private.registration_municipalities(),private.complete_citizen_profile(uuid,text,text),private.update_my_profile(text,text,text) to authenticated;
revoke all on function public.list_registration_municipalities(),public.complete_citizen_profile(uuid,text,text),public.update_my_profile(text,text,text) from public,anon,authenticated;
grant execute on function public.list_registration_municipalities(),public.complete_citizen_profile(uuid,text,text),public.update_my_profile(text,text,text) to authenticated;
commit;
