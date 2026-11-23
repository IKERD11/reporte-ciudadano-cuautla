import {test} from 'node:test';
import assert from 'node:assert/strict';
import {reportCoordinate,reportMarkerColor} from '../src/lib/map-data.ts';
test('maps real coordinates in longitude latitude order without inventing missing locations',()=>{
  assert.deepEqual(reportCoordinate({latitude:18.812,longitude:-98.955}),[-98.955,18.812]);
  assert.deepEqual(reportCoordinate({latitude:0,longitude:0}),[0,0]);
  for(const latitude of [null,undefined,NaN,Infinity,91,'18.812'])
    assert.equal(reportCoordinate({latitude,longitude:-98.955}),null);
  for(const longitude of [null,undefined,NaN,-Infinity,181,'-98.955'])
    assert.equal(reportCoordinate({latitude:18.812,longitude}),null);
});
test('marker colors distinguish active, resolved and rejected reports',()=>{
  assert.notEqual(reportMarkerColor('EN_ATENCION'),reportMarkerColor('RECIBIDO'));
  assert.equal(reportMarkerColor('RESUELTO'),reportMarkerColor('CERRADO'));
  assert.notEqual(reportMarkerColor('RECHAZADO'),reportMarkerColor('RESUELTO'));
});
