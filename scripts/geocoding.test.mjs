import {test} from 'node:test';
import assert from 'node:assert/strict';
import {searchUrl,searchResults} from '../supabase/functions/report-pilot/geocoding.ts';
test('explicit searches remain bounded to Cuautla and Mexico',()=>{
 const u=searchUrl('  Calle   pública  ','https://nominatim.openstreetmap.org/search');
 assert.equal(u.searchParams.get('q'),'Calle pública, Cuautla, Morelos, México');
 assert.equal(u.searchParams.get('bounded'),'1');assert.equal(u.searchParams.get('countrycodes'),'mx');assert.equal(u.searchParams.get('limit'),'5');
});
test('rejects blank, oversized and accidentally pasted private contact fields',()=>{
 for(const v of ['',null,'x'.repeat(201),'persona@example.com','https://ejemplo.com','calle\nnombre'])assert.throws(()=>searchUrl(v,'https://nominatim.openstreetmap.org/search'));
});
test('provider coordinates are validated and out-of-area results dropped',()=>{
 assert.deepEqual(searchResults([{lat:'18.81',lon:'-98.95',display_name:'Centro'},{lat:'NaN',lon:'-98.95',display_name:'bad'},{lat:'19.5',lon:'-99.3',display_name:'outside'}]),[{latitude:18.81,longitude:-98.95,address:'Centro'}]);
 assert.throws(()=>searchResults({error:'down'}));assert.deepEqual(searchResults([]),[]);
});

test('selected map points use reverse lookup bounded to pilot area',()=>{
 const u=searchUrl('18.81260, -98.95480','https://nominatim.openstreetmap.org/search');
 assert.equal(u.pathname,'/reverse');assert.equal(u.searchParams.get('lat'),'18.81260');
 assert.equal(u.searchParams.get('lon'),'-98.95480');assert.equal(u.searchParams.has('q'),false);
 assert.throws(()=>searchUrl('20.5, -100.0','https://nominatim.openstreetmap.org/search'));
 assert.deepEqual(searchResults({lat:'18.8126',lon:'-98.9548',display_name:'Calle del punto, Cuautla'}),[{latitude:18.8126,longitude:-98.9548,address:'Calle del punto, Cuautla'}]);
});
