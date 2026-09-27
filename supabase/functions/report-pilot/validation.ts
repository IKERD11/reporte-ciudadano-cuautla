import jpeg from 'npm:jpeg-js@0.4.4';
export class PilotError extends Error{constructor(message:string,public status=400){super(message);}}
export const uuid=(v:unknown)=>typeof v==='string'&&/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);
export async function normalizePhoto(value:unknown){
 if(typeof value!=='string'||value.length>940000)throw new PilotError('Cada foto debe ocupar menos de 700 KB.');
 try{
  const bytes=Uint8Array.from(atob(value),c=>c.charCodeAt(0));
  if(bytes.length>700000||bytes[0]!==255||bytes[1]!==216)throw new Error();
  const decoded=jpeg.decode(bytes,{useTArray:true,maxResolutionInMP:2,maxMemoryUsageInMB:32,tolerantDecoding:false});
  if(decoded.width<32||decoded.height<32||decoded.width>1600||decoded.height>1600)throw new Error();
  // Solo píxeles: descartar EXIF, GPS incrustado, comentarios y nombres originales.
  const clean=jpeg.encode({width:decoded.width,height:decoded.height,data:decoded.data},75).data;
  if(clean.length>700000)throw new Error();
  const out=new Uint8Array(clean);
  const sha256=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',out)),b=>b.toString(16).padStart(2,'0')).join('');
  return {bytes:out,sha256};
 }catch{throw new PilotError('Foto inválida. Usa una imagen JPEG de 32 a 1600 píxeles por lado.');}
}
export async function readBody(request:Request){
 if(!request.body)throw new PilotError('Solicitud vacía.');
 const reader=request.body.getReader();const chunks:Uint8Array[]=[];let size=0;
 try{for(;;){const {done,value}=await reader.read();if(done)break;size+=value.length;if(size>2900000){await reader.cancel();throw new PilotError('Solicitud demasiado grande.',413);}chunks.push(value);}}finally{reader.releaseLock();}
 const out=new Uint8Array(size);let offset=0;for(const chunk of chunks){out.set(chunk,offset);offset+=chunk.length;}
 try{return JSON.parse(new TextDecoder().decode(out));}catch{throw new PilotError('JSON inválido.');}
}
