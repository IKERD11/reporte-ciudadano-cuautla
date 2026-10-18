import { createClient } from 'npm:@supabase/supabase-js@2.57.4';
import { PilotError, uuid, validateSynthetic, readLimitedBody, DisabledOcrProvider, ManualPilotProvider } from './core.mjs';

const url = Deno.env.get('SUPABASE_URL')!;
const secret = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const admin = createClient(url, secret, { auth: { persistSession: false, autoRefreshToken: false } });
const origins = new Set(['http://localhost:3000', 'http://127.0.0.1:3000', 'https://ikerd11.github.io']);
const actions = new Set(['context','begin','upload','submit','read','approve_demo','reject']);
Deno.serve(async (request) => {
  const origin = request.headers.get('origin');
  const headers: Record<string,string> = { 'Content-Type':'application/json', 'Cache-Control':'no-store', 'Vary':'Origin' };
  if (origin && origins.has(origin)) headers['Access-Control-Allow-Origin'] = origin;
  headers['Access-Control-Allow-Headers'] = 'authorization, apikey, content-type, x-client-info';
  headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS';
  const reply = (body: unknown, status=200) => new Response(JSON.stringify(body), {status,headers});
  if (origin && !origins.has(origin)) return reply({error:'Origen no permitido.'},403);
  if (request.method==='OPTIONS') return new Response(null,{status:204,headers});
  if (request.method!=='POST') return reply({error:'Método no permitido.'},405);
  try {
    const authorization=request.headers.get('authorization') ?? '';
    if (!authorization.startsWith('Bearer ')) throw new PilotError('Inicia sesión.',401);
    const token=authorization.slice(7);
    const {data:auth,error:authError}=await admin.auth.getUser(token);
    if(authError || !auth.user) throw new PilotError('Sesión inválida.',401);
    // Solo se lee session_id después de verificar criptográficamente el token con Auth.
    let session: string;
    try {session=JSON.parse(atob(token.split('.')[1].replace(/-/g,'+').replace(/_/g,'/'))).session_id;}
    catch {throw new PilotError('Sesión inválida.',401);}
    if(!uuid(session)) throw new PilotError('Sesión inválida.',401);
    const body=await readLimitedBody(request);
    if(!body || !actions.has(body.action)) throw new PilotError('Acción no permitida.');
    if(body.case_id!=null && !uuid(body.case_id)) throw new PilotError('Solicitud inválida.');
    if(body.action==='begin' && (!uuid(body.request_key) || body.consent!==true || body.notice_version!=='synthetic-v1')) throw new PilotError('Acepta el consentimiento de pruebas.');
    const rpc=async(action:string) => {
      const {data,error}=await admin.rpc('identity_pilot_service',{
        p_actor:auth.user!.id,p_session:session,p_action:action,p_case:body.case_id ?? null,
        p_key:body.request_key ?? null,p_side:body.side ?? null,p_version:body.notice_version ?? null,
      });
      if(error) throw new PilotError(error.code==='42501'?'Acceso no autorizado o solicitud vencida.':error.code==='54000'?'Límite diario del piloto alcanzado.':'No se pudo completar la operación.',error.code==='42501'?403:error.code==='54000'?429:400);
      return data;
    };
    if(body.action==='upload') {
      if(typeof body.image!=='string' || body.image.length>40000) throw new PilotError('Muestra inválida.');
      let bytes: Uint8Array;
      try {bytes=Uint8Array.from(atob(body.image), c=>c.charCodeAt(0));} catch {throw new PilotError('Muestra inválida.');}
      await validateSynthetic(body.side,bytes);
      const reservation=await rpc('reserve');
      if(!reservation.uploaded) {
        const {error}=await admin.storage.from('identity-documents').upload(reservation.path,bytes,{contentType:'image/png',upsert:false,cacheControl:'0'});
        // Un reintento tras una respuesta perdida puede encontrar el mismo archivo inmutable.
        if(error && !['409','Duplicate','409 Conflict'].includes(String('statusCode' in error ? error.statusCode : '')) && !/already exists/i.test(error.message)) throw new PilotError('No se pudo cargar la muestra.',503);
      }
      return reply(await rpc('uploaded'));
    }
    if(body.action==='submit') {
      await new DisabledOcrProvider().extract([]);
      await new ManualPilotProvider().evaluate({synthetic:true});
    }
    if(body.action==='read') {
      const document=await rpc('read');
      const {data,error}=await admin.storage.from('identity-documents').createSignedUrl(document.path,60);
      if(error) throw new PilotError('Documento no disponible.',404);
      return reply({url:data.signedUrl,expires_in:60});
    }
    return reply(await rpc(body.action));
  } catch(error) {
    // Nunca registrar JWT, imágenes, URLs firmadas o datos personales.
    return reply({error:error instanceof PilotError?error.message:'Servicio no disponible.'},error instanceof PilotError?error.status:503);
  }
});

