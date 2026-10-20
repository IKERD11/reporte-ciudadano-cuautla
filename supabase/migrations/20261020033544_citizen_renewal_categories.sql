begin;
-- Complete the approved Figma catalog in the existing Cuautla test pilot only.
-- Existing category IDs, evidence requirements and dynamic forms are preserved.
insert into public.categories(municipality_id,name,description,default_priority_id,requires_photo,requires_location,sort_order,dynamic_form_schema)
select m.id,v.name,'Categoría de PRUEBA PILOTO: sin atención municipal real.',p.id,false,true,v.ord,
  '{"type":"object","properties":{},"additionalProperties":false}'::jsonb
from public.municipalities m
join public.settings s on s.municipality_id=m.id and s.pilot_reports_enabled
join public.priorities p on p.municipality_id=m.id and p.rank=2
cross join (values ('Robo / Asalto',10),('Accidente',11),('Vandalismo',12),('Violencia',13),('Maltrato animal',16),('Otro',17)) v(name,ord)
where m.name='Cuautla' and m.state='Morelos'
on conflict (municipality_id,name) do nothing;
commit;
