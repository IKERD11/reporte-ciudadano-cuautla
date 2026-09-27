import http from 'node:http';
import {readFile,stat} from 'node:fs/promises';
import {resolve,extname,sep} from 'node:path';
const root=resolve('apps/mobile/build/web');
const mime={'.html':'text/html; charset=utf-8','.js':'application/javascript','.json':'application/json','.css':'text/css','.wasm':'application/wasm','.png':'image/png','.svg':'image/svg+xml','.woff2':'font/woff2','.ttf':'font/ttf'};
await stat(resolve(root,'index.html'));
http.createServer(async(req,res)=>{
 try {
  const pathname=decodeURIComponent(new URL(req.url,'http://localhost').pathname);
  const target=resolve(root,'.'+(pathname==='/'?'/index.html':pathname));
  if(!target.startsWith(root+sep)||!['GET','HEAD'].includes(req.method)){res.writeHead(403);res.end();return;}
  const data=await readFile(target);
  res.writeHead(200,{'Content-Type':mime[extname(target)]??'application/octet-stream','Cache-Control':'no-store','Referrer-Policy':'strict-origin-when-cross-origin','X-Content-Type-Options':'nosniff'});
  res.end(req.method==='HEAD'?undefined:data);
 } catch {res.writeHead(404);res.end('No encontrado');}
}).listen(3000,'127.0.0.1',()=>console.log('Piloto local: http://127.0.0.1:3000 (Ctrl+C para detener).'));
