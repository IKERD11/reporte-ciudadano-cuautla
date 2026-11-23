const http=require('node:http');
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const root=path.resolve(__dirname,'..');
const web=path.join(root,'apps/admin/out');
const prefix='/reporte-ciudadano-dashboard/';
const server=http.createServer((req,res)=>{
  const pathname=decodeURIComponent(new URL(req.url,'http://localhost').pathname);
  if(!pathname.startsWith(prefix)){res.writeHead(404).end();return;}
  const file=path.resolve(web,pathname.slice(prefix.length)||'index.html');
  if(!file.startsWith(web+path.sep)){res.writeHead(403).end();return;}
  fs.readFile(file,(error,data)=>{
    if(error){res.writeHead(404).end();return;}
    res.setHeader('Content-Type',({'.html':'text/html','.js':'text/javascript','.mjs':'text/javascript','.css':'text/css','.png':'image/png','.woff2':'font/woff2'})[path.extname(file)]||'application/octet-stream');
    res.end(data);
  });
});
(async()=>{
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const browser=await chromium.launch({channel:'msedge',headless:true,args:['--enable-unsafe-swiftshader','--use-angle=swiftshader','--disable-gpu-sandbox']});
  const page=await browser.newPage({viewport:{width:1440,height:1000},reducedMotion:'reduce'});
  const errors=[];page.on('pageerror',error=>errors.push(error.message));
  let tiles=0,worker=false;
  page.on('response',response=>{
    if(response.ok()&&/tiles.openfreemap.org.*(?:pbf|mvt)/.test(response.url()))tiles++;
    if(response.ok()&&response.url().endsWith('/worker.mjs'))worker=true;
  });
  let session;
  try {
    const account=JSON.parse(fs.readFileSync(path.join(root,'tmp/admin-test-accounts/credentials.json'),'utf8'))[0];
    const config=JSON.parse(fs.readFileSync(path.join(root,'apps/mobile/config/pilot.json'),'utf8').replace(/^\uFEFF/,''));
    const response=await fetch(`${config.SUPABASE_URL}/auth/v1/token?grant_type=password`,{
      method:'POST',headers:{apikey:config.SUPABASE_PUBLISHABLE_KEY,'Content-Type':'application/json'},
      body:JSON.stringify({email:account.email,password:account.password}),
    });
    assert.ok(response.ok,'Test login failed');session=await response.json();
    await page.addInitScript(value=>localStorage.setItem('rc-admin-session',JSON.stringify(value)),session);
    await page.goto(`http://127.0.0.1:${server.address().port}${prefix}`,{waitUntil:'domcontentloaded'});
    const toggle=page.getByRole('button',{name:'Cambiar a mapa 2D',exact:true});
    await toggle.waitFor({state:'visible',timeout:60000});
    await page.waitForFunction(()=>!document.querySelector('.admin-map-tools button')?.disabled,{timeout:60000});
    assert.ok(worker,'Local map worker must load under base path');
    await page.waitForFunction(()=>document.querySelectorAll('.admin-report-pin').length>0,{timeout:30000});
    await page.waitForFunction(()=>[...document.querySelectorAll('.admin-report-pin img')].every(img=>img.complete&&img.naturalWidth>0),{timeout:30000});
    const markerStyle=await page.locator('.admin-report-pin').first().evaluate(button=>{
      const style=getComputedStyle(button),image=button.querySelector('img');
      return {width:style.width,height:style.height,radius:style.borderTopLeftRadius,border:style.borderTopWidth,
        imageWidth:getComputedStyle(image).width,source:image.getAttribute('src')};
    });
    assert.deepEqual([markerStyle.width,markerStyle.height,markerStyle.radius,markerStyle.border,markerStyle.imageWidth],['54px','54px','19px','3px','39px']);
    assert.ok(markerStyle.source.includes('/branding/report-markers/'));
    await page.waitForTimeout(2500);
    assert.ok(tiles>0,'Real vector tiles must load');
    assert.equal(await page.locator('.maplibregl-canvas').count(),1);
    await toggle.click();
    assert.equal(await page.getByRole('button',{name:'Cambiar a mapa 3D',exact:true}).getAttribute('aria-pressed'),'false');
    await page.getByRole('button',{name:'Cambiar a mapa 3D',exact:true}).click();
    await page.getByRole('button',{name:'Configuración',exact:true}).click();
    const wizard=fs.readFileSync(path.join(root,'apps/mobile/lib/features/reports/report_wizard.dart'),'utf8');
    const categoryNames=[...wizard.match(/static const choices = \[([\s\S]*?)\];/)[1].matchAll(/'([^']+)'/g)].map(match=>match[1]);
    assert.deepEqual(await page.locator('.config-row strong').allTextContents(),categoryNames);
    await page.waitForFunction(()=>[...document.querySelectorAll('.config-row img')].every(img=>img.complete&&img.naturalWidth>0));
    const artwork=await page.locator('.config-row img').evaluateAll(images=>images.map(img=>img.getAttribute('src').split('/').at(-1)));
    assert.deepEqual(artwork,['robbery.webp','car.webp','spray.webp','users.webp','bulb.webp','cone.webp','paw.webp','mourning.png','more.webp']);
    assert.equal(await page.locator('.config-row').getByText('Activa',{exact:true}).count(),9);
    assert.equal(await page.locator('.department-entry').count(),8);
    assert.equal(await page.locator('.category-department').count(),9);
    await page.locator('.config-row').first().locator('..').screenshot({path:path.join(root,'output/dashboard-categories.png')});
    await page.getByRole('button',{name:'Mapa',exact:true}).click();
    await page.waitForFunction(()=>document.querySelector('.admin-map-tools button')?.disabled===false,{timeout:60000});
    await page.getByRole('button',{name:'Acercar',exact:true}).click();
    await page.waitForTimeout(1000);
    const canvas=page.locator('.maplibregl-canvas');
    await page.getByRole('button',{name:'Actualizar datos',exact:true}).click();
    await page.waitForTimeout(1500);
    assert.equal(await canvas.count(),1,'Refresh must preserve a single map instance');
    await page.getByRole('button',{name:'Ver reportes',exact:true}).click();
    await page.waitForTimeout(1500);
    const output=path.join(root,'output/dashboard-map-3d.png');
    await page.screenshot({path:output,fullPage:true});
    await page.locator('.admin-report-pin').last().click({force:true});
    await page.getByRole('heading',{name:'Detalle de reporte',exact:true}).waitFor({timeout:30000});
    await page.locator('.department-suggestion').waitFor();
    assert.ok((await page.getByRole('combobox',{name:'Departamento',exact:true}).textContent()).trim()!=='Seleccionar departamento');
    await page.waitForFunction(()=>document.querySelector('.admin-map-tools button')?.disabled===false,{timeout:60000});
    assert.equal(await page.locator('.maplibregl-canvas').count(),1,'Detail map replaces overview cleanly');
    await page.getByRole('button',{name:'Acercar',exact:true}).click();
    await page.waitForTimeout(2500);
    await page.locator('.detail-map').screenshot({path:path.join(root,'output/dashboard-buildings-3d.png')});
    const fallback=await browser.newPage({viewport:{width:1280,height:900}});
    await fallback.addInitScript(value=>{
      localStorage.setItem('rc-admin-session',JSON.stringify(value));
      const original=HTMLCanvasElement.prototype.getContext;
      HTMLCanvasElement.prototype.getContext=function(type,...args){
        if(type==='webgl'||type==='webgl2'||type==='experimental-webgl')return null;
        return original.call(this,type,...args);
      };
    },session);
    await fallback.goto(`http://127.0.0.1:${server.address().port}${prefix}`);
    await fallback.getByRole('button',{name:'Ver mapa 2D',exact:true}).click({timeout:30000});
    await fallback.locator('.leaflet-container').waitFor();
    assert.ok(await fallback.locator('.leaflet-marker-icon').count()>0,'Fallback keeps real report markers');
    await fallback.waitForFunction(()=>[...document.querySelectorAll('.admin-report-pin img')].every(img=>img.complete&&img.naturalWidth>0),{timeout:30000});
    assert.equal(await fallback.locator('.admin-report-pin').first().evaluate(button=>getComputedStyle(button).width),'54px');
    await fallback.close();
    await page.getByRole('button',{name:'Cerrar sesión',exact:true}).first().click();
    await page.getByRole('button',{name:'Ingresar al panel',exact:true}).waitFor();
    assert.equal(await page.locator('.maplibregl-canvas').count(),0,'Logout cleans map resources');
    assert.deepEqual(errors,[]);
    console.log(`PASS: real map tiles (${tiles}), local worker, 2D/3D toggle, dashboard map, refresh, marker-to-detail, WebGL-free fallback and logout cleanup. Screenshot: ${output}`);
  } finally {
    if(session){
      const config=JSON.parse(fs.readFileSync(path.join(root,'apps/mobile/config/pilot.json'),'utf8').replace(/^\uFEFF/,''));
      await fetch(`${config.SUPABASE_URL}/auth/v1/logout?scope=local`,{method:'POST',headers:{apikey:config.SUPABASE_PUBLISHABLE_KEY,Authorization:`Bearer ${session.access_token}`}});
    }
    await browser.close();server.close();
  }
})().catch(error=>{console.error(error);process.exitCode=1;server.close();});
