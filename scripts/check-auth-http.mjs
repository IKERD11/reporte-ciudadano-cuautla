import {readFileSync} from 'node:fs';
import assert from 'node:assert/strict';
const config=JSON.parse(readFileSync('apps/mobile/config/pilot.json','utf8').replace(/^\uFEFF/,''));
const headers={apikey:config.SUPABASE_PUBLISHABLE_KEY,'Content-Type':'application/json'};
const settings=await fetch(`${config.SUPABASE_URL}/auth/v1/settings`,{headers});
assert.equal(settings.status,200);
const body=await settings.json();
assert.equal(body.mailer_autoconfirm,false);assert.equal(body.external.email,true);
console.log('OK: Auth habilitado, confirmación obligatoria.');
for(const [path,method,payload] of [
  ['/rest/v1/profiles?select=id','GET',undefined],
  ['/rest/v1/rpc/list_registration_municipalities','POST',{}],
  ['/rest/v1/rpc/complete_citizen_profile','POST',{p_municipality_id:'f6e37105-cb28-4d27-a3f5-b4e9ac38b67c',p_first_name:'No insertar',p_last_name:'Prueba anónima'}],
]) {
 const response=await fetch(`${config.SUPABASE_URL}${path}`,{method,headers,body:payload?JSON.stringify(payload):undefined});
 assert.ok([401,403].includes(response.status),`Acceso anónimo no rechazado: ${path} ${response.status}`);
 console.log(`OK: ${method} ${path.split('?')[0]} rechazado sin sesión (${response.status}).`);
}
