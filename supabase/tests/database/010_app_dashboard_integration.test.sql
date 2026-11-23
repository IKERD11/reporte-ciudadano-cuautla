begin;
set local search_path=public,extensions;
create extension if not exists pgtap with schema extensions;
create temp table integration_results(result text);
grant all on integration_results to authenticated,anon;
insert into integration_results select plan(21);

insert into public.municipalities(id,name,state)
values('d6000000-0000-0000-0000-000000000001','App dashboard integration','Pruebas');
insert into public.settings(municipality_id,pilot_reports_enabled)
values('d6000000-0000-0000-0000-000000000001',true);
insert into auth.users(id,aud,role,email,email_confirmed_at)
select ('d6100000-0000-0000-0000-'||lpad(i::text,12,'0'))::uuid,
 'authenticated','authenticated','integration-'||i||'@example.test',now()
from generate_series(1,3) i;
insert into auth.sessions(id,user_id,created_at,updated_at)
select ('d6200000-0000-0000-0000-'||lpad(i::text,12,'0'))::uuid,
 ('d6100000-0000-0000-0000-'||lpad(i::text,12,'0'))::uuid,now(),now()
from generate_series(1,3) i;
insert into public.profiles(id,municipality_id,first_name)
select ('d6100000-0000-0000-0000-'||lpad(i::text,12,'0'))::uuid,
 'd6000000-0000-0000-0000-000000000001','Integration '||i
from generate_series(1,3) i;
insert into public.user_roles(user_id,municipality_id,role_id)
select p.id,p.municipality_id,r.id from public.profiles p join public.roles r
on r.code=case when right(p.id::text,1)='2' then 'MUNICIPAL_ADMIN' else 'CITIZEN' end
where p.id::text like 'd6100000-%';
insert into public.priorities(id,municipality_id,name,rank)
values('d6300000-0000-0000-0000-000000000001','d6000000-0000-0000-0000-000000000001','Media',2);
insert into public.categories(id,municipality_id,name,default_priority_id)
values('d6400000-0000-0000-0000-000000000001','d6000000-0000-0000-0000-000000000001','Integración','d6300000-0000-0000-0000-000000000001');
insert into public.departments(id,municipality_id,name)
values('d6600000-0000-0000-0000-000000000001','d6000000-0000-0000-0000-000000000001','Equipo de prueba');

create function pg_temp.app(action text) returns jsonb language sql as $$
 select public.report_pilot_service(
 'd6100000-0000-0000-0000-000000000001','d6200000-0000-0000-0000-000000000001',action,
 p_key:='d6500000-0000-0000-0000-000000000001',
 p_payload:='{"category_id":"d6400000-0000-0000-0000-000000000001","description":"Reporte sintético de integración app y dashboard","latitude":18.812,"longitude":-98.955,"address":"Dirección sintética de prueba","consent":true,"additional_data":{},"images":[]}',
 p_report:=(select id from public.reports where citizen_id='d6100000-0000-0000-0000-000000000001'));
$$;
create function pg_temp.claim(i integer) returns void language plpgsql as $$
begin perform set_config('request.jwt.claims',jsonb_build_object(
 'sub','d6100000-0000-0000-0000-'||lpad(i::text,12,'0'),
 'session_id','d6200000-0000-0000-0000-'||lpad(i::text,12,'0'),'role','authenticated')::text,true); end;
$$;
create temp table target(id uuid);
grant select on target to authenticated;
create function pg_temp.admin(action text,data jsonb default '{}') returns jsonb language sql as $$
 select public.admin_pilot(action,jsonb_build_object('id',(select id from target))||data);
$$;

insert into integration_results select is(pg_temp.app('context')->>'enabled','true','App creation enabled');
insert into integration_results select is(pg_temp.app('reserve')->>'committed','false','App reserves submission');
insert into integration_results select is(pg_temp.app('commit')->>'committed','true','App commits report');
insert into target select id from public.reports where citizen_id='d6100000-0000-0000-0000-000000000001';
insert into integration_results select is(pg_temp.app('commit')->>'committed','true','App retry succeeds');
insert into integration_results select is((select count(*)::int from public.reports where id in(select id from target)),1,'No duplicate report');
select pg_temp.claim(2);
set local role authenticated;
insert into integration_results select is(public.admin_pilot('list')->>'total','1','Dashboard sees app report');
insert into integration_results select is(pg_temp.admin('detail')->>'description','Reporte sintético de integración app y dashboard','Same content in dashboard');
insert into integration_results select is(pg_temp.admin('detail')->>'address','Dirección sintética de prueba','Same location reference');
insert into integration_results select is(public.admin_pilot('summary')->>'total','1','App report counted in metrics');
insert into integration_results select lives_ok($$select pg_temp.admin('status','{"version":0,"status":"EN_REVISION"}')$$,'Dashboard starts review');
insert into integration_results select throws_ok($$select pg_temp.admin('status','{"version":0,"status":"VALIDADO"}')$$,'40001',null,'Concurrent stale edit rejected');
insert into integration_results select lives_ok($$select pg_temp.admin('status','{"version":1,"status":"VALIDADO"}')$$,'Dashboard validates');
insert into integration_results select lives_ok($$select pg_temp.admin('assign','{"version":2,"department_id":"d6600000-0000-0000-0000-000000000001"}')$$,'Dashboard assigns department');
insert into integration_results select lives_ok($$select pg_temp.admin('status','{"version":3,"status":"EN_ATENCION"}')$$,'Dashboard starts attention');
insert into integration_results select lives_ok($$select pg_temp.admin('status','{"version":4,"status":"RESUELTO"}')$$,'Dashboard resolves');
reset role;
insert into integration_results select is(pg_temp.app('detail')->>'status','Resuelto','App reads admin resolution');
insert into integration_results select is(jsonb_array_length(pg_temp.app('detail')->'timeline'),6,'App sees full shared history');
select pg_temp.claim(1);
set local role authenticated;
insert into integration_results select is((public.citizen_notifications('count')->>'unread')::int,6,'App receives committed status notifications');
insert into integration_results select throws_ok($$select public.admin_pilot('context')$$,'42501',null,'Citizen cannot enter dashboard');
select pg_temp.claim(3);
insert into integration_results select is((public.citizen_notifications('count')->>'total')::int,0,'Another citizen cannot read owner notifications');
reset role;
insert into integration_results select throws_ok($$select public.report_pilot_service('d6100000-0000-0000-0000-000000000003','d6200000-0000-0000-0000-000000000003','detail',p_report:=(select id from target))$$,'42501',null,'Another citizen cannot read owner detail');
insert into integration_results select * from finish();
select jsonb_agg(result) as test_results from integration_results;
rollback;
