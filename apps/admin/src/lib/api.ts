import { createClient } from '@supabase/supabase-js';
export const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, {auth:{storageKey:'rc-admin-session',persistSession:true,autoRefreshToken:true,detectSessionInUrl:false}});
export async function call<T>(action:string,data:object={}):Promise<T> {
 const {data:result,error}=await supabase.rpc('admin_pilot',{p_action:action,p_data:data});
 if(error) throw new Error(error.code==='42501'?'Tu sesión no tiene acceso a esta operación.':error.message);
 return result as T;
}
export type Catalog = {id:string;name:string;code?:string;description?:string;is_active?:boolean};
export type Team = {id:string;name:string;roles:string[];cases:number};
export type Context = {name:string;municipality:string;roles:string[];permissions:string[];categories:Catalog[];statuses:Catalog[];priorities:Catalog[];departments:Catalog[];team:Team[]};
export type Report = {id:string;folio:string;description:string;address:string|null;created_at:string;category:string;category_id:string;status:string;status_code:string;priority:string;assigned_name:string|null;latitude:number|null;longitude:number|null};
export type Summary = {total:number;pending:number;progress:number;resolved:number;resolution_days:number|null;categories:{name:string;count:number}[];statuses:{name:string;count:number}[];weeks:{week:string;count:number}[]};
export type Detail = {id:string;folio:string;description:string;address:string|null;created_at:string;version:number;status:string;category:string;priority_id:string;latitude:number|null;longitude:number|null;citizen:{name:string;phone:string|null};images:{id:string;path:string;url?:string}[];timeline:{status:string;created_at:string}[];assignment:{department_id:string;assigned_to:string|null}|null};
export const transitions:Record<string,string[]>={RECIBIDO:['EN_REVISION','RECHAZADO','DUPLICADO'],EN_REVISION:['VALIDADO','RECHAZADO','DUPLICADO'],VALIDADO:[],ASIGNADO:['EN_ATENCION'],EN_ATENCION:['RESUELTO'],RESUELTO:['CERRADO','EN_ATENCION']};
