import {copyFileSync,mkdirSync,readFileSync} from 'node:fs';
import {resolve} from 'node:path';
const version=JSON.parse(readFileSync('node_modules/maplibre-gl/package.json','utf8')).version;
const target=resolve('public/maps',`maplibre-${version}`);
mkdirSync(target,{recursive:true});
copyFileSync('node_modules/maplibre-gl/dist/maplibre-gl-worker.mjs',resolve(target,'worker.mjs'));
copyFileSync('node_modules/maplibre-gl/LICENSE.txt',resolve(target,'LICENSE.txt'));
console.log(`MapLibre ${version}: worker local preparado.`);
