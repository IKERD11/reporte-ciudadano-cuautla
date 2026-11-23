import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {reportCoordinate,reportCategoryArtwork} from '../src/lib/map-data.ts';
test('maps real coordinates in longitude latitude order without inventing missing locations',()=>{
  assert.deepEqual(reportCoordinate({latitude:18.812,longitude:-98.955}),[-98.955,18.812]);
  assert.deepEqual(reportCoordinate({latitude:0,longitude:0}),[0,0]);
  for(const latitude of [null,undefined,NaN,Infinity,91,'18.812'])
    assert.equal(reportCoordinate({latitude,longitude:-98.955}),null);
  for(const longitude of [null,undefined,NaN,-Infinity,181,'-98.955'])
    assert.equal(reportCoordinate({latitude:18.812,longitude}),null);
});
test('markers use the app category artwork and consultation colors',()=>{
  for(const [category,icon,color] of [
    ['Robo / Asalto','robbery','#ff3d55'],['Accidente','car','#176bea'],
    ['Vandalismo','spray','#813de4'],['Violencia','users','#ff3d55'],
    ['Alumbrado público','bulb','#08b989'],['Baches','cone','#ff8c1a'],
    ['Deceso','mourning','#176bea'],['Maltrato animal','paw','#813de4'],
    ['Recolección de residuos','more','#176bea'],['<img src=x>','more','#176bea'],
  ]) assert.deepEqual(reportCategoryArtwork(category),{icon,color});
});
test('dashboard ships the exact original images used by the app',()=>{
  for(const file of ['robbery.webp','car.webp','spray.webp','users.webp','bulb.webp','cone.webp','mourning.png','paw.webp','more.webp']) {
    const dashboard=readFileSync(new URL(`../public/branding/report-markers/${file}`,import.meta.url));
    const app=readFileSync(new URL(`../../mobile/assets/renewal/icons/3d/${file}`,import.meta.url));
    assert.deepEqual(dashboard,app,`${file} must match the citizen app`);
  }
});
