import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {validateSynthetic,readLimitedBody,DisabledOcrProvider,ManualPilotProvider} from '../../supabase/functions/identity-pilot/core.mjs';
for (const side of ['front','back']) test(`acepta muestra ${side} y rechaza cualquier modificación`,async()=>{
 const bytes=new Uint8Array(await readFile(`apps/mobile/assets/identity/${side}.png`));
 assert.equal((await validateSynthetic(side,bytes)).width,960);
 bytes[100]^=1;await assert.rejects(validateSynthetic(side,bytes));
});
test('rechaza lado arbitrario e imagen vacía',async()=>{
 await assert.rejects(validateSynthetic('../other',new Uint8Array()));
 await assert.rejects(validateSynthetic('front',new Uint8Array()));
});
test('no confunde OCR con verificación',async()=>{
 assert.deepEqual(await new DisabledOcrProvider().extract([]),{status:'disabled',fields:{}});
 const provider=new ManualPilotProvider();
 assert.equal((await provider.evaluate({synthetic:true})).verified,false);
 await assert.rejects(provider.evaluate({synthetic:false}));
});
test('limita cuerpo real incluso sin Content-Length',async()=>{
 const request=new Request('https://example.test',{method:'POST',body:'x'.repeat(45001)});
 await assert.rejects(readLimitedBody(request),{status:413});
});
test('rechaza JSON inválido',async()=>{
 await assert.rejects(readLimitedBody(new Request('https://example.test',{method:'POST',body:'oops'})),{status:400});
});
