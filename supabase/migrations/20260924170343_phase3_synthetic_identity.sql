begin;
-- Esta fase no autoriza documentos reales ni modifica la identidad del perfil.
alter table public.identity_verifications
  add column is_synthetic boolean not null default false,
  add column consent_id uuid references public.consents(id),
  add column request_key uuid;
create unique index identity_request_key_idx on public.identity_verifications(user_id,request_key) where request_key is not null;
create index identity_consent_idx on public.identity_verifications(consent_id);
create index identity_pending_purge_idx on public.identity_verifications(document_delete_after) where documents_deleted_at is null;
create unique index identity_synthetic_active_idx on public.identity_verifications(user_id)
  where is_synthetic and status in ('PENDING','DOCUMENT_CAPTURED','PROCESSING','UNDER_REVIEW') and documents_deleted_at is null;
create table private.identity_documents (
  verification_id uuid not null references public.identity_verifications(id),
  side text not null check(side in ('front','back')),
  storage_path text not null unique,
  uploaded_at timestamptz,
  deleted_at timestamptz,
  primary key(verification_id,side)
);
alter table private.identity_documents enable row level security;
revoke all on private.identity_documents from public,anon,authenticated;

create function private.identity_permission(p_actor uuid,p_municipality uuid,p_permission text) returns boolean
language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.user_roles ur
    join public.profiles p on p.id=ur.user_id
    join public.municipalities home on home.id=p.municipality_id
    join public.municipalities target on target.id=p_municipality
    join public.roles r on r.id=ur.role_id
    join public.role_permissions rp on rp.role_id=r.id
    join public.permissions perm on perm.id=rp.permission_id
    where ur.user_id=p_actor and p.is_active and p.deleted_at is null and home.is_active and target.is_active
    and perm.code=p_permission and (ur.municipality_id=p_municipality or (ur.municipality_id is null and r.code='SUPER_ADMIN')));
$$;

