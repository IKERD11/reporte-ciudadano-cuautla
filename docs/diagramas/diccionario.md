# Diccionario estructural de tablas

Extraído del SQL, no de datos remotos. PK y UK compuestas se listan completas. Las columnas espaciales usan SRID 4326; reports.location es Point y zones.boundary es MultiPolygon. CHECK, DEFAULT e índices: consultar migraciones originales.

## public.municipalities

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `name` | `text` | No |
| `state` | `text` | No |
| `logo_url` | `text` | Sí |
| `is_active` | `bool` | No |
| `created_at` | `timestamptz` | No |
| `updated_at` | `timestamptz` | No |

PK: `id`.

## public.profiles

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `municipality_id` | `uuid` | No |
| `first_name` | `text` | No |
| `last_name` | `text` | No |
| `phone` | `text` | Sí |
| `identity_status` | `public.identity_status` | No |
| `is_active` | `bool` | No |
| `created_at` | `timestamptz` | No |
| `updated_at` | `timestamptz` | No |
| `deleted_at` | `timestamptz` | Sí |

PK: `id`.

UNIQUE: `id, municipality_id`.

FK: `(id)` → `auth.users(id)`.

FK: `(municipality_id)` → `public.municipalities(id)`.

## public.roles

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `code` | `text` | No |
| `description` | `text` | No |

PK: `id`.

UNIQUE: `code`.

## public.permissions

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `code` | `text` | No |
| `description` | `text` | No |

PK: `id`.

UNIQUE: `code`.

## public.role_permissions

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `role_id` | `uuid` | No |
| `permission_id` | `uuid` | No |

PK: `role_id, permission_id`.

FK: `(role_id)` → `public.roles(id)`.

FK: `(permission_id)` → `public.permissions(id)`.

## public.user_roles

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `user_id` | `uuid` | No |
| `municipality_id` | `uuid` | Sí |
| `role_id` | `uuid` | No |
| `created_at` | `timestamptz` | No |

PK: `id`.

UNIQUE: `user_id, municipality_id, role_id`.

FK: `(user_id)` → `public.profiles(id)`.

FK: `(municipality_id)` → `public.municipalities(id)`.

FK: `(role_id)` → `public.roles(id)`.

FK: `(user_id, municipality_id)` → `public.profiles(id, municipality_id)`.

## public.priorities

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `municipality_id` | `uuid` | No |
| `name` | `text` | No |
| `rank` | `int2` | No |
| `is_active` | `bool` | No |

PK: `id`.

UNIQUE: `municipality_id, name`.

UNIQUE: `municipality_id, rank`.

UNIQUE: `id, municipality_id`.

FK: `(municipality_id)` → `public.municipalities(id)`.

## public.report_statuses

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `code` | `text` | No |
| `name` | `text` | No |
| `is_terminal` | `bool` | No |

PK: `id`.

UNIQUE: `code`.

## public.departments

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `municipality_id` | `uuid` | No |
| `name` | `text` | No |
| `is_active` | `bool` | No |
| `created_at` | `timestamptz` | No |
| `updated_at` | `timestamptz` | No |

PK: `id`.

UNIQUE: `municipality_id, name`.

UNIQUE: `id, municipality_id`.

FK: `(municipality_id)` → `public.municipalities(id)`.

## public.zones

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `municipality_id` | `uuid` | No |
| `name` | `text` | No |
| `boundary` | `extensions.geometry` | No |

PK: `id`.

UNIQUE: `municipality_id, name`.

UNIQUE: `id, municipality_id`.

FK: `(municipality_id)` → `public.municipalities(id)`.

## public.categories

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `municipality_id` | `uuid` | No |
| `name` | `text` | No |
| `description` | `text` | Sí |
| `icon` | `text` | Sí |
| `default_priority_id` | `uuid` | No |
| `requires_photo` | `bool` | No |
| `requires_location` | `bool` | No |
| `is_public` | `bool` | No |
| `is_active` | `bool` | No |
| `sort_order` | `int4` | No |
| `dynamic_form_schema` | `jsonb` | No |
| `created_at` | `timestamptz` | No |
| `updated_at` | `timestamptz` | No |

PK: `id`.

UNIQUE: `municipality_id, name`.

UNIQUE: `id, municipality_id`.

FK: `(municipality_id)` → `public.municipalities(id)`.

FK: `(default_priority_id, municipality_id)` → `public.priorities(id, municipality_id)`.

## public.subcategories

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `municipality_id` | `uuid` | No |
| `category_id` | `uuid` | No |
| `name` | `text` | No |
| `is_active` | `bool` | No |
| `sort_order` | `int4` | No |

PK: `id`.

UNIQUE: `category_id, name`.

UNIQUE: `id, category_id, municipality_id`.

FK: `(municipality_id)` → `public.municipalities(id)`.

