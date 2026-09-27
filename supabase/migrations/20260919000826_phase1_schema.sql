-- Fase 1. Infraestructura; las escrituras de clientes se habilitan por RPC en fases posteriores.
begin;
create schema if not exists extensions;
create extension if not exists postgis with schema extensions;
create schema if not exists private;
revoke all on schema private from public;

create type public.identity_status as enum ('PENDING','DOCUMENT_CAPTURED','PROCESSING','UNDER_REVIEW','VERIFIED','REJECTED','EXPIRED');

create table public.municipalities (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 1 and 160),
  state text not null,
  logo_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  municipality_id uuid not null references public.municipalities(id),
  first_name text not null default '' check (length(first_name) <= 120),
  last_name text not null default '' check (length(last_name) <= 160),
  phone text check (phone ~ '^\+[1-9][0-9]{7,14}$'),
  identity_status public.identity_status not null default 'PENDING',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (id, municipality_id)
);
create table public.roles (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code in ('SUPER_ADMIN','MUNICIPAL_ADMIN','SUPERVISOR','OPERATOR','VIEWER','CITIZEN')),
  description text not null
);
create table public.permissions (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  description text not null
);
create table public.role_permissions (
  role_id uuid not null references public.roles(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  primary key (role_id, permission_id)
);
create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  municipality_id uuid references public.municipalities(id),
  role_id uuid not null references public.roles(id),
  created_at timestamptz not null default now(),
  foreign key (user_id, municipality_id) references public.profiles(id, municipality_id),
  unique nulls not distinct (user_id, municipality_id, role_id)
);
create table public.priorities (
  id uuid primary key default gen_random_uuid(),
  municipality_id uuid not null references public.municipalities(id),
  name text not null,
  rank smallint not null check (rank > 0),
  is_active boolean not null default true,
  unique (municipality_id, name), unique (municipality_id, rank), unique (id, municipality_id)
);
create table public.report_statuses (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code in ('RECIBIDO','EN_REVISION','VALIDADO','ASIGNADO','EN_ATENCION','RESUELTO','CERRADO','RECHAZADO','DUPLICADO')),
  name text not null,
  is_terminal boolean not null default false
);
create table public.departments (
  id uuid primary key default gen_random_uuid(),
  municipality_id uuid not null references public.municipalities(id),
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (municipality_id, name), unique (id, municipality_id)
);
create table public.zones (
  id uuid primary key default gen_random_uuid(),
  municipality_id uuid not null references public.municipalities(id),
  name text not null,
  boundary extensions.geometry(MultiPolygon,4326) not null,
  check (extensions.st_isvalid(boundary) and not extensions.st_isempty(boundary)),
  unique (municipality_id, name), unique (id, municipality_id)
);
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  municipality_id uuid not null references public.municipalities(id),
  name text not null,
  description text,
  icon text,
  default_priority_id uuid not null,
  requires_photo boolean not null default false,
  requires_location boolean not null default true,
  is_public boolean not null default true,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  dynamic_form_schema jsonb not null default '{"type":"object","properties":{},"additionalProperties":false}'::jsonb,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check (jsonb_typeof(dynamic_form_schema) = 'object'),
  foreign key (default_priority_id, municipality_id) references public.priorities(id, municipality_id),
  unique (municipality_id, name), unique (id, municipality_id)
);
create table public.subcategories (
  id uuid primary key default gen_random_uuid(),
  municipality_id uuid not null references public.municipalities(id),
  category_id uuid not null,
  name text not null,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  foreign key (category_id, municipality_id) references public.categories(id, municipality_id),
  unique (category_id, name), unique (id, category_id, municipality_id)
);
create table public.settings (
  municipality_id uuid primary key references public.municipalities(id),
  -- Valores deben establecerse con la política institucional; no inferir plazos legales.
  identity_retention_days integer check (identity_retention_days between 1 and 3650),
  evidence_retention_days integer check (evidence_retention_days between 1 and 3650),
  privacy_notice_version text,
  privacy_notice_url text,
  emergency_contact text,
  max_report_images smallint not null default 5 check (max_report_images between 1 and 10),
  updated_at timestamptz not null default now()
);
create table public.consents (
  id uuid primary key default gen_random_uuid(),
  municipality_id uuid not null references public.municipalities(id),
  user_id uuid not null,
  consent_type text not null,
  privacy_notice_version text not null,
  accepted_at timestamptz not null default now(),
  foreign key (user_id, municipality_id) references public.profiles(id, municipality_id),
  unique (user_id, consent_type, privacy_notice_version)
);
create table public.identity_verifications (
  id uuid primary key default gen_random_uuid(),
  municipality_id uuid not null references public.municipalities(id),
  user_id uuid not null,
  provider text,
  provider_reference text,
  document_type text not null default 'INE' check (document_type = 'INE'),
  status public.identity_status not null default 'PENDING',
  -- Solo metadatos mínimos y no documentos ni respuestas crudas del proveedor.
  verification_metadata jsonb not null default '{}' check (jsonb_typeof(verification_metadata) = 'object'),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  verified_at timestamptz, rejected_at timestamptz, expires_at timestamptz,
  document_delete_after timestamptz, documents_deleted_at timestamptz,
  foreign key (user_id, municipality_id) references public.profiles(id, municipality_id),
  unique (id, municipality_id), unique (provider, provider_reference),
  check (status <> 'VERIFIED' or (verified_at is not null and expires_at is not null)),
  check (status <> 'REJECTED' or rejected_at is not null),
  check (expires_at is null or expires_at > created_at)
);

