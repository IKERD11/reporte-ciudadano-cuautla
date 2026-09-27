begin;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values
('identity-documents','identity-documents',false,10485760,array['image/jpeg','image/png']),
('report-evidence','report-evidence',false,10485760,array['image/jpeg','image/png','image/webp']);

-- No upload policy hasta validar documentos/evidencia desde servidor en fases 3 y 4.
-- Leer evidencia exige coincidencia exacta con metadatos autorizados, no solo un prefijo manipulable.
create policy evidence_read on storage.objects for select to authenticated
using (bucket_id = 'report-evidence' and exists (
  select 1 from public.report_images i where i.storage_path = name and private.can_read_report(i.report_id)
));
-- INE sin SELECT directo, incluso para revisores: la futura función comprobará
-- identity.read, auditará la consulta y emitirá URL de duración corta.
commit;
