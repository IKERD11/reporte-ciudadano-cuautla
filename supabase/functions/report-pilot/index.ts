import { createClient } from 'npm:@supabase/supabase-js@2.57.4';
import {normalizePhoto, readBody, PilotError, uuid} from './validation.ts';
import {searchUrl,searchResults} from './geocoding.ts';
const admin=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false,autoRefreshToken:false}});
const origins=new Set(['http://localhost:3000','http://127.0.0.1:3000','https://ikerd11.github.io']);
Deno.serve(async request=>{
 const origin=request.headers.get('origin');
 const headers:Record<string,string>={'Content-Type':'application/json','Cache-Control':'no-store','Vary':'Origin','Access-Control-Allow-Headers':'authorization,apikey,content-type,x-client-info','Access-Control-Allow-Methods':'POST,OPTIONS'};
 if(origin&&origins.has(origin))headers['Access-Control-Allow-Origin']=origin;
 const reply=(data:unknown,status=200)=>new Response(JSON.stringify(data),{status,headers});
 if(origin&&!origins.has(origin))return reply({error:'Origen no permitido'},403);
 if(request.method==='OPTIONS')return new Response(null,{status:204,headers});
 if(request.method!=='POST')return reply({error:'Método no permitido'},405);
 try{
  const token=(request.headers.get('authorization')??'').replace(/^Bearer /,'');
  const {data:auth,error}=await admin.auth.getUser(token);
  if(error||!auth.user)throw new PilotError('Inicia sesión.',401);
  let session:string;
  try{session=JSON.parse(atob(token.split('.')[1].replace(/-/g,'+').replace(/_/g,'/'))).session_id;}catch{throw new PilotError('Sesión inválida.',401);}
  if(!uuid(session))throw new PilotError('Sesión inválida.',401);
  const b=await readBody(request);
  if(!['context','submit','list','detail','image','geocode'].includes(b.action))throw new PilotError('Acción inválida.');
  if(b.report_id!=null&&!uuid(b.report_id))throw new PilotError('Reporte inválido.');
  const rpc=async(action:string,payload:unknown={})=>{
   const {data,error}=await admin.rpc('report_pilot_service',{p_actor:auth.user!.id,p_session:session,p_action:action,p_key:b.request_key??null,p_payload:payload,p_report:b.report_id??null,p_offset:b.offset??0,p_filter:b.filter??'ALL'});
   if(error)throw new PilotError(error.code==='42501'?'Acceso no autorizado o solicitud vencida.':error.code==='54000'?'Alcanzaste cinco reportes de prueba en 24 horas.':error.code==='22023'?error.message:'Revisa los datos del reporte.',error.code==='42501'?403:error.code==='54000'?429:400);
   return data;
  };
  if(b.action==='geocode'){
   if(Deno.env.get('GEOCODING_DISABLED')==='true')throw new PilotError('Búsqueda temporalmente deshabilitada. Usa el mapa.',503);
   const context=await rpc('context');if(!context.enabled)throw new PilotError('Piloto no habilitado.',403);
   let url:URL;try{url=searchUrl(b.query,Deno.env.get('GEOCODING_URL')??'https://nominatim.openstreetmap.org/search');}catch(e){throw new PilotError((e as Error).message);}
   const key=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(url.toString().toLowerCase()))),v=>v.toString(16).padStart(2,'0')).join('');
   const params={p_actor:auth.user.id,p_session:session,p_key:key};
   const {data:reservation,error}=await admin.rpc('pilot_geocode_service',{...params,p_action:'reserve'});
   if(error)throw new PilotError(error.code==='54000'?error.message:'Búsqueda no disponible.',error.code==='54000'?429:403);
   if(reservation.results)return reply({results:reservation.results,attribution:'© OpenStreetMap contributors'});
   let results:ReturnType<typeof searchResults>|null=null;
   try{
    const response=await fetch(url,{headers:{'User-Agent':'ReporteCiudadanoCuautla-Piloto/1.0 (+https://ikerd11.github.io/reporte-ciudadano-diagramas/)','Accept':'application/json'},signal:AbortSignal.timeout(8000),redirect:'error'});
    if(!response.ok)throw new Error('Buscador temporalmente no disponible. Usa el mapa o intenta más tarde.');
    results=searchResults(await response.json());
   }catch{throw new PilotError('No se pudo buscar la dirección. Puedes marcar el lugar en el mapa.',503);}
   finally{await admin.rpc('pilot_geocode_service',{...params,p_action:'finish',p_ticket:reservation.ticket,p_results:results});}
   return reply({results,attribution:'© OpenStreetMap contributors'});
  }
  if(b.action==='submit'){
   if(!uuid(b.request_key)||!b.payload||b.payload.consent!==true||!Array.isArray(b.photos)||b.photos.length>3)throw new PilotError('Solicitud inválida.');
   // Revisión de sesión/municipio antes de gastar CPU en fotografías.
   const context=await rpc('context'); if(!context.enabled)throw new PilotError('Piloto no habilitado.',403);
   const photos=[];
   for(const photo of b.photos)photos.push(await normalizePhoto(photo));
   const payload={...b.payload,images:photos.map(p=>({size:p.bytes.length,sha256:p.sha256}))};
   const ticket=await rpc('reserve',payload);
   if(ticket.committed)return reply(ticket);
   for(let i=0;i<photos.length;i++){
    const {error}=await admin.storage.from('report-evidence').upload(ticket.paths[i],photos[i].bytes,{contentType:'image/jpeg',upsert:false,cacheControl:'3600'});
    if(error&&!/already exists/i.test(error.message)&&String('statusCode' in error?error.statusCode:'')!=='409')throw new PilotError('La carga no terminó. Reintenta sin cambiar los datos.',503);
   }
   return reply(await rpc('commit',payload));
  }
  if(b.action==='image'){
   if(!uuid(b.image_id))throw new PilotError('Imagen inválida.');
   const item=await rpc('image',{image_id:b.image_id});
   const {data,error}=await admin.storage.from('report-evidence').createSignedUrl(item.path,60);
   if(error)throw new PilotError('Imagen no disponible.',404);
   return reply({url:data.signedUrl});
  }
  return reply(await rpc(b.action));
 }catch(e){return reply({error:e instanceof PilotError?e.message:'Servicio no disponible. Reintenta.'},e instanceof PilotError?e.status:503);}
});
