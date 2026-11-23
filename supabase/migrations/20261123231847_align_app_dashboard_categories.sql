begin;
-- Match the citizen wizard without deleting categories or changing report IDs.
update public.categories c set name='Baches / Vía pública'
from public.municipalities m
where c.municipality_id=m.id and m.name='Cuautla' and m.state='Morelos'
 and c.name='Baches' and not exists(
  select 1 from public.categories other where other.municipality_id=m.id and other.name='Baches / Vía pública');

insert into public.categories(municipality_id,name,description,default_priority_id,
 requires_photo,requires_location,sort_order,dynamic_form_schema)
select m.id,'Deceso','Categoría de PRUEBA PILOTO: sin atención municipal real.',p.id,
 false,true,8,'{"type":"object","properties":{},"additionalProperties":false}'::jsonb
from public.municipalities m
join public.settings s on s.municipality_id=m.id and s.pilot_reports_enabled
join public.priorities p on p.municipality_id=m.id and p.rank=2 and p.is_active
where m.name='Cuautla' and m.state='Morelos'
on conflict(municipality_id,name) do nothing;

update public.categories c set sort_order=choices.position
from public.municipalities m,
(values ('Robo / Asalto',1),('Accidente',2),('Vandalismo',3),('Violencia',4),
 ('Alumbrado público',5),('Baches / Vía pública',6),('Maltrato animal',7),('Deceso',8),('Otro',9)) choices(name,position)
where c.municipality_id=m.id and m.name='Cuautla' and m.state='Morelos' and c.name=choices.name;

-- Preserve the old category and any linked history, but stop offering it for new reports.
update public.categories c set is_active=false,is_public=false
from public.municipalities m
where c.municipality_id=m.id and m.name='Cuautla' and m.state='Morelos' and c.name='Recolección de residuos';
commit;
