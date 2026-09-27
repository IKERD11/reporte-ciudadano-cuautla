begin;
set local search_path=public,extensions;
create extension if not exists pgtap with schema extensions;
select plan(26);
insert into public.municipalities(id,name,state) values('d4000000-0000-0000-0000-000000000001','Report Test','Pruebas'),('d4000000-0000-0000-0000-000000000002','Other Test','Pruebas');
insert into public.settings(municipality_id,pilot_reports_enabled) values('d4000000-0000-0000-0000-000000000001',true);
insert into auth.users(id,aud,role,email,email_confirmed_at) values
('d4100000-0000-0000-0000-000000000001','authenticated','authenticated','report-a@example.test',now()),
('d4100000-0000-0000-0000-000000000002','authenticated','authenticated','report-b@example.test',now());
insert into auth.sessions(id,user_id,created_at,updated_at) values
('d4200000-0000-0000-0000-000000000001','d4100000-0000-0000-0000-000000000001',now(),now()),
('d4200000-0000-0000-0000-000000000002','d4100000-0000-0000-0000-000000000002',now(),now());
insert into public.profiles(id,municipality_id) values
('d4100000-0000-0000-0000-000000000001','d4000000-0000-0000-0000-000000000001'),
('d4100000-0000-0000-0000-000000000002','d4000000-0000-0000-0000-000000000002');
insert into public.user_roles(user_id,municipality_id,role_id) select id,municipality_id,(select id from public.roles where code='CITIZEN') from public.profiles where id::text like 'd4100000-%';
insert into public.priorities(id,municipality_id,name,rank) values('d4300000-0000-0000-0000-000000000001','d4000000-0000-0000-0000-000000000001','Media',2);
insert into public.categories(id,municipality_id,name,default_priority_id,dynamic_form_schema) values
('d4400000-0000-0000-0000-000000000001','d4000000-0000-0000-0000-000000000001','Test','d4300000-0000-0000-0000-000000000001','{"type":"object","properties":{"count":{"type":"integer","minimum":1}},"required":["count"],"additionalProperties":false}');
create function pg_temp.payload() returns jsonb language sql as $$select '{"category_id":"d4400000-0000-0000-0000-000000000001","description":"Reporte exclusivamente de prueba","latitude":18.812,"longitude":-98.955,"consent":true,"additional_data":{"count":2},"images":[]}'::jsonb$$;
create function pg_temp.call(action text,payload jsonb default pg_temp.payload(),key uuid default 'd4500000-0000-0000-0000-000000000001') returns jsonb language sql as $$select public.report_pilot_service('d4100000-0000-0000-0000-000000000001','d4200000-0000-0000-0000-000000000001',action,key,payload)$$;
set local role authenticated;
select throws_ok($$select public.report_pilot_service('d4100000-0000-0000-0000-000000000001','d4200000-0000-0000-0000-000000000001','context')$$,'42501',null,'Cliente no llama RPC privilegiada');
reset role;
select throws_ok($$select public.report_pilot_service('d4100000-0000-0000-0000-000000000001','d4200000-0000-0000-0000-000000000002','context')$$,'42501',null,'Sesión ajena rechazada');
select throws_ok($$select pg_temp.call('reserve',pg_temp.payload()||'{"consent":false}')$$,'22023',null,'Consentimiento obligatorio');
select throws_ok($$select pg_temp.call('reserve',pg_temp.payload()||'{"additional_data":{"count":0}}')$$,'22023',null,'JSON schema valida mínimo');
select throws_ok($$select pg_temp.call('reserve',pg_temp.payload()||'{"additional_data":{"count":2,"extra":true}}')$$,'22023',null,'Campos desconocidos rechazados');
select throws_ok($$select pg_temp.call('reserve',pg_temp.payload()||'{"latitude":91}')$$,'22023',null,'Coordenadas inválidas rechazadas');
select throws_ok($$select pg_temp.call('reserve',pg_temp.payload()||'{"latitude":null}')$$,'22023',null,'Ubicación requerida');
select is(pg_temp.call('reserve')->>'committed','false','Reserva sin crear reporte');
select is(pg_temp.call('commit')->>'committed','true','Crea reporte piloto');
select is(pg_temp.call('commit')->>'committed','true','Reintento exitoso');
select is((select count(*)::int from public.reports where citizen_id='d4100000-0000-0000-0000-000000000001'),1,'No duplica reportes');
select ok((select is_pilot and folio like 'REP-%' and priority_id='d4300000-0000-0000-0000-000000000001' from public.reports where citizen_id='d4100000-0000-0000-0000-000000000001'),'Etiqueta, folio y prioridad del servidor');
select is((select identity_status::text from public.profiles where id='d4100000-0000-0000-0000-000000000001'),'PENDING','No verifica identidad');
select is((select count(*)::int from public.report_status_history where report_id in(select id from public.reports where citizen_id='d4100000-0000-0000-0000-000000000001')),1,'Historial inicial único');
select throws_ok($$select pg_temp.call('commit',pg_temp.payload()||'{"description":"Contenido modificado en reintento"}')$$,'22023',null,'Idempotencia ligada a contenido');
select throws_ok($$select public.report_pilot_service('d4100000-0000-0000-0000-000000000002','d4200000-0000-0000-0000-000000000002','detail',p_report:=(select id from public.reports where citizen_id='d4100000-0000-0000-0000-000000000001'))$$,'42501',null,'Otro municipio no lee detalle');
select is(jsonb_array_length(public.report_pilot_service('d4100000-0000-0000-0000-000000000002','d4200000-0000-0000-0000-000000000002','list')->'reports'),0,'Lista de otro ciudadano vacía');
update public.categories set requires_photo=true where id='d4400000-0000-0000-0000-000000000001';
select throws_ok($$select pg_temp.call('reserve',pg_temp.payload(),'d4500000-0000-0000-0000-000000000002')$$,'22023',null,'Foto requerida por categoría');
update public.categories set requires_photo=false where id='d4400000-0000-0000-0000-000000000001';
select pg_temp.call('reserve',pg_temp.payload()||jsonb_build_object('images',jsonb_build_array(jsonb_build_object('size',100,'sha256',repeat('a',64)))),'d4500000-0000-0000-0000-000000000002');
select throws_ok($$select pg_temp.call('commit',pg_temp.payload()||jsonb_build_object('images',jsonb_build_array(jsonb_build_object('size',100,'sha256',repeat('a',64)))),'d4500000-0000-0000-0000-000000000002')$$,'22023',null,'No confirma carga incompleta');
select throws_ok($$select pg_temp.call('reserve',pg_temp.payload()||'{"latitude":null,"longitude":null,"address":"   "}','d4500000-0000-0000-0000-000000000003')$$,'22023',null,'No acepta ubicación vacía');
select throws_ok($$select pg_temp.call('reserve',pg_temp.payload()||'{"latitude":null,"longitude":null,"address":"Calle"}','d4500000-0000-0000-0000-000000000003')$$,'22023',null,'Dirección demasiado corta rechazada');
select is(pg_temp.call('reserve',pg_temp.payload()||'{"latitude":null,"longitude":null,"address":"Calle de prueba 123, Centro, Cuautla"}','d4500000-0000-0000-0000-000000000003')->>'committed','false','Reserva con dirección sin GPS');
select is(pg_temp.call('commit',pg_temp.payload()||'{"latitude":null,"longitude":null,"address":"Calle de prueba 123, Centro, Cuautla"}','d4500000-0000-0000-0000-000000000003')->>'committed','true','Envía dirección sin GPS');
select ok((select location is null and approximate_address='Calle de prueba 123, Centro, Cuautla' from public.reports where id=(select id from private.report_uploads where request_key='d4500000-0000-0000-0000-000000000003')),'Guarda dirección sin inventar coordenadas');
update public.settings set pilot_reports_enabled=false where municipality_id='d4000000-0000-0000-0000-000000000001';
select throws_ok($$select pg_temp.call('reserve',pg_temp.payload(),'d4500000-0000-0000-0000-000000000003')$$,'42501',null,'Desactivar piloto bloquea envío');
delete from auth.sessions where id='d4200000-0000-0000-0000-000000000001';
select throws_ok($$select pg_temp.call('context')$$,'42501',null,'Sesión revocada rechazada');
select * from finish();
rollback;

