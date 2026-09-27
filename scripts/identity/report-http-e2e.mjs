import {readFileSync,writeFileSync} from 'node:fs';
import assert from 'node:assert/strict';
const config=JSON.parse(readFileSync('apps/mobile/config/pilot.json','utf8').replace(/^\uFEFF/,''));
const {password}=JSON.parse(readFileSync('supabase/.tests-generated/report-credential.json','utf8'));
const base=config.SUPABASE_URL,headers={apikey:config.SUPABASE_PUBLISHABLE_KEY,'Content-Type':'application/json'};
const call=async body=>{const r=await fetch(`${base}/functions/v1/report-pilot`,{method:'POST',headers,body:JSON.stringify(body)});return {status:r.status,data:await r.json()};};
assert.equal((await call({action:'context'})).status,401);
const login=await fetch(`${base}/auth/v1/token?grant_type=password`,{method:'POST',headers,body:JSON.stringify({email:'phase4-e2e@example.test',password})});
const session=await login.json();assert.equal(login.status,200,session.error_code??'login');headers.Authorization=`Bearer ${session.access_token}`;
try{
 const ctx=await call({action:'context'});assert.equal(ctx.status,200);assert.equal(ctx.data.categories.length,1);
 const body={action:'submit',request_key:crypto.randomUUID(),payload:{category_id:'e4400000-0000-0000-0000-000000000001',description:'Reporte HTTP exclusivamente de prueba',latitude:18.812,longitude:-98.955,additional_data:{},consent:true},photos:[readFileSync('supabase/.tests-generated/report-photo.jpg').toString('base64')]};
 const bad=await call({...body,photos:['YmFk']});assert.equal(bad.status,400);
 const first=await call(body);assert.equal(first.status,200,JSON.stringify(first.data));
 const again=await call(body);assert.equal(again.status,200,JSON.stringify(again.data));assert.equal(again.data.id,first.data.id);
 const list=await call({action:'list'});assert.equal(list.status,200,JSON.stringify(list.data));assert.equal(list.data.reports.length,1);
 const detail=await call({action:'detail',report_id:first.data.id});assert.equal(detail.status,200,JSON.stringify(detail.data));assert.equal(detail.data.images.length,1);assert.equal(detail.data.is_pilot,true);assert.equal(detail.data.status,'Recibido');
 const image=await call({action:'image',report_id:first.data.id,image_id:detail.data.images[0].id});assert.equal(image.status,200);
 const photo=await fetch(image.data.url);assert.equal(photo.status,200);assert.equal(photo.headers.get('content-type'),'image/jpeg');
 const forged=await call({action:'detail',report_id:crypto.randomUUID()});assert.equal(forged.status,403);
 writeFileSync('supabase/.tests-generated/report-result.json',JSON.stringify({id:first.data.id,folio:first.data.folio,passed:true}));
 console.log('E2E OK: login, categorías, rechazo de archivo falso, foto privada, folio, reintento sin duplicados, lista, detalle y URL firmada.');
}finally{
 await fetch(`${base}/auth/v1/logout?scope=global`,{method:'POST',headers});
 const revoked=await call({action:'context'});assert.ok([401,403].includes(revoked.status));console.log('E2E OK: sesión revocada rechazada.');
}
