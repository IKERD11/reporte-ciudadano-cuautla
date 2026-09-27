import {readFileSync,writeFileSync} from 'node:fs';
import assert from 'node:assert/strict';
const config=JSON.parse(readFileSync('apps/mobile/config/pilot.json','utf8').replace(/^\uFEFF/,''));
const credential=JSON.parse(readFileSync('supabase/.tests-generated/e2e-credential.json','utf8'));
const base=config.SUPABASE_URL;
const headers={apikey:config.SUPABASE_PUBLISHABLE_KEY,'Content-Type':'application/json'};
const anonymous=await fetch(`${base}/functions/v1/identity-pilot`,{method:'POST',headers,body:'{"action":"context"}'});
assert.equal(anonymous.status,401);
const login=await fetch(`${base}/auth/v1/token?grant_type=password`,{method:'POST',headers,body:JSON.stringify({email:'phase3-e2e@example.test',password:credential.password})});
const session=await login.json(); if(login.status!==200)throw new Error(`Login de prueba: ${login.status} ${session.error_code??session.code}`);
headers.Authorization=`Bearer ${session.access_token}`;
const call=async body=>{
 const response=await fetch(`${base}/functions/v1/identity-pilot`,{method:'POST',headers,body:JSON.stringify(body)});
 const data=await response.json();return {status:response.status,data};
};
try{
 const context=await call({action:'context'});assert.equal(context.status,200);assert.equal(context.data.real_capture_enabled,false);
 const begin=await call({action:'begin',consent:true,notice_version:'synthetic-v1',request_key:crypto.randomUUID()});assert.equal(begin.status,200);
 const id=begin.data.case.id;writeFileSync('supabase/.tests-generated/e2e-case.json',JSON.stringify({id}));
 const bad=await call({action:'upload',case_id:id,side:'front',image:'aW52YWxpZA=='});assert.equal(bad.status,400);
 for(const side of ['front','back']) {
  const response=await call({action:'upload',case_id:id,side,image:readFileSync(`apps/mobile/assets/identity/${side}.png`).toString('base64')});
  assert.equal(response.status,200,JSON.stringify(response.data));assert.equal(response.data.case[`${side}_uploaded`],true);
 }
 const submitted=await call({action:'submit',case_id:id});assert.equal(submitted.status,200);assert.equal(submitted.data.case.status,'UNDER_REVIEW');
 const read=await call({action:'read',case_id:id,side:'front'});assert.equal(read.status,403);
 const approve=await call({action:'approve_demo',case_id:id});assert.equal(approve.status,403);
 console.log('E2E OK: login real, modo sintético, archivo ajeno rechazado, dos uploads privados, envío a revisión, lectura y autoaprobación denegadas.');
}finally{
 await fetch(`${base}/auth/v1/logout?scope=global`,{method:'POST',headers});
 const revoked=await call({action:'context'});assert.ok([401,403].includes(revoked.status));
 console.log('E2E OK: sesión cerrada rechazada.');
}
