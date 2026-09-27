begin;
set local search_path=public,extensions;
create extension if not exists pgtap with schema extensions;
select plan(22);
-- Transaccional: UUID exclusivos; una colisión aborta sin tocar datos existentes.
insert into public.municipalities(id,name,state) values
('a2000000-0000-0000-0000-000000000001','Auth test A','Pruebas'),
('a2000000-0000-0000-0000-000000000002','Auth test B','Pruebas');
insert into public.settings(municipality_id,citizen_registration_enabled) values
('a2000000-0000-0000-0000-000000000001',true),('a2000000-0000-0000-0000-000000000002',false);
insert into auth.users(id,aud,role,email,email_confirmed_at,raw_user_meta_data) values
('a2100000-0000-0000-0000-000000000001','authenticated','authenticated','auth-phase2-a@example.test',now(),'{"role":"SUPER_ADMIN","identity_status":"VERIFIED"}'),
('a2100000-0000-0000-0000-000000000002','authenticated','authenticated','auth-phase2-b@example.test',null,'{}');
set local role anon;
select throws_ok($$select public.list_registration_municipalities()$$,'42501',null,'Anónimo no enumera municipios');
select throws_ok($$select public.complete_citizen_profile('a2000000-0000-0000-0000-000000000001','A','B')$$,'42501',null,'Anónimo no crea perfil');
set local role authenticated;
select set_config('request.jwt.claim.sub','a2100000-0000-0000-0000-000000000002',true);
select throws_ok($$select public.list_registration_municipalities()$$,'42501',null,'Correo sin confirmar no enumera');
select throws_ok($$select public.complete_citizen_profile('a2000000-0000-0000-0000-000000000001','A','B')$$,'42501',null,'Correo sin confirmar no crea perfil');
select set_config('request.jwt.claim.sub','a2100000-0000-0000-0000-000000000001',true);
select is((select count(*)::int from public.list_registration_municipalities() where id='a2000000-0000-0000-0000-000000000002'),0,'Municipio cerrado oculto');
select throws_ok($$select public.complete_citizen_profile('a2000000-0000-0000-0000-000000000002','A','B')$$,'42501',null,'Municipio cerrado rechaza alta');
select throws_ok($$select public.complete_citizen_profile('a2000000-0000-0000-0000-000000000001',' ','B')$$,'22023',null,'Nombre vacío rechazado');
select is((public.complete_citizen_profile('a2000000-0000-0000-0000-000000000001',' Ana ',' Pérez ')).first_name,'Ana','Alta recorta nombres');
select is((public.complete_citizen_profile('a2000000-0000-0000-0000-000000000001','Otro','Cambio')).first_name,'Ana','Reintento idempotente conserva perfil');
select throws_ok($$select public.complete_citizen_profile('a2000000-0000-0000-0000-000000000002','A','B')$$,'42501',null,'No permite cambiar municipio');
select is((select identity_status::text from public.profiles where id=auth.uid()),'PENDING','Ignora metadatos de verificación');
select throws_ok($$update public.profiles set identity_status='VERIFIED' where id=auth.uid()$$,'42501',null,'No permite escritura directa');
select throws_ok($$select public.update_my_profile('Ana','Pérez','123')$$,'22023',null,'Teléfono inválido rechazado');
select is((public.update_my_profile('Ana María','Pérez','+525512345678')).phone,'+525512345678','Edita perfil propio');
reset role;
select is((select count(*)::int from public.user_roles ur join public.roles r on r.id=ur.role_id where ur.user_id='a2100000-0000-0000-0000-000000000001' and r.code='CITIZEN'),1,'Asigna CITIZEN una sola vez');
select is((select count(*)::int from public.user_roles where user_id='a2100000-0000-0000-0000-000000000001'),1,'Ignora SUPER_ADMIN de metadatos');
select is((select count(*)::int from public.audit_logs where actor_id='a2100000-0000-0000-0000-000000000001' and old_values='{}'::jsonb and new_values='{}'::jsonb and metadata='{}'::jsonb),2,'Auditoría de alta y edición sin PII');
update public.profiles set is_active=false where id='a2100000-0000-0000-0000-000000000001';
set local role authenticated;
select throws_ok($$select public.complete_citizen_profile('a2000000-0000-0000-0000-000000000001','A','B')$$,'42501',null,'No reactiva perfil suspendido');
select throws_ok($$select public.update_my_profile('A','B',null)$$,'42501',null,'No edita perfil suspendido');
reset role;
update auth.users set banned_until=now()+interval '1 day' where id='a2100000-0000-0000-0000-000000000001';
set local role authenticated;
select throws_ok($$select public.list_registration_municipalities()$$,'42501',null,'Cuenta bloqueada rechazada');
reset role;
update auth.users set banned_until=null,is_anonymous=true where id='a2100000-0000-0000-0000-000000000001';
set local role authenticated;
select throws_ok($$select public.list_registration_municipalities()$$,'42501',null,'Sesión anónima rechazada');
reset role;
select is((select count(*)::int from public.profiles where id='a2100000-0000-0000-0000-000000000002'),0,'Nunca crea perfil para otro usuario');
select * from finish();
rollback;
