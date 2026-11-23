import {test} from 'node:test';
import assert from 'node:assert/strict';
import {pilotDepartments,suggestedDepartmentName,suggestedDepartmentId} from '../src/lib/department-routing.ts';
import {appCategoryNames} from '../src/lib/app-categories.ts';

test('each app category has one proposed department and all eight areas are used',()=>{
  assert.equal(pilotDepartments.length,8);
  assert.deepEqual(pilotDepartments.flatMap(area=>area.categories).sort(),[...appCategoryNames].sort());
  for(const area of pilotDepartments)for(const category of area.categories)
    assert.equal(suggestedDepartmentName(category),area.name);
});
test('suggestions use real active department IDs and never fabricate or activate destinations',()=>{
  assert.equal(suggestedDepartmentId('Robo / Asalto',[{id:'security',name:'Seguridad Pública'}]),'security');
  assert.equal(suggestedDepartmentId('Robo / Asalto',[{id:'security',name:'Seguridad Pública',is_active:false}]),'');
  assert.equal(suggestedDepartmentId('Deceso',[]),'');
  assert.equal(suggestedDepartmentName('Baches'),'Obras Públicas y Mantenimiento Vial');
  assert.equal(suggestedDepartmentName('Categoría futura'),'Atención Ciudadana');
});
