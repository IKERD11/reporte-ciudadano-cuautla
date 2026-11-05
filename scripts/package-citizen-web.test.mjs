import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp, mkdir, writeFile, readFile, rm} from 'node:fs/promises';
import {resolve, join, sep} from 'node:path';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';

for (const token of ['"3956041637"', '3956041637']) {
  test(`release packaging produces valid asset URLs for Flutter token ${token}`, async () => {
    const workspaceTemp=resolve('tmp');
    const root=await mkdtemp(join(workspaceTemp,'package-web-test-'));
    try {
      await mkdir(join(root,'maps'));
      await writeFile(join(root,'index.html'),`<link href="maps/citizen-map.css?release=${token}"><script src="maps/citizen-map.js?release=${token}"></script><script src="flutter_bootstrap.js?release=${token}" async></script>`);
      await writeFile(join(root,'flutter_bootstrap.js'),`const build={"mainJsPath":"main.dart.js"};build.mainJsPath += '?release=${token}';`);
      await writeFile(join(root,'main.dart.js'),'window.appLoaded=true;');
      await writeFile(join(root,'maps/citizen-map.js'),'window.mapLoaded=true;');
      await writeFile(join(root,'maps/citizen-map.css'),'body{margin:0}');
      execFileSync(process.execPath,['scripts/package-citizen-web.mjs',root],{stdio:'pipe'});
      const html=await readFile(join(root,'index.html'),'utf8');
      assert.match(html, /^<link href="maps\/citizen-map\.[a-f0-9]{12}\.css"><script src="maps\/citizen-map\.[a-f0-9]{12}\.js"><\/script><script src="flutter_bootstrap\.[a-f0-9]{12}\.js" async><\/script>$/);
      for(const [,relative] of html.matchAll(/(?:href|src)="([^"]+)"/g)) {
        const bytes=await readFile(join(root,relative));
        assert.ok(relative.includes(createHash('sha256').update(bytes).digest('hex').slice(0,12)));
      }
      const bootstrap=await readFile(join(root,'flutter_bootstrap.js'),'utf8');
      assert.match(bootstrap,/main\.dart\.[a-f0-9]{12}\.js/);
      assert.ok(!bootstrap.includes('?release="'));
    } finally {
      assert.ok(resolve(root).startsWith(workspaceTemp+sep));
      await rm(root,{recursive:true,force:true});
    }
  });
}
