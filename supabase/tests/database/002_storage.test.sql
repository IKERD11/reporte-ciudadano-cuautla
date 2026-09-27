begin;
create extension if not exists pgtap with schema extensions;
-- Versiones alojadas recientes bloquean DELETE por trigger antes de evaluar RLS.
-- Aceptar rechazo o cero filas; nunca aceptar que se elimine evidencia.
create function pg_temp.deleted_evidence_count() returns integer
language plpgsql security invoker as $$
declare affected integer;
begin
  delete from storage.objects where bucket_id='report-evidence';
  get diagnostics affected = row_count;
  return affected;
exception when insufficient_privilege then return 0;
end;
$$;
select plan(10);
-- Fixtures de metadatos únicamente; se revierten al final, no hay bytes en Storage.
insert into public.report_images(municipality_id,report_id,storage_path,mime_type,size)
values ('10000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001/50000000-0000-0000-0000-000000000001/test.jpg','image/jpeg',100),
('10000000-0000-0000-0000-000000000002','50000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000002/50000000-0000-0000-0000-000000000003/test.jpg','image/jpeg',100);
insert into storage.objects(bucket_id,name)
select 'report-evidence',storage_path from public.report_images;
insert into storage.objects(bucket_id,name) values('identity-documents','test-private.jpg');
set local role authenticated;
select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000001',true);
select is((select count(*)::integer from storage.objects where bucket_id='report-evidence'),1,'Ciudadano lee evidencia propia');
select is((select count(*)::integer from storage.objects where bucket_id='identity-documents'),0,'INE no tiene lectura directa');
select throws_ok($$insert into storage.objects(bucket_id,name) values('report-evidence','forged.jpg')$$,'42501',null,'Upload directo rechazado');
select throws_ok($$insert into storage.objects(bucket_id,name) values('identity-documents','forged.jpg')$$,'42501',null,'Upload INE rechazado hasta flujo seguro');
with updated as (update storage.objects set name='changed.jpg' where bucket_id='report-evidence' returning id)
select is(count(*)::integer,0,'No modificar evidencia') from updated;
select is(pg_temp.deleted_evidence_count(),0,'No eliminar evidencia');
select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000004',true);
select is((select count(*)::integer from storage.objects where bucket_id='report-evidence'),1,'Operador solo ve evidencia autorizada');
select is((select count(*)::integer from storage.objects where bucket_id='identity-documents'),0,'Operador no ve INE');
select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000003',true);
select is((select count(*)::integer from storage.objects where bucket_id='report-evidence'),1,'Ciudadano de municipio B aislado');
set local role anon;
select is((select count(*)::integer from storage.objects where bucket_id in ('report-evidence','identity-documents')),0,'Anónimo no lee objetos privados');
select * from finish();
rollback;
