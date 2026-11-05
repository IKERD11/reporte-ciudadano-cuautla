export function searchUrl(input:unknown, endpoint:string):URL {
 if(typeof input!=='string')throw new Error('Escribe una dirección pública del incidente.');
 const query=input.trim().replace(/\s+/g,' ');
 if(query.length<5||query.length>200||/@|https?:|[\r\n]/i.test(input))throw new Error('Usa de 5 a 200 caracteres, sin correos, enlaces ni datos personales.');
 const url=new URL(endpoint);
 if(url.protocol!=='https:')throw new Error('Buscador no disponible.');
 const coordinates=/^(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)$/.exec(query);
 if(coordinates){
  const lat=Number(coordinates[1]),lon=Number(coordinates[2]);
  if(lat<18.6||lat>19||lon< -99.1||lon> -98.8)throw new Error('Selecciona un punto dentro de Cuautla.');
  if(!/\/search\/?$/.test(url.pathname))throw new Error('Consulta de ubicación no disponible.');
  url.pathname=url.pathname.replace(/\/search\/?$/,'/reverse');
  url.search=new URLSearchParams({lat:lat.toFixed(5),lon:lon.toFixed(5),format:'jsonv2',zoom:'18','accept-language':'es'}).toString();
  return url;
 }
 url.search=new URLSearchParams({q:query+', Cuautla, Morelos, México',format:'jsonv2',limit:'5',countrycodes:'mx',viewbox:'-99.1,19.0,-98.8,18.6',bounded:'1','accept-language':'es'}).toString();
 return url;
}
export function searchResults(value:unknown) {
 if(value && typeof value==='object' && 'display_name' in value)value=[value];
 if(!Array.isArray(value))throw new Error('El buscador no devolvió una respuesta válida.');
 return value.slice(0,5).flatMap(item=>{
  const lat=Number(item?.lat),lon=Number(item?.lon);
  if(!Number.isFinite(lat)||!Number.isFinite(lon)||lat<18.6||lat>19||lon< -99.1||lon> -98.8||typeof item?.display_name!=='string')return [];
  return [{latitude:lat,longitude:lon,address:item.display_name.slice(0,500)}];
 });
}
