begin;
create extension if not exists pgtap with schema extensions;
select plan(35);

select is((select count(*)::integer from pg_tables where schemaname = 'public' and not rowsecurity),0,'Todas las tablas públicas tienen RLS');
select ok(exists(select 1 from pg_extension where extname = 'postgis'),'PostGIS instalado');
select is((select count(*)::integer from storage.buckets where id in ('identity-documents','report-evidence') and not public),2,'Buckets privados');
select is((select count(*)::integer from public.reports),3,'Fixtures locales cargados');
select is((select count(*)::integer from public.report_status_history),3,'Estado inicial tiene historial');

set local role authenticated;
select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000001',true);
select is((select count(*)::integer from public.reports),1,'Ciudadano A solo lee su reporte');
select is((select count(*)::integer from public.reports where citizen_id = '20000000-0000-0000-0000-000000000002'),0,'Ciudadano A no ve ciudadano B');
select is((select count(*)::integer from public.categories),1,'Catálogos aislados por municipio');
select is((select count(*)::integer from public.report_comments),1,'Comentarios internos ocultos');
select is((select count(*)::integer from public.identity_verifications),0,'Metadatos de identidad no se exponen al ciudadano');
select throws_ok($$update public.reports set priority_id = priority_id$$,'42501','permission denied for table reports','Ciudadano no cambia prioridad');
select throws_ok($$update public.reports set status_id = status_id$$,'42501','permission denied for table reports','Ciudadano no cambia estado');
select throws_ok($$update public.profiles set identity_status = 'VERIFIED'$$,'42501','permission denied for table profiles','No autoverificación');
select throws_ok($$insert into public.user_roles(user_id,role_id) select auth.uid(),id from public.roles where code='SUPER_ADMIN'$$,'42501','permission denied for table user_roles','No escalación de rol');
select throws_ok($$insert into public.reports default values$$,'42501','permission denied for table reports','Creación de reporte cerrada hasta RPC validada');
select is((select count(*)::integer from public.audit_logs),0,'Ciudadano no lee auditoría');

select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000004',true);
select is((select count(*)::integer from public.reports),1,'Operador solo lee asignado');
select is((select count(*)::integer from public.reports where municipality_id='10000000-0000-0000-0000-000000000002'),0,'Operador A no lee municipio B');
select is((select count(*)::integer from public.identity_verifications),0,'Operador sin identity.read no lee INE');
select is((select count(*)::integer from public.report_comments),2,'Operador asignado puede leer nota interna');

select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000005',true);
select is((select count(*)::integer from public.reports),2,'Administrador lee su municipio');
select is((select count(*)::integer from public.identity_verifications),0,'Administrador no obtiene identity.read implícito');
select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000007',true);
select is((select count(*)::integer from public.reports),2,'Viewer tiene lectura municipal');
select throws_ok($$delete from public.reports$$,'42501','permission denied for table reports','Viewer no elimina');
select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000008',true);
select is((select count(*)::integer from public.reports),3,'Superadmin global explícito');
select is((select count(*)::integer from public.identity_verifications),3,'Superadmin tiene identity.read explícito');

set local role anon;
select throws_ok($$select id from public.reports$$,'42501','permission denied for table reports','Anónimo no lee reportes');
select throws_ok($$select id from public.profiles$$,'42501','permission denied for table profiles','Anónimo no lee perfiles');

reset role;
select throws_ok($$update public.reports set category_id='30000000-0000-0000-0000-000000000002' where id='50000000-0000-0000-0000-000000000001'$$,'23503',null,'FK rechaza categoría de otro municipio');
select throws_ok($$update public.report_assignments set department_id='40000000-0000-0000-0000-000000000002'$$,'23503',null,'FK rechaza departamento de otro municipio');
select throws_ok($$update public.user_roles set municipality_id=null where user_id='20000000-0000-0000-0000-000000000004'$$,'23514',null,'Operador no puede adquirir alcance global');
select ok((select bool_and(folio ~ '^REP-[0-9]{4}-[0-9]{6,}$') from public.reports),'Folios de servidor');
select throws_ok($$update public.reports set citizen_id='20000000-0000-0000-0000-000000000001',idempotency_key='50000000-0000-0000-0000-000000000001' where id='50000000-0000-0000-0000-000000000002'$$,'23505',null,'Idempotencia única por ciudadano');
update public.profiles set is_active=false where id='20000000-0000-0000-0000-000000000004';
set local role authenticated;
select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000004',true);
select is((select count(*)::integer from public.reports),0,'Desactivar perfil revoca acceso');
reset role;
select is((select count(*)::integer from pg_publication_tables where pubname='supabase_realtime' and schemaname='public'),0,'No publicar datos sensibles accidentalmente');
select * from finish();
rollback;
