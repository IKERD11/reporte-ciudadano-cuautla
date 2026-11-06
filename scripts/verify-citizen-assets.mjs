import { readdir, readFile } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
const root = resolve(import.meta.dirname, '..');
const app = join(root, 'apps/citizen-web');
const reference = join(root, 'design/figma');
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
async function files(dir, prefix = '') {
  const result = [];
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const name = join(prefix, entry.name);
    if (entry.isDirectory()) result.push(...await files(join(dir, entry.name), name));
    else result.push(name);
  }
  return result;
}
assert.equal(hash(await readFile(join(app, 'src/index.css'))), hash(await readFile(join(reference, 'src/index.css'))), 'CSS differs from the ZIP reference');
let checked = 0;
const emitted = await Promise.all((await files(join(app, 'dist/assets'))).map(async f => hash(await readFile(join(app, 'dist/assets', f)))));
for (const base of ['public', 'src/assets']) {
  for (const file of await files(join(reference, base))) {
    if (!file.endsWith('.webp') && !file.endsWith('.svg')) continue;
    const original = hash(await readFile(join(reference, base, file)));
    assert.equal(hash(await readFile(join(app, base, file))), original, `Changed visual asset: ${file}`);
    if (base === 'public') assert.equal(hash(await readFile(join(app, 'dist', file))), original, `Missing public asset: ${file}`);
    else assert.ok(emitted.includes(original), `Missing bundled asset: ${file}`);
    checked++;
  }
}
const source = await readFile(join(app, 'src/App.tsx'), 'utf8');
const routes = source.match(/type AppScreen = ([^\n]+)/)[1].match(/"[A-Za-z]+"/g);
assert.equal(routes.length, 28);
assert.equal(new Set(routes).size, 28);
console.log(`PASS: identical ZIP stylesheet; ${checked} original visual assets included in build; all 28 screen routes preserved.`);