FK: `(category_id, municipality_id)` → `public.categories(id, municipality_id)`.

## public.settings

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `municipality_id` | `uuid` | No |
| `identity_retention_days` | `int4` | Sí |
| `evidence_retention_days` | `int4` | Sí |
| `privacy_notice_version` | `text` | Sí |
| `privacy_notice_url` | `text` | Sí |
| `emergency_contact` | `text` | Sí |
| `max_report_images` | `int2` | No |
| `updated_at` | `timestamptz` | No |
| `citizen_registration_enabled` | `bool` | No |
| `pilot_reports_enabled` | `bool` | No |

PK: `municipality_id`.

FK: `(municipality_id)` → `public.municipalities(id)`.

## public.consents

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `municipality_id` | `uuid` | No |
| `user_id` | `uuid` | No |
| `consent_type` | `text` | No |
| `privacy_notice_version` | `text` | No |
| `accepted_at` | `timestamptz` | No |

PK: `id`.

UNIQUE: `user_id, consent_type, privacy_notice_version`.

FK: `(municipality_id)` → `public.municipalities(id)`.

FK: `(user_id, municipality_id)` → `public.profiles(id, municipality_id)`.

## public.identity_verifications

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `municipality_id` | `uuid` | No |
| `user_id` | `uuid` | No |
| `provider` | `text` | Sí |
| `provider_reference` | `text` | Sí |
| `document_type` | `text` | No |
| `status` | `public.identity_status` | No |
| `verification_metadata` | `jsonb` | No |
| `created_at` | `timestamptz` | No |
| `updated_at` | `timestamptz` | No |
| `verified_at` | `timestamptz` | Sí |
| `rejected_at` | `timestamptz` | Sí |
| `expires_at` | `timestamptz` | Sí |
| `document_delete_after` | `timestamptz` | Sí |
| `documents_deleted_at` | `timestamptz` | Sí |
| `is_synthetic` | `bool` | No |
| `consent_id` | `uuid` | Sí |
| `request_key` | `uuid` | Sí |

PK: `id`.

UNIQUE: `id, municipality_id`.

UNIQUE: `provider, provider_reference`.

FK: `(municipality_id)` → `public.municipalities(id)`.

FK: `(user_id, municipality_id)` → `public.profiles(id, municipality_id)`.

FK: `(consent_id)` → `public.consents(id)`.

## public.reports

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `folio` | `text` | No |
| `municipality_id` | `uuid` | No |
| `citizen_id` | `uuid` | No |
| `category_id` | `uuid` | No |
| `subcategory_id` | `uuid` | Sí |
| `priority_id` | `uuid` | No |
| `status_id` | `uuid` | No |
| `zone_id` | `uuid` | Sí |
| `description` | `text` | No |
| `location` | `extensions.geography` | Sí |
| `approximate_address` | `text` | Sí |
| `gps_accuracy` | `numeric` | Sí |
| `captured_at` | `timestamptz` | Sí |
| `additional_data` | `jsonb` | No |
| `form_schema_snapshot` | `jsonb` | No |
| `idempotency_key` | `uuid` | No |
| `created_at` | `timestamptz` | No |
| `updated_at` | `timestamptz` | No |
| `resolved_at` | `timestamptz` | Sí |
| `closed_at` | `timestamptz` | Sí |
| `is_pilot` | `bool` | No |
| `admin_version` | `int8` | No |

PK: `id`.

UNIQUE: `folio`.

UNIQUE: `citizen_id, idempotency_key`.

UNIQUE: `id, municipality_id`.

FK: `(municipality_id)` → `public.municipalities(id)`.

FK: `(status_id)` → `public.report_statuses(id)`.

FK: `(citizen_id, municipality_id)` → `public.profiles(id, municipality_id)`.

FK: `(category_id, municipality_id)` → `public.categories(id, municipality_id)`.

FK: `(subcategory_id, category_id, municipality_id)` → `public.subcategories(id, category_id, municipality_id)`.

FK: `(priority_id, municipality_id)` → `public.priorities(id, municipality_id)`.

FK: `(zone_id, municipality_id)` → `public.zones(id, municipality_id)`.

## public.report_images

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `municipality_id` | `uuid` | No |
| `report_id` | `uuid` | No |
| `storage_path` | `text` | No |
| `mime_type` | `text` | No |
| `size` | `int8` | No |
| `created_at` | `timestamptz` | No |

PK: `id`.

UNIQUE: `storage_path`.

FK: `(municipality_id)` → `public.municipalities(id)`.

FK: `(report_id, municipality_id)` → `public.reports(id, municipality_id)`.

## public.report_status_history

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `municipality_id` | `uuid` | No |
| `report_id` | `uuid` | No |
| `previous_status_id` | `uuid` | Sí |
| `new_status_id` | `uuid` | No |
| `changed_by` | `uuid` | Sí |
| `comment` | `text` | Sí |
| `created_at` | `timestamptz` | No |

