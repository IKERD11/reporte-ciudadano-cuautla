begin;
drop index public.identity_pending_purge_idx;
create extension if not exists pg_cron;
create extension if not exists pg_net with schema extensions;
-- Credencial interna: generada y conservada en Vault, nunca enviada al cliente.
select vault.create_secret(encode(extensions.gen_random_bytes(32),'hex'),'identity_purge_token','Token exclusivo de purga de muestras sintéticas');
create function private.identity_purge_authorized(p_token text,p_case uuid default null) returns jsonb
language plpgsql security definer set search_path='' as $$
begin
  if p_token is null or not exists(select 1 from vault.decrypted_secrets where name='identity_purge_token'
    and extensions.digest(decrypted_secret,'sha256')=extensions.digest(p_token,'sha256')) then
    raise exception 'Mantenimiento no autorizado' using errcode='42501'; end if;
  return private.identity_purge(p_case);
end;
$$;
create function public.identity_purge_authorized(p_token text,p_case uuid default null) returns jsonb
language sql security invoker set search_path='' as $$ select private.identity_purge_authorized(p_token,p_case); $$;
revoke all on function private.identity_purge_authorized(text,uuid),public.identity_purge_authorized(text,uuid) from public,anon,authenticated;
grant execute on function private.identity_purge_authorized(text,uuid),public.identity_purge_authorized(text,uuid) to service_role;
-- Máximo cuatro invocaciones/hora; sin servicios externos de pago.
select cron.schedule('identity-synthetic-purge','*/15 * * * *',$job$
  select net.http_post(
    url:='https://mnjphahyqmwrvlaephla.supabase.co/functions/v1/identity-purge',
    headers:=jsonb_build_object('Content-Type','application/json','Authorization','Bearer '||(select decrypted_secret from vault.decrypted_secrets where name='identity_purge_token')),
    body:='{}'::jsonb,timeout_milliseconds:=10000);
$job$);
commit;
