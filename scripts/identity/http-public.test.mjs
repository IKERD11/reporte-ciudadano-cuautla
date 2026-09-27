import assert from 'node:assert/strict';
const base='https://mnjphahyqmwrvlaephla.supabase.co/functions/v1';
for(const name of ['identity-pilot','identity-purge']) {
 const response=await fetch(`${base}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{"action":"context"}'});
 assert.equal(response.status,401,`${name}: debe exigir autenticación`);
 console.log(`OK: ${name} rechaza acceso anónimo.`);
}
const origin=await fetch(`${base}/identity-pilot`,{method:'OPTIONS',headers:{Origin:'https://untrusted.example'}});
assert.equal(origin.status,403);console.log('OK: origen ajeno rechazado.');
