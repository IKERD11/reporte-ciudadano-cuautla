import { createClient } from 'npm:@supabase/supabase-js@2.57.4';
const admin=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false,autoRefreshToken:false}});
Deno.serve(async request=>{
  const headers={'Content-Type':'application/json','Cache-Control':'no-store'};
  const token=(request.headers.get('authorization')??'').replace(/^Bearer /,'');
  if(!/^[a-f0-9]{64}$/.test(token)) return new Response('{"error":"Unauthorized"}',{status:401,headers});
  if(request.method!=='POST')return new Response(null,{status:405,headers});
  const {data:cases,error}=await admin.rpc('identity_purge_authorized',{p_token:token});
  if(error)return new Response('{"error":"Purge unavailable"}',{status:error.code==='42501'?401:503,headers});
  let removed=0,failed=0;
  for(const item of cases){
    const paths=item.paths??[];
    if(paths.length){
      const {error:storageError}=await admin.storage.from('identity-documents').remove(paths);
      if(storageError){failed++;continue;}
    }
    const {error:finishError}=await admin.rpc('identity_purge_authorized',{p_token:token,p_case:item.id});
    if(finishError)failed++;else removed++;
  }
  const {data:uploads,error:uploadError}=await admin.rpc('report_upload_purge',{p_token:token});
  let uploadsRemoved=0;
  if(uploadError)failed++;
  else for(const item of uploads){
    if(item.paths?.length){
      const {error}=await admin.storage.from('report-evidence').remove(item.paths);
      if(error){failed++;continue;}
    }
    const {error}=await admin.rpc('report_upload_purge',{p_token:token,p_case:item.id});
    if(error)failed++;else uploadsRemoved++;
  }
  return new Response(JSON.stringify({removed,uploadsRemoved,failed}),{status:failed?503:200,headers});
});
