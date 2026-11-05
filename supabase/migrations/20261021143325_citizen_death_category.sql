begin;
-- Add the new design category to the Cuautla test pilot without changing access.
insert into public.categories(municipality_id,name,description,default_priority_id,requires_photo,requires_location,sort_order,dynamic_form_schema)
select m.id,'Deceso','Categoría de PRUEBA PILOTO: sin atención municipal real.',p.id,false,true,17,
  '{"type":"object","properties":{},"additionalProperties":false}'::jsonb
from public.municipalities m
join public.settings s on s.municipality_id=m.id and s.pilot_reports_enabled
join public.priorities p on p.municipality_id=m.id and p.rank=2
where m.name='Cuautla' and m.state='Morelos'
on conflict (municipality_id,name) do nothing;
commit;