create function private.identity_pilot(p_actor uuid,p_session uuid,p_action text,p_case uuid,p_key uuid,p_side text,p_version text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare actor public.profiles; v public.identity_verifications; consent uuid; doc private.identity_documents; result jsonb;
begin
  -- La Edge Function valida el JWT con Auth; esta segunda validación impide usar sesiones revocadas.
  if not exists(select 1 from auth.users u join auth.sessions s on s.user_id=u.id
    where u.id=p_actor and s.id=p_session and (s.not_after is null or s.not_after>now())
    and u.email_confirmed_at is not null and not coalesce(u.is_anonymous,false) and u.deleted_at is null
    and (u.banned_until is null or u.banned_until<=now())) then
    raise exception 'Sesión no disponible' using errcode='42501';
  end if;
  select * into actor from public.profiles where id=p_actor for update;
  if not found or not actor.is_active or actor.deleted_at is not null
    or not exists(select 1 from public.municipalities where id=actor.municipality_id and is_active)
  then raise exception 'Perfil no disponible' using errcode='42501'; end if;

  if p_action='context' then
    select * into v from public.identity_verifications where user_id=p_actor and is_synthetic order by created_at desc limit 1;
  elsif p_action='begin' then
    if p_version is distinct from 'synthetic-v1' or p_key is null then
      raise exception 'Se requiere consentimiento sintético vigente' using errcode='22023';
    end if;
    select * into v from public.identity_verifications where user_id=p_actor and request_key=p_key and is_synthetic;
    if not found then
      select * into v from public.identity_verifications where user_id=p_actor and is_synthetic
        and status in ('PENDING','DOCUMENT_CAPTURED','PROCESSING','UNDER_REVIEW') and documents_deleted_at is null;
    end if;
    if v.id is null then
      if (select count(*) from public.identity_verifications where user_id=p_actor and created_at>now()-interval '1 day')>=3 then
        raise exception 'Límite diario del piloto' using errcode='54000';
      end if;
      insert into public.consents(municipality_id,user_id,consent_type,privacy_notice_version)
      values(actor.municipality_id,p_actor,'IDENTITY_SYNTHETIC_TEST','synthetic-v1')
      on conflict(user_id,consent_type,privacy_notice_version) do nothing;
      select id into consent from public.consents where user_id=p_actor and consent_type='IDENTITY_SYNTHETIC_TEST' and privacy_notice_version='synthetic-v1';
      insert into public.identity_verifications(municipality_id,user_id,is_synthetic,consent_id,request_key,provider,document_delete_after,verification_metadata)
      values(actor.municipality_id,p_actor,true,consent,p_key,'manual-pilot',now()+interval '24 hours',
        '{"synthetic":true,"ocr":"disabled","review":"pending","notice_version":"synthetic-v1","retention_hours":24}') returning * into v;
      insert into private.identity_documents(verification_id,side,storage_path)
      select v.id,s,actor.municipality_id::text||'/'||p_actor::text||'/'||v.id::text||'/'||s||'.png' from unnest(array['front','back']) s;
      insert into public.audit_logs(municipality_id,actor_id,action,entity_type,entity_id)
      values(actor.municipality_id,p_actor,'identity.synthetic_started','identity_verifications',v.id);
    end if;
  else
    select * into v from public.identity_verifications where id=p_case and is_synthetic for update;
    if not found then raise exception 'Solicitud no disponible' using errcode='42501'; end if;
    if p_action in ('read','approve_demo','reject') then
      if not private.identity_permission(p_actor,v.municipality_id,'identity.read') then
        raise exception 'Sin permiso de revisión' using errcode='42501'; end if;
    elsif v.user_id<>p_actor or v.municipality_id<>actor.municipality_id then
      raise exception 'Solicitud no disponible' using errcode='42501';
    end if;
    if v.documents_deleted_at is not null or v.document_delete_after<=now() then
      raise exception 'Documentos vencidos' using errcode='42501';
    end if;
    if p_action in ('reserve','uploaded') then
      if v.status not in ('PENDING','DOCUMENT_CAPTURED') or p_side not in ('front','back') or p_side is null then
        raise exception 'Carga no disponible' using errcode='22023'; end if;
      select * into doc from private.identity_documents where verification_id=v.id and side=p_side for update;
      if p_action='reserve' then
        return jsonb_build_object('path',doc.storage_path,'uploaded',doc.uploaded_at is not null);
      end if;
      if not exists(select 1 from storage.objects where bucket_id='identity-documents' and name=doc.storage_path) then
        raise exception 'Falta archivo privado' using errcode='22023'; end if;
      update private.identity_documents set uploaded_at=coalesce(uploaded_at,now()) where verification_id=v.id and side=p_side;
      if not exists(select 1 from private.identity_documents where verification_id=v.id and uploaded_at is null) then
        update public.identity_verifications set status='DOCUMENT_CAPTURED' where id=v.id returning * into v;
      end if;
    elsif p_action='submit' then
      if v.status='DOCUMENT_CAPTURED' then
        update public.identity_verifications set status='PROCESSING' where id=v.id;
        insert into public.audit_logs(municipality_id,actor_id,action,entity_type,entity_id)
        values(v.municipality_id,p_actor,'identity.synthetic_processing','identity_verifications',v.id);
        -- OCR no habilitado: no se extraen campos ni se infiere autenticidad.
        update public.identity_verifications set status='UNDER_REVIEW' where id=v.id returning * into v;
      elsif v.status<>'UNDER_REVIEW' then raise exception 'Completa ambos lados' using errcode='22023'; end if;
    elsif p_action='read' then
      select * into doc from private.identity_documents where verification_id=v.id and side=p_side and uploaded_at is not null and deleted_at is null;
      if not found then raise exception 'Documento no disponible' using errcode='42501'; end if;
      insert into public.audit_logs(municipality_id,actor_id,action,entity_type,entity_id)
      values(v.municipality_id,p_actor,'identity.document_access','identity_verifications',v.id);
      return jsonb_build_object('path',doc.storage_path);
    elsif p_action in ('approve_demo','reject') then
      if p_actor=v.user_id or not private.identity_permission(p_actor,v.municipality_id,'identity.review') or v.status<>'UNDER_REVIEW' then
        raise exception 'Revisión no permitida' using errcode='42501'; end if;
      if v.verification_metadata->>'review' <> 'pending' then
        raise exception 'La revisión ya fue registrada' using errcode='22023'; end if;
      update public.identity_verifications set
        status=case when p_action='reject' then 'REJECTED'::public.identity_status else 'UNDER_REVIEW'::public.identity_status end,
        rejected_at=case when p_action='reject' then now() else null end,
        verification_metadata=verification_metadata || jsonb_build_object('review',case when p_action='reject' then 'rejected' else 'simulation_approved' end)
      where id=v.id returning * into v;
      insert into public.audit_logs(municipality_id,actor_id,action,entity_type,entity_id)
      values(v.municipality_id,p_actor,'identity.'||p_action,'identity_verifications',v.id);
    else raise exception 'Acción no disponible' using errcode='22023';
    end if;
  end if;
  result:=jsonb_build_object('mode','synthetic','real_capture_enabled',false,'notice_version','synthetic-v1','retention_hours',24,
    'case',case when v.id is null then null else jsonb_build_object('id',v.id,'status',v.status,'review',v.verification_metadata->>'review',
      'delete_after',v.document_delete_after,'deleted_at',v.documents_deleted_at,
      'front_uploaded',exists(select 1 from private.identity_documents where verification_id=v.id and side='front' and uploaded_at is not null and deleted_at is null),
      'back_uploaded',exists(select 1 from private.identity_documents where verification_id=v.id and side='back' and uploaded_at is not null and deleted_at is null)) end);
  return result;
end;
$$;
create function public.identity_pilot_service(p_actor uuid,p_session uuid,p_action text,p_case uuid default null,p_key uuid default null,p_side text default null,p_version text default null)
returns jsonb language sql security invoker set search_path='' as $$
 select private.identity_pilot(p_actor,p_session,p_action,p_case,p_key,p_side,p_version);
$$;
revoke all on function private.identity_permission(uuid,uuid,text),private.identity_pilot(uuid,uuid,text,uuid,uuid,text,text),public.identity_pilot_service(uuid,uuid,text,uuid,uuid,text,text) from public,anon,authenticated;
grant usage on schema private to service_role;
grant execute on function private.identity_pilot(uuid,uuid,text,uuid,uuid,text,text),public.identity_pilot_service(uuid,uuid,text,uuid,uuid,text,text) to service_role;
-- Purga accesible únicamente desde una función de servidor autenticada.
create function private.identity_purge(p_case uuid default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare v public.identity_verifications;
begin
  if p_case is null then
    return coalesce((select jsonb_agg(jsonb_build_object('id',c.id,'paths',
      (select jsonb_agg(d.storage_path) from private.identity_documents d where d.verification_id=c.id)))
      from (select id from public.identity_verifications where is_synthetic and documents_deleted_at is null
        and document_delete_after < now()-interval '10 minutes' order by document_delete_after limit 25) c),'[]'::jsonb);
  end if;
  select * into v from public.identity_verifications where id=p_case and is_synthetic for update;
  if not found or v.document_delete_after >= now()-interval '10 minutes' then
    raise exception 'Solicitud no vencida' using errcode='22023'; end if;
  if exists(select 1 from private.identity_documents d join storage.objects o on o.bucket_id='identity-documents' and o.name=d.storage_path where d.verification_id=v.id) then
    raise exception 'Eliminar archivos con Storage API antes de confirmar' using errcode='22023'; end if;
  if v.documents_deleted_at is null then
    update private.identity_documents set deleted_at=now() where verification_id=v.id;
    update public.identity_verifications set status='EXPIRED',documents_deleted_at=now() where id=v.id;
    insert into public.audit_logs(municipality_id,action,entity_type,entity_id)
    values(v.municipality_id,'identity.synthetic_purged','identity_verifications',v.id);
  end if;
  return jsonb_build_object('deleted',true);
end;
$$;
create function public.identity_purge_service(p_case uuid default null) returns jsonb
language sql security invoker set search_path='' as $$ select private.identity_purge(p_case); $$;
revoke all on function private.identity_purge(uuid),public.identity_purge_service(uuid) from public,anon,authenticated;
grant execute on function private.identity_purge(uuid),public.identity_purge_service(uuid) to service_role;

commit;


