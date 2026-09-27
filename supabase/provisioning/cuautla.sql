-- Configuración del piloto, no seed de pruebas. Ejecutar con administración autorizada.
-- Idempotente; no asigna roles ni crea cuentas de usuario.
begin;
do $$
declare municipality uuid; matches integer;
begin
  select count(*),min(id::text)::uuid into matches,municipality
    from public.municipalities where name='Cuautla' and state='Morelos';
  if matches > 1 then raise exception 'Hay municipios duplicados; revisar antes de habilitar registro'; end if;
  if matches = 0 then
    insert into public.municipalities(name,state) values('Cuautla','Morelos') returning id into municipality;
  end if;
  if not exists(select 1 from public.municipalities where id=municipality and is_active) then
    raise exception 'Municipio desactivado; no se reactiva automáticamente';
  end if;
  insert into public.settings(municipality_id,citizen_registration_enabled) values(municipality,true)
    on conflict(municipality_id) do update set citizen_registration_enabled=true;
end;
$$;
commit;
