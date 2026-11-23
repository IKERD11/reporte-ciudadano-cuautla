import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {appCategoryNames,appCategories} from '../src/lib/app-categories.ts';

test('dashboard labels and order match the actual citizen report wizard',()=>{
  const dart=readFileSync(new URL('../../mobile/lib/features/reports/report_wizard.dart',import.meta.url),'utf8');
  const labels=[...dart.match(/static const choices = \[([\s\S]*?)\];/)[1].matchAll(/'([^']+)'/g)].map(match=>match[1]);
  assert.deepEqual([...appCategoryNames],labels);
});
test('preserves database IDs and activity while aligning old names and omitting legacy categories',()=>{
  const rows=appCategoryNames.map((name,index)=>({id:`real-${index}`,name,is_active:index!==7})).reverse();
  rows.find(row=>row.id==='real-5').name='Baches';
  rows.push({id:'legacy',name:'Recolección de residuos'});
  const categories=appCategories(rows);
  assert.deepEqual(categories.map(row=>row.name),[...appCategoryNames]);
  assert.equal(categories[5].id,'real-5');
  assert.equal(categories[7].is_active,false);
  assert.equal(appCategories([]).length,0);
});
