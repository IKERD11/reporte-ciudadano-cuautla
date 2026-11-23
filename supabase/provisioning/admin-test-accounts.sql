-- Aprovisionamiento explícito de seis cuentas sintéticas; no es una migración.
-- El generador proporciona app.test_admin_accounts dentro de una transacción.
do $$
declare
  accounts jsonb := current_setting('app.test_admin_accounts')::jsonb;
  account jsonb;
  home uuid;
  admin_role uuid;
  user_id uuid;
  account_email text;
  n integer := 0;
begin
  if jsonb_typeof(accounts) <> 'array' or jsonb_array_length(accounts) <> 6 then
    raise exception 'Se requieren exactamente seis cuentas de prueba';
  end if;
  select id into strict home from public.municipalities
    where name = 'Cuautla' and state = 'Morelos' and is_active;
  select id into strict admin_role from public.roles where code = 'MUNICIPAL_ADMIN';
  for account in select value from jsonb_array_elements(accounts) loop
    n := n + 1;
    account_email := 'admin.prueba.' || lpad(n::text, 2, '0') || '@example.test';
    if account->>'email' is distinct from account_email
      or coalesce(length(account->>'password'), 0) < 24 then
      raise exception 'Correo o contraseña inválidos para cuenta %', n;
    end if;
    if exists(select 1 from auth.users where lower(email) = account_email) then
      raise exception 'La cuenta % ya existe; no se modifica su contraseña ni sus permisos', account_email;
    end if;
    user_id := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, confirmation_token, recovery_token,
      email_change_token_new, email_change, raw_app_meta_data,
      raw_user_meta_data, is_super_admin, created_at, updated_at
    ) values (
      '00000000-0000-0000-0000-000000000000', user_id,
      'authenticated', 'authenticated', account_email,
      extensions.crypt(account->>'password', extensions.gen_salt('bf', 10)),
      now(), '', '', '', '',
      '{"provider":"email","providers":["email"],"test_account":true}',
      jsonb_build_object('first_name', 'Administrador de prueba ' || n, 'last_name', 'Cuautla'),
      false, now(), now()
    );
    insert into auth.identities (provider_id, user_id, identity_data, provider, created_at, updated_at)
    values (user_id::text, user_id,
      jsonb_build_object('sub', user_id::text, 'email', account_email, 'email_verified', true, 'phone_verified', false),
      'email', now(), now());
    insert into public.profiles (id, municipality_id, first_name, last_name)
    values (user_id, home, 'Administrador de prueba ' || n, 'Cuautla');
    insert into public.user_roles (user_id, municipality_id, role_id)
    values (user_id, home, admin_role);
  end loop;
end;
$$;