PK: `id`.

FK: `(municipality_id)` → `public.municipalities(id)`.

FK: `(previous_status_id)` → `public.report_statuses(id)`.

FK: `(new_status_id)` → `public.report_statuses(id)`.

FK: `(changed_by)` → `public.profiles(id)`.

FK: `(report_id, municipality_id)` → `public.reports(id, municipality_id)`.

## public.report_assignments

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `municipality_id` | `uuid` | No |
| `report_id` | `uuid` | No |
| `department_id` | `uuid` | No |
| `assigned_to` | `uuid` | Sí |
| `assigned_by` | `uuid` | Sí |
| `assigned_at` | `timestamptz` | No |
| `unassigned_at` | `timestamptz` | Sí |

PK: `id`.

FK: `(municipality_id)` → `public.municipalities(id)`.

FK: `(assigned_by)` → `public.profiles(id)`.

FK: `(report_id, municipality_id)` → `public.reports(id, municipality_id)`.

FK: `(department_id, municipality_id)` → `public.departments(id, municipality_id)`.

FK: `(assigned_to, municipality_id)` → `public.profiles(id, municipality_id)`.

## public.report_comments

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `municipality_id` | `uuid` | No |
| `report_id` | `uuid` | No |
| `author_id` | `uuid` | Sí |
| `body` | `text` | No |
| `is_internal` | `bool` | No |
| `created_at` | `timestamptz` | No |

PK: `id`.

FK: `(municipality_id)` → `public.municipalities(id)`.

FK: `(author_id)` → `public.profiles(id)`.

FK: `(report_id, municipality_id)` → `public.reports(id, municipality_id)`.

## public.notifications

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `municipality_id` | `uuid` | No |
| `user_id` | `uuid` | No |
| `report_id` | `uuid` | Sí |
| `title` | `text` | No |
| `body` | `text` | No |
| `read_at` | `timestamptz` | Sí |
| `created_at` | `timestamptz` | No |

PK: `id`.

FK: `(municipality_id)` → `public.municipalities(id)`.

FK: `(user_id, municipality_id)` → `public.profiles(id, municipality_id)`.

FK: `(report_id, municipality_id)` → `public.reports(id, municipality_id)`.

## public.audit_logs

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `municipality_id` | `uuid` | No |
| `actor_id` | `uuid` | Sí |
| `action` | `text` | No |
| `entity_type` | `text` | No |
| `entity_id` | `uuid` | Sí |
| `old_values` | `jsonb` | No |
| `new_values` | `jsonb` | No |
| `metadata` | `jsonb` | No |
| `created_at` | `timestamptz` | No |

PK: `id`.

FK: `(municipality_id)` → `public.municipalities(id)`.

FK: `(actor_id)` → `public.profiles(id)`.

## public.sla_rules

Creada en `20260919000826_phase1_schema.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `municipality_id` | `uuid` | No |
| `category_id` | `uuid` | Sí |
| `priority_id` | `uuid` | No |
| `response_minutes` | `int4` | No |
| `resolution_minutes` | `int4` | No |
| `is_active` | `bool` | No |

PK: `id`.

UNIQUE: `municipality_id, category_id, priority_id`.

FK: `(municipality_id)` → `public.municipalities(id)`.

FK: `(category_id, municipality_id)` → `public.categories(id, municipality_id)`.

FK: `(priority_id, municipality_id)` → `public.priorities(id, municipality_id)`.

## private.identity_documents

Creada en `20260924170343_phase3_synthetic_identity.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `verification_id` | `uuid` | No |
| `side` | `text` | No |
| `storage_path` | `text` | No |
| `uploaded_at` | `timestamptz` | Sí |
| `deleted_at` | `timestamptz` | Sí |

PK: `verification_id, side`.

UNIQUE: `storage_path`.

FK: `(verification_id)` → `public.identity_verifications(id)`.

## private.report_uploads

Creada en `20260925174611_phase4_pilot_reports.sql`; incluye columnas añadidas por migraciones posteriores.

| Columna | Tipo SQL | Admite NULL |
|---|---|---|
| `id` | `uuid` | No |
| `actor` | `uuid` | No |
| `municipality_id` | `uuid` | No |
| `request_key` | `uuid` | No |
| `payload` | `jsonb` | No |
| `created_at` | `timestamptz` | No |
| `expires_at` | `timestamptz` | No |
| `committed_at` | `timestamptz` | Sí |
| `purged_at` | `timestamptz` | Sí |

PK: `id`.

UNIQUE: `actor, request_key`.

FK: `(actor)` → `public.profiles(id)`.

FK: `(municipality_id)` → `public.municipalities(id)`.