create sequence private.report_folio_seq;
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  folio text not null unique,
  municipality_id uuid not null references public.municipalities(id),
  citizen_id uuid not null,
  category_id uuid not null,
  subcategory_id uuid,
  priority_id uuid not null,
  status_id uuid not null references public.report_statuses(id),
  zone_id uuid,
  description text not null check (length(trim(description)) between 10 and 5000),
  location extensions.geography(Point,4326),
  approximate_address text check (length(approximate_address) <= 500),
  gps_accuracy numeric check (gps_accuracy >= 0 and gps_accuracy <= 100000),
  captured_at timestamptz,
  additional_data jsonb not null default '{}' check (jsonb_typeof(additional_data) = 'object'),
  form_schema_snapshot jsonb not null default '{}' check (jsonb_typeof(form_schema_snapshot) = 'object'),
  idempotency_key uuid not null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  resolved_at timestamptz, closed_at timestamptz,
  foreign key (citizen_id, municipality_id) references public.profiles(id, municipality_id),
  foreign key (category_id, municipality_id) references public.categories(id, municipality_id),
  foreign key (subcategory_id, category_id, municipality_id) references public.subcategories(id, category_id, municipality_id),
  foreign key (priority_id, municipality_id) references public.priorities(id, municipality_id),
  foreign key (zone_id, municipality_id) references public.zones(id, municipality_id),
  unique (citizen_id, idempotency_key), unique (id, municipality_id),
  check (closed_at is null or closed_at >= created_at),
  check (resolved_at is null or resolved_at >= created_at)
);
create table public.report_images (
  id uuid primary key default gen_random_uuid(),
  municipality_id uuid not null references public.municipalities(id),
  report_id uuid not null,
  storage_path text not null unique,
  mime_type text not null check (mime_type in ('image/jpeg','image/png','image/webp')),
  size bigint not null check (size > 0 and size <= 10485760),
  created_at timestamptz not null default now(),
  foreign key (report_id, municipality_id) references public.reports(id, municipality_id)
);
create table public.report_status_history (
  id uuid primary key default gen_random_uuid(),
  municipality_id uuid not null references public.municipalities(id),
  report_id uuid not null,
  previous_status_id uuid references public.report_statuses(id),
  new_status_id uuid not null references public.report_statuses(id),
  changed_by uuid references public.profiles(id),
  comment text check (length(comment) <= 2000),
  created_at timestamptz not null default now(),
  foreign key (report_id, municipality_id) references public.reports(id, municipality_id)
);
create table public.report_assignments (
  id uuid primary key default gen_random_uuid(),
  municipality_id uuid not null references public.municipalities(id),
  report_id uuid not null,
  department_id uuid not null,
  assigned_to uuid,
  assigned_by uuid references public.profiles(id),
  assigned_at timestamptz not null default now(), unassigned_at timestamptz,
  foreign key (report_id, municipality_id) references public.reports(id, municipality_id),
  foreign key (department_id, municipality_id) references public.departments(id, municipality_id),
  foreign key (assigned_to, municipality_id) references public.profiles(id, municipality_id),
  check (unassigned_at is null or unassigned_at >= assigned_at)
);
create table public.report_comments (
  id uuid primary key default gen_random_uuid(),
  municipality_id uuid not null references public.municipalities(id),
  report_id uuid not null,
  author_id uuid references public.profiles(id),
  body text not null check (length(trim(body)) between 1 and 4000),
  is_internal boolean not null default true,
  created_at timestamptz not null default now(),
  foreign key (report_id, municipality_id) references public.reports(id, municipality_id)
);
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  municipality_id uuid not null references public.municipalities(id),
  user_id uuid not null,
  report_id uuid,
  title text not null check (length(title) <= 200),
  body text not null check (length(body) <= 1000),
  read_at timestamptz,
  created_at timestamptz not null default now(),
  foreign key (user_id, municipality_id) references public.profiles(id, municipality_id),
  foreign key (report_id, municipality_id) references public.reports(id, municipality_id)
);
create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  municipality_id uuid not null references public.municipalities(id),
  actor_id uuid references public.profiles(id),
  action text not null,
  entity_type text not null,
  entity_id uuid,
  old_values jsonb not null default '{}', new_values jsonb not null default '{}', metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);
