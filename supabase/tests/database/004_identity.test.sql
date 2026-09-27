begin;
set local search_path=public,extensions;
create extension if not exists pgtap with schema extensions;
select plan(12);
insert into public.municipalities(id,name,state) values('b3000000-0000-0000-0000-000000000001','Identidad Test','Pruebas');
insert into auth.users(id,aud,role,email,email_confirmed_at) values
('b3100000-0000-0000-0000-000000000001','authenticated','authenticated','identity-a@example.test',now()),
('b3100000-0000-0000-0000-000000000002','authenticated','authenticated','identity-b@example.test',now());
insert into auth.sessions(id,user_id,created_at,updated_at) values
('b3200000-0000-0000-0000-000000000001','b3100000-0000-0000-0000-000000000001',now(),now()),
('b3200000-0000-0000-0000-000000000002','b3100000-0000-0000-0000-000000000002',now(),now());
insert into public.profiles(id,municipality_id) values
('b3100000-0000-0000-0000-000000000001','b3000000-0000-0000-0000-000000000001'),
('b3100000-0000-0000-0000-000000000002','b3000000-0000-0000-0000-000000000001');
set local role authenticated;
select throws_ok($$select public.identity_pilot_service('b3100000-0000-0000-0000-000000000001','b3200000-0000-0000-0000-000000000001','context')$$,'42501',null,'Cliente no invoca servicio privilegiado');
select throws_ok($$select public.identity_purge_service()$$,'42501',null,'Cliente no ejecuta purga');
reset role;
select throws_ok($$select public.identity_pilot_service('b3100000-0000-0000-0000-000000000001','b3200000-0000-0000-0000-000000000002','context')$$,'42501',null,'Sesión ajena rechazada');
select throws_ok($$select public.identity_pilot_service('b3100000-0000-0000-0000-000000000001','b3200000-0000-0000-0000-000000000001','begin',null,'b3300000-0000-0000-0000-000000000001',null,'wrong')$$,'22023',null,'Requiere versión de consentimiento exacta');
select is(public.identity_pilot_service('b3100000-0000-0000-0000-000000000001','b3200000-0000-0000-0000-000000000001','begin',null,'b3300000-0000-0000-0000-000000000001',null,'synthetic-v1')->>'mode','synthetic','Inicia solo modo sintético');
select public.identity_pilot_service('b3100000-0000-0000-0000-000000000001','b3200000-0000-0000-0000-000000000001','begin',null,'b3300000-0000-0000-0000-000000000001',null,'synthetic-v1');
select is((select count(*)::int from public.identity_verifications where user_id='b3100000-0000-0000-0000-000000000001'),1,'Reintento no duplica solicitudes');
select is((select count(*)::int from public.consents where user_id='b3100000-0000-0000-0000-000000000001'),1,'Consentimiento único');
select is((select identity_status::text from public.profiles where id='b3100000-0000-0000-0000-000000000001'),'PENDING','Prueba no verifica identidad real');
select throws_ok($$select public.identity_pilot_service('b3100000-0000-0000-0000-000000000002','b3200000-0000-0000-0000-000000000002','reserve',(select id from public.identity_verifications where user_id='b3100000-0000-0000-0000-000000000001'),null,'front')$$,'42501',null,'No carga a solicitud ajena');
select throws_ok($$select public.identity_pilot_service('b3100000-0000-0000-0000-000000000001','b3200000-0000-0000-0000-000000000001','submit',(select id from public.identity_verifications where user_id='b3100000-0000-0000-0000-000000000001'))$$,'22023',null,'No envía solicitud incompleta');
select throws_ok($$select public.identity_pilot_service('b3100000-0000-0000-0000-000000000001','b3200000-0000-0000-0000-000000000001','read',(select id from public.identity_verifications where user_id='b3100000-0000-0000-0000-000000000001'),null,'front')$$,'42501',null,'Ciudadano no obtiene URL de documento');
delete from auth.sessions where id='b3200000-0000-0000-0000-000000000001';
select throws_ok($$select public.identity_pilot_service('b3100000-0000-0000-0000-000000000001','b3200000-0000-0000-0000-000000000001','context')$$,'42501',null,'Sesión revocada rechazada');
select * from finish();
rollback;
