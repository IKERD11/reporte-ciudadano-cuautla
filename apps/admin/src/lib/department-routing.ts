import type {Catalog} from './api';

export const pilotDepartments=[
  {name:'Seguridad Pública',categories:['Robo / Asalto','Vandalismo']},
  {name:'Tránsito Municipal',categories:['Accidente']},
  {name:'Atención a Víctimas y Violencia',categories:['Violencia']},
  {name:'Alumbrado Público',categories:['Alumbrado público']},
  {name:'Obras Públicas y Mantenimiento Vial',categories:['Baches / Vía pública']},
  {name:'Protección y Bienestar Animal',categories:['Maltrato animal']},
  {name:'Protección Civil',categories:['Deceso']},
  {name:'Atención Ciudadana',categories:['Otro']},
];

export function suggestedDepartmentName(category:string) {
  const name=category==='Baches'?'Baches / Vía pública':category;
  return pilotDepartments.find(area=>area.categories.includes(name))?.name??'Atención Ciudadana';
}

export function suggestedDepartmentId(category:string,departments:Catalog[]) {
  const name=suggestedDepartmentName(category);
  return departments.find(area=>area.name===name&&area.is_active!==false)?.id??'';
}
