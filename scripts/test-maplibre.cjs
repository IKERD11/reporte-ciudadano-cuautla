// Browser regression tests for our MapLibre bridge. Fixtures never enter the app/repository.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const {createRequire} = require('node:module');
const runtimeRequire = process.env.CODEX_NODE_MODULES
  ? createRequire(path.join(process.env.CODEX_NODE_MODULES, '__maplibre_test__.cjs')) : require;
const {chromium} = runtimeRequire('playwright');
const root = path.resolve(__dirname, '..');
const web = path.join(root, 'apps/mobile/web');
const fixtureStyle = {version: 8, sources: {openmaptiles: {type: 'vector', tiles: ['https://tiles.openfreemap.org/test/{z}/{x}/{y}.pbf'], maxzoom: 14}},
  layers: [{id: 'background', type: 'background', paint: {'background-color': '#edf4f8'}}]};
const server = http.createServer((req, res) => {
  const pathname = new URL(req.url, 'http://localhost').pathname;
  if (pathname === '/') {
    res.setHeader('Content-Type', 'text/html');
    res.end('<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="stylesheet" href="vendor/maplibre-gl-4.7.1/maplibre-gl.css"><link rel="stylesheet" href="maps/citizen-map.css"><style>body{margin:0}#map{width:100%;height:600px}</style><div id="map"></div></html>');
    return;
  }
  const file = pathname.startsWith('/assets/assets/')
    ? path.join(root, 'apps/mobile', pathname.slice('/assets/'.length)) : path.join(web, pathname);
  if (!file.startsWith(web + path.sep) && !file.startsWith(path.join(root, 'apps/mobile/assets') + path.sep)) { res.writeHead(403).end(); return; }
  const contentType = {'.js': 'text/javascript', '.css': 'text/css', '.webp': 'image/webp', '.ttf': 'font/ttf'}[path.extname(file)] || 'application/octet-stream';
  fs.readFile(file, (error, data) => {
    if (error) { res.writeHead(404).end(); return; }
    res.setHeader('Content-Type', contentType); res.end(data);
  });
});
(async () => {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const base = `http://127.0.0.1:${server.address().port}/`;
  const browser = await chromium.launch({channel: 'msedge', headless: true,
    args: ['--enable-unsafe-swiftshader', '--use-angle=swiftshader', '--disable-gpu-sandbox']});
  try {
    const context = await browser.newContext({viewport: {width: 390, height: 844}, ignoreHTTPSErrors: true, hasTouch: true, isMobile: true});
    const page = await context.newPage();
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    await page.route('https://tiles.openfreemap.org/**', route => route.fulfill({status: 200,
      contentType: route.request().url().includes('/styles/') ? 'application/json' : 'application/x-protobuf',
      body: route.request().url().includes('/styles/') ? JSON.stringify(fixtureStyle) : Buffer.alloc(0)}));
    async function setup(target = page) {
      await target.goto(base);
      await target.addScriptTag({url: base + 'vendor/maplibre-gl-4.7.1/maplibre-gl.js'});
      await target.evaluate(() => {
        window.testMaps = []; window.testMarkers = []; window.testStates = []; window.testSelections = [];
        const OriginalMap = maplibregl.Map, OriginalMarker = maplibregl.Marker;
        window.maplibregl = {...maplibregl, Map: class extends OriginalMap {
          constructor(options) { super(options); window.testMaps.push(this); }
          remove() { this.testRemoved = true; return super.remove(); }
        }, Marker: class extends OriginalMarker { constructor(options) { super(options); window.testMarkers.push(this); } }};
      });
      await target.addScriptTag({url: base + 'maps/citizen-map.js'});
    }
    await setup();
    await page.evaluate(() => {
      window.testOptions = {allow3D: true, bottomInset: 203, controlTop: 82, zoom: 14, reports: [
        {id: 'fixture-only', title: 'Reporte de prueba', source: 'demo', icon: 'bulb', latitude: 18.8126, longitude: -98.9548},
      ]};
      window.handle = CitizenMapLibre.create(document.getElementById('map'), testOptions, {
        onState: state => testStates.push(state), onReportSelected: id => testSelections.push(id),
      });
    });
    await page.waitForFunction(() => testStates.at(-1) === 'ready');
    assert.deepEqual(await page.evaluate(() => testMaps[0].getCenter().toArray()), [-98.9548, 18.8126]);
    assert.equal(await page.evaluate(() => testMaps[0].getPitch()), 0);
    await page.getByRole('button', {name: 'Reporte de prueba · Reporte de demostración', exact: true}).click();
    assert.deepEqual(await page.evaluate(() => testSelections), ['fixture-only']);
    assert.equal(await page.locator('.citizen-map-demo').isVisible(), true);
    await page.getByRole('button', {name: 'Alternar vista 2D y 3D'}).click();
    await page.waitForFunction(() => testMaps[0].getPitch() > 54);
    assert.equal(await page.evaluate(() => testMaps[0].getLayoutProperty('citizen-buildings-3d', 'visibility')), 'visible');
    await page.getByRole('button', {name: 'Alternar vista 2D y 3D'}).click();
    await page.waitForFunction(() => testMaps[0].getPitch() === 0);
    await page.evaluate(() => handle.update({...testOptions, reports: [], bottomInset: 300}));
    assert.equal(await page.locator('.citizen-map-marker').count(), 0);
    assert.equal(await page.locator('.citizen-map-demo').isVisible(), false);
    await page.setViewportSize({width: 320, height: 568});
    const footer = await page.locator('.citizen-map-attribution').boundingBox();
    assert.ok(footer.x >= 0 && footer.x + footer.width <= 321 && footer.y + footer.height <= 301);
    for (const text of ['OpenFreeMap', '© OpenMapTiles', '© OpenStreetMap']) assert.equal(await page.getByRole('link', {name: text, exact: true}).isVisible(), true);
    await page.evaluate(() => { handle.dispose(); handle.dispose(); });
    assert.equal(await page.locator('.maplibregl-canvas').count(), 0);
    assert.equal(await page.evaluate(() => testMaps[0].testRemoved), true);
    // Editor stays in 2D even if a caller accidentally asks for 3D.
    await page.evaluate(() => {
      document.getElementById('map').style.height = '137px';
      testStates = []; testSelections = [];
      window.handle = CitizenMapLibre.create(document.getElementById('map'), {editable: true, allow3D: true, controlTop: 48, reports: []}, {
        onState: state => testStates.push(state), onSelected: (lat, lng) => testSelections.push({lat, lng}),
      });
    });
    await page.waitForFunction(() => testStates.at(-1) === 'ready');
    assert.equal(await page.getByRole('button', {name: 'Alternar vista 2D y 3D'}).count(), 0);
    assert.equal(await page.evaluate(() => testMaps.at(-1).getMaxPitch()), 0);
    await page.touchscreen.tap(180, 60);
    await page.waitForFunction(() => testSelections.length === 1);
    const before = await page.evaluate(() => testSelections[0]);
    const marker = page.locator('.maplibregl-marker');
    const box = await marker.boundingBox();
    await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
    await page.mouse.down(); await page.mouse.move(box.x + box.width / 2 + 30, box.y + box.height / 2 + 12, {steps: 10}); await page.mouse.up();
    await page.waitForFunction(() => testSelections.length === 2);
    const after = await page.evaluate(() => testSelections[1]);
    assert.ok(Math.abs(after.lng - before.lng) > 0.00001);
    // Error stays visible and retry recreates the map and releases its predecessor.
    await page.evaluate(() => testMaps.at(-1).fire('error', {error: new Error('fixture network failure')}));
    await page.getByRole('button', {name: 'Reintentar'}).click();
    await page.waitForFunction(() => testStates.at(-1) === 'ready');
    assert.equal(await page.evaluate(() => testMaps.at(-2).testRemoved), true);
    await page.evaluate(() => handle.dispose());
    // Dispose during the library load must not create a late map.
    await page.route('**/vendor/maplibre-gl-4.7.1/maplibre-gl.js', async route => { await new Promise(resolve => setTimeout(resolve, 100)); await route.continue(); });
    await page.evaluate(() => { window.maplibregl = undefined; const pending = CitizenMapLibre.create(document.getElementById('map'), {}, {}); pending.dispose(); });
    await page.waitForTimeout(250);
    assert.equal(await page.locator('.maplibregl-canvas').count(), 0);
    assert.deepEqual(errors, []);
    console.log('PASS: Cuautla, 2D/3D, category click, demo labels, filter updates, mobile attribution, tap/drag, retry, disposal.');
    if (process.env.MAPLIBRE_LIVE === '1') {
      const live = await context.newPage();
      await setup(live);
      await live.evaluate(() => {
        window.handle = CitizenMapLibre.create(document.getElementById('map'), {allow3D: true, zoom: 16, reports: []}, {onState: state => testStates.push(state)});
      });
      await live.waitForFunction(() => testStates.at(-1) === 'ready', {timeout: 40000});
      await live.getByRole('button', {name: 'Alternar vista 2D y 3D'}).click();
      await live.waitForFunction(() => testMaps[0].getPitch() > 54 && testMaps[0].areTilesLoaded());
      const buildings = await live.evaluate(() => testMaps[0].querySourceFeatures('openmaptiles', {sourceLayer: 'building'}).length);
      const out = path.join(root, 'output/figma-renovacion/maplibre-cuautla-3d.png');
      fs.mkdirSync(path.dirname(out), {recursive: true}); await live.screenshot({path: out});
      console.log(`PASS: live OpenFreeMap in Cuautla; ${buildings} building features loaded. Screenshot: ${out}`);
      await live.evaluate(() => handle.dispose());
      await live.close();
    }
  } finally { await browser.close(); server.close(); }
})().catch(error => { console.error(error); server.close(); process.exitCode = 1; });
