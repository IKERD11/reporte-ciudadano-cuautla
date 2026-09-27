import jpeg from 'npm:jpeg-js@0.4.4';
import {normalizePhoto,readBody,uuid} from './validation.ts';
const assert=(ok:unknown)=>{if(!ok)throw new Error('Assertion failed');};
async function rejects(fn:()=>Promise<unknown>){let failed=false;try{await fn();}catch{failed=true;}assert(failed);}
Deno.test('JPEG válido se normaliza y elimina comentarios',async()=>{
 const input=jpeg.encode({width:64,height:64,data:new Uint8Array(64*64*4),comments:['EXIF-like private text']},80).data;
 const output=await normalizePhoto(btoa(String.fromCharCode(...input)));
 assert(output.sha256.length===64);assert(!new TextDecoder().decode(output.bytes).includes('private text'));
});
Deno.test('No acepta contenido falso, PNG ni fotos pequeñas',async()=>{
 await rejects(()=>normalizePhoto(btoa('fake jpeg')));
 await rejects(()=>normalizePhoto('iVBORw0KGgo='));
 const input=jpeg.encode({width:16,height:16,data:new Uint8Array(16*16*4)},80).data;
 await rejects(()=>normalizePhoto(btoa(String.fromCharCode(...input))));
});
Deno.test('Limita archivo y cuerpo HTTP',async()=>{
 await rejects(()=>normalizePhoto('a'.repeat(940001)));
 await rejects(()=>readBody(new Request('https://example.test',{method:'POST',body:'a'.repeat(2900001)})));
 await rejects(()=>readBody(new Request('https://example.test',{method:'POST',body:'bad json'})));
});
Deno.test('UUID estricto',()=>{assert(uuid('d4500000-0000-0000-0000-000000000001'));assert(!uuid('../secret'));});
