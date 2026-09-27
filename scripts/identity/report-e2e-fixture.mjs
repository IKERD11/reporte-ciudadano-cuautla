// Solo fixture aislado: no usa ni modifica cuentas reales.
import {randomBytes} from 'node:crypto';
import {mkdirSync,writeFileSync} from 'node:fs';
const password=randomBytes(32).toString('hex');
mkdirSync('supabase/.tests-generated',{recursive:true});
writeFileSync('supabase/.tests-generated/report-credential.json',JSON.stringify({password}));
writeFileSync('supabase/.tests-generated/report-fixture.sql',`
begin;
insert into public.municipalities(id,name,state) values('e4000000-0000-0000-0000-000000000001','HTTP Report Test','Pruebas');
insert into public.settings(municipality_id,pilot_reports_enabled) values('e4000000-0000-0000-0000-000000000001',true);
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,confirmation_token,recovery_token,email_change_token_new,email_change,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
values('00000000-0000-0000-0000-000000000000','e4100000-0000-0000-0000-000000000001','authenticated','authenticated','phase4-e2e@example.test',extensions.crypt('${password}',extensions.gen_salt('bf')),now(),'','','','','{"provider":"email","providers":["email"]}','{}',now(),now());
insert into auth.identities(id,user_id,provider_id,identity_data,provider,created_at,updated_at) values(gen_random_uuid(),'e4100000-0000-0000-0000-000000000001','e4100000-0000-0000-0000-000000000001','{"sub":"e4100000-0000-0000-0000-000000000001","email":"phase4-e2e@example.test","email_verified":true}','email',now(),now());
insert into public.profiles(id,municipality_id,first_name,last_name) values('e4100000-0000-0000-0000-000000000001','e4000000-0000-0000-0000-000000000001','Prueba','HTTP');
insert into public.user_roles(user_id,municipality_id,role_id) select 'e4100000-0000-0000-0000-000000000001','e4000000-0000-0000-0000-000000000001',id from public.roles where code='CITIZEN';
insert into public.priorities(id,municipality_id,name,rank) values('e4300000-0000-0000-0000-000000000001','e4000000-0000-0000-0000-000000000001','Media',2);
insert into public.categories(id,municipality_id,name,default_priority_id,requires_photo) values('e4400000-0000-0000-0000-000000000001','e4000000-0000-0000-0000-000000000001','HTTP Prueba','e4300000-0000-0000-0000-000000000001',true);
commit;`);
console.log('Fixture aislado generado en directorio ignorado.');
