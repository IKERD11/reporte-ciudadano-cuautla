import type {Catalog} from './api';

// Same labels and order as ReportWizard.choices in the citizen app.
export const appCategoryNames=[
  'Robo / Asalto','Accidente','Vandalismo','Violencia','Alumbrado público',
  'Baches / Vía pública','Maltrato animal','Deceso','Otro',
] as const;

export function appCategories(categories:Catalog[]):Catalog[] {
  return appCategoryNames.flatMap(name=>{
    const category=categories.find(item=>item.name.toLowerCase()===name.toLowerCase()
      || (name==='Baches / Vía pública'&&item.name.toLowerCase()==='baches')
      || (name==='Otro'&&item.name.toLowerCase()==='otros'));
    return category?[{...category,name}]:[];
  });
}
