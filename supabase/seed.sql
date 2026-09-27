-- SOLO desarrollo local. Identidades sintéticas sin contraseña: no pueden iniciar sesión.
-- La CLI ejecuta este archivo tras migrar al usar db reset --local.
begin;
insert into public.municipalities(id,name,state) values
('10000000-0000-0000-0000-000000000001','Municipio de desarrollo A','Pruebas'),
('10000000-0000-0000-0000-000000000002','Municipio de desarrollo B','Pruebas');

do $$
declare m uuid; u uuid; n integer; role_code text; p uuid; c uuid; d uuid; rep uuid;
begin
  for n in 1..8 loop
    u := ('20000000-0000-0000-0000-' || lpad(n::text,12,'0'))::uuid;
    m := case when n = 3 then '10000000-0000-0000-0000-000000000002'::uuid else '10000000-0000-0000-0000-000000000001'::uuid end;
    insert into auth.users(id,instance_id,aud,role,email,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
    values(u,'00000000-0000-0000-0000-000000000000','authenticated','authenticated','fixture-'||n||'@example.test',now(),'{"provider":"email","providers":["email"]}','{}',now(),now());
    insert into public.profiles(id,municipality_id,first_name,last_name)
    values(u,m,'Usuario de prueba '||n,'Desarrollo');
    role_code := case n when 4 then 'OPERATOR' when 5 then 'MUNICIPAL_ADMIN' when 6 then 'SUPERVISOR' when 7 then 'VIEWER' when 8 then 'SUPER_ADMIN' else 'CITIZEN' end;
    insert into public.user_roles(user_id,municipality_id,role_id)
    select u,case when n = 8 then null else m end,id from public.roles where code = role_code;
  end loop;
  for n in 1..2 loop
    m := ('10000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid;
    insert into public.priorities(municipality_id,name,rank)
    values(m,'BAJA',1),(m,'MEDIA',2),(m,'ALTA',3),(m,'CRÍTICA',4);
    select id into p from public.priorities where municipality_id = m and rank = 2;
    c := ('30000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid;
    insert into public.categories(id,municipality_id,name,default_priority_id) values(c,m,'Alumbrado',p);
    d := ('40000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid;
    insert into public.departments(id,municipality_id,name) values(d,m,'Servicios Públicos');
    insert into public.settings(municipality_id) values(m);
  end loop;
  for n in 1..3 loop
    m := case when n = 3 then '10000000-0000-0000-0000-000000000002'::uuid else '10000000-0000-0000-0000-000000000001'::uuid end;
    select id into p from public.priorities where municipality_id = m and rank = 2;
    select id into c from public.categories where municipality_id = m;
    u := ('20000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid;
    rep := ('50000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid;
    insert into public.reports(id,municipality_id,citizen_id,category_id,priority_id,status_id,description,location,idempotency_key)
    select rep,m,u,c,p,id,'Reporte sintético para pruebas de aislamiento',extensions.st_setsrid(extensions.st_makepoint(-99.13,19.43),4326)::extensions.geography,rep
    from public.report_statuses where code = 'RECIBIDO';
    insert into public.identity_verifications(municipality_id,user_id) values(m,u);
    insert into public.consents(municipality_id,user_id,consent_type,privacy_notice_version) values(m,u,'TEST_ONLY','dev-1');
  end loop;
end;
$$;
insert into public.report_assignments(municipality_id,report_id,department_id,assigned_to,assigned_by)
values('10000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000004','20000000-0000-0000-0000-000000000005');
insert into public.report_comments(municipality_id,report_id,body,is_internal)
values('10000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000001','Comentario visible al ciudadano',false),
('10000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000001','Nota interna de prueba',true);
commit;
