import {readFile, writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {resolve, join} from 'node:path';

// Content-address the startup assets after Flutter builds. Keep canonical files
// for older clients/service-worker manifests; new HTML only uses immutable URLs.
const root = resolve(process.argv[2] ?? 'apps/mobile/build/web');
const hash = bytes => createHash('sha256').update(bytes).digest('hex').slice(0, 12);
async function fingerprint(relative) {
  const bytes = await readFile(join(root, relative));
  const at = relative.lastIndexOf('.');
  const versioned = `${relative.slice(0, at)}.${hash(bytes)}${relative.slice(at)}`;
  await writeFile(join(root, versioned), bytes);
  return versioned;
}
let html = await readFile(join(root, 'index.html'), 'utf8');
let bootstrap = await readFile(join(root, 'flutter_bootstrap.js'), 'utf8');
const main = await fingerprint('main.dart.js');
const key = /"mainJsPath"\s*:\s*"main\.dart\.js"/g;
if (!key.test(bootstrap)) throw new Error('Flutter build must run before packaging.');
bootstrap = bootstrap.replace(key, `"mainJsPath":"${main}"`);
await writeFile(join(root, 'flutter_bootstrap.js'), bootstrap);
const boot = await fingerprint('flutter_bootstrap.js');
const mapScript = await fingerprint('maps/citizen-map.js');
const mapStyle = await fingerprint('maps/citizen-map.css');
for (const [pattern, value] of [
  [/src="flutter_bootstrap\.js(?:\?[^"\s]*)?"/, `src="${boot}"`],
  [/src="maps\/citizen-map\.js(?:\?[^"\s]*)?"/, `src="${mapScript}"`],
  [/href="maps\/citizen-map\.css(?:\?[^"\s]*)?"/, `href="${mapStyle}"`],
]) {
  if (!pattern.test(html)) throw new Error('Expected startup asset missing.');
  html = html.replace(pattern, value);
}
await writeFile(join(root, 'index.html'), html);
console.log(JSON.stringify({main, bootstrap: boot, mapScript, mapStyle}));
