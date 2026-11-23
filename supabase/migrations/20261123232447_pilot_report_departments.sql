begin;
-- Functional routing proposal for the pilot, not a certified municipal directory.
insert into public.departments(municipality_id,name)
select m.id,areas.name from public.municipalities m cross join (values
 ('Seguridad Pública'),('Tránsito Municipal'),('Atención a Víctimas y Violencia'),
 ('Alumbrado Público'),('Obras Públicas y Mantenimiento Vial'),
 ('Protección y Bienestar Animal'),('Protección Civil'),('Atención Ciudadana')
) areas(name)
where m.name='Cuautla' and m.state='Morelos' and m.is_active
on conflict(municipality_id,name) do nothing;
commit;