create table public.sla_rules (
  id uuid primary key default gen_random_uuid(),
  municipality_id uuid not null references public.municipalities(id),
  category_id uuid,
  priority_id uuid not null,
  response_minutes integer not null check (response_minutes > 0),
  resolution_minutes integer not null check (resolution_minutes >= response_minutes),
  is_active boolean not null default true,
  foreign key (category_id, municipality_id) references public.categories(id, municipality_id),
  foreign key (priority_id, municipality_id) references public.priorities(id, municipality_id),
  unique nulls not distinct (municipality_id, category_id, priority_id)
);

create index profiles_municipality_idx on public.profiles(municipality_id);
create index user_roles_lookup_idx on public.user_roles(user_id, municipality_id);
create index reports_municipality_created_idx on public.reports(municipality_id, created_at desc, id);
create index reports_citizen_created_idx on public.reports(citizen_id, created_at desc, id);
create index reports_status_priority_idx on public.reports(municipality_id, status_id, priority_id, created_at desc);
create index reports_category_created_idx on public.reports(municipality_id, category_id, created_at desc);
create index reports_location_gist on public.reports using gist(location);
create index zones_boundary_gist on public.zones using gist(boundary);
create index assignments_user_active_idx on public.report_assignments(assigned_to, report_id) where unassigned_at is null;
create unique index assignments_one_active_idx on public.report_assignments(report_id) where unassigned_at is null;
create index images_report_idx on public.report_images(report_id);
create index history_report_created_idx on public.report_status_history(report_id, created_at);
create index comments_report_created_idx on public.report_comments(report_id, created_at);
create index identity_user_idx on public.identity_verifications(user_id, created_at desc);
create index identity_review_idx on public.identity_verifications(municipality_id, status, created_at);
create index identity_retention_idx on public.identity_verifications(document_delete_after) where documents_deleted_at is null;
create index consents_user_idx on public.consents(user_id);
create index notifications_user_created_idx on public.notifications(user_id, created_at desc);
create index audit_municipality_created_idx on public.audit_logs(municipality_id, created_at desc);

-- Impedir permisos implícitos por default privileges de Supabase.
do $$ declare t record; begin
  for t in select tablename from pg_tables where schemaname = 'public' loop
    execute format('alter table public.%I enable row level security', t.tablename);
    execute format('revoke all on table public.%I from anon, authenticated', t.tablename);
  end loop;
end $$;
revoke all on all sequences in schema private from public, anon, authenticated;
commit;
