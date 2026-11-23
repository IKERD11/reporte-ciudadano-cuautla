// Explicit write test against the pilot; touches only a new labeled test report.
import {readFileSync, writeFileSync, mkdirSync} from 'node:fs';
import {randomUUID} from 'node:crypto';
import assert from 'node:assert/strict';

assert.ok(process.argv.includes('--write-test'), 'Requiere --write-test: crea un reporte sintético para verificar la conexión.');
const config = JSON.parse(readFileSync('apps/mobile/config/pilot.json','utf8').replace(/^\uFEFF/,''));
const accounts = JSON.parse(readFileSync('tmp/admin-test-accounts/credentials.json','utf8'));
const url = config.SUPABASE_URL;
const key = config.SUPABASE_PUBLISHABLE_KEY;
const origin = 'https://ikerd11.github.io';
const sessions = [];
async function request(path, body, token) {
  const response = await fetch(`${url}${path}`, {
    method:'POST', headers:{apikey:key,'Content-Type':'application/json',Origin:origin,
      ...(token ? {Authorization:`Bearer ${token}`} : {})}, body:JSON.stringify(body),
  });
  const data = await response.json();
  assert.equal(response.status,200, `${path}: ${response.status} ${data.error ?? data.message ?? ''}`);
  return data;
}
try {
  for (const account of accounts.slice(0,2)) {
    sessions.push(await request('/auth/v1/token?grant_type=password', {email:account.email,password:account.password}));
  }
  const [owner, admin] = sessions.map(s=>s.access_token);
  const app = (action, values={}) => request('/functions/v1/report-pilot',{action,...values},owner);
  const dashboard = (action,data={}) => request('/rest/v1/rpc/admin_pilot',{p_action:action,p_data:data},admin);
  const notifications = action => request('/rest/v1/rpc/citizen_notifications',{p_action:action},owner);
  const preflight = await fetch(`${url}/functions/v1/report-pilot`, {
    method:'OPTIONS',headers:{Origin:origin,'Access-Control-Request-Method':'POST','Access-Control-Request-Headers':'authorization,apikey,content-type'},
  });
  assert.equal(preflight.status,204);
  assert.equal(preflight.headers.get('access-control-allow-origin'),origin);
  const context = await app('context');
  assert.equal(context.enabled,true);
  const category = context.categories.find(c=>c.name==='Otro'&&!c.requires_photo);
  assert.ok(category,'Categoría Otro sin foto requerida no disponible');
  const requestKey = randomUUID();
  const payload = {category_id:category.id,description:`PRUEBA AUTOMÁTICA de conexión app-dashboard ${requestKey}`,
    latitude:18.812,longitude:-98.955,address:'Ubicación sintética de integración, Cuautla',consent:true,additional_data:{}};
  const created = await app('submit',{request_key:requestKey,payload,photos:[]});
  assert.equal(created.committed,true);
  mkdirSync('tmp',{recursive:true});
  writeFileSync('tmp/dashboard-app-http-result.json',JSON.stringify({report_id:created.id,request_key:requestKey,owner_id:sessions[0].user.id},null,2));
  const retry = await app('submit',{request_key:requestKey,payload,photos:[]});
  assert.equal(retry.id,created.id);
  const listing = await dashboard('list',{query:created.folio});
  assert.equal(listing.total,1);
  assert.equal(listing.reports[0].id,created.id);
  let detail = await dashboard('detail',{id:created.id});
  assert.equal(detail.description,payload.description);
  const summary = await dashboard('summary',{query:created.folio});
  assert.equal(summary.total,1);
  await dashboard('status',{id:created.id,version:detail.version,status:'EN_REVISION'});
  detail = await dashboard('detail',{id:created.id});
  await dashboard('status',{id:created.id,version:detail.version,status:'RECHAZADO'});
  const citizenDetail = await app('detail',{report_id:created.id});
  assert.equal(citizenDetail.status,'Rechazado');
  assert.equal(citizenDetail.timeline.length,3);
  const ownList = await app('list');
  assert.ok(ownList.reports.some(r=>r.id===created.id&&r.status_code==='RECHAZADO'));
  const events = await notifications('list');
  assert.equal(events.items.filter(n=>n.report_id===created.id).length,3);
  console.log('OK: CORS, envío por Edge Function, idempotencia, listado y métricas del dashboard, cambio de estado, detalle/listado de app y tres avisos reales.');
  console.log('Identificador del reporte sintético guardado en tmp/dashboard-app-http-result.json para limpieza controlada.');
} finally {
  for(const session of sessions) {
    const response = await fetch(`${url}/auth/v1/logout?scope=local`, {method:'POST',headers:{apikey:key,Authorization:`Bearer ${session.access_token}`}});
    assert.ok(response.ok,'No se pudo cerrar una sesión de prueba');
  }
}
