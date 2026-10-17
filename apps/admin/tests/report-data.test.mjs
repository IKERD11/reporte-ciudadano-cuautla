import {test} from 'node:test';
import assert from 'node:assert/strict';
import {municipalDate, summarizeReports, reportsCsv} from '../src/lib/report-data.ts';

test('Cuautla calendar starts at 06 UTC, including an inclusive end date', () => {
  const start=Date.parse(municipalDate('2026-10-08'));
  assert.equal(new Date(start).toISOString(),'2026-10-08T06:00:00.000Z');
  assert.equal(Date.parse('2026-10-09T05:59:59.999Z')<start+86400000,true);
  assert.equal(Date.parse('2026-10-09T06:00:00Z')<start+86400000,false);
  assert.equal(municipalDate(''),'');
});
test('summary handles no rows, terminal and unlocated reports', () => {
  assert.equal(summarizeReports([]).total,0);
  const rows=['RECIBIDO','EN_ATENCION','CERRADO','RECHAZADO'].map(status_code=>({status_code,status:status_code,category:'Servicios',latitude:null}));
  const summary=summarizeReports(rows);
  assert.deepEqual([summary.total,summary.pending,summary.progress,summary.resolved],[4,1,1,1]);
  assert.equal(summary.categories[0].count,4);
  assert.equal(summary.resolution_days,null);
});
test('CSV neutralizes formulas and escapes quotes, commas and nulls', () => {
  const csv=reportsCsv([{folio:'REP-1',description:' =HYPERLINK("x")',address:null,category:'A,B',status:'Recibido'}]);
  assert.ok(csv.includes('"\' =HYPERLINK(""x"")"'));
  assert.ok(csv.includes('"A,B"'));
  assert.ok(csv.startsWith('\uFEFF'));
});
