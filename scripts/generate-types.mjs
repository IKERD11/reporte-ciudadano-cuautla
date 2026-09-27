import { spawnSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';
const result = spawnSync(process.platform === 'win32' ? 'npx.cmd' : 'npx', ['supabase', 'gen', 'types', 'typescript', '--local', '--schema', 'public'], { encoding: 'utf8', shell: process.platform === 'win32' });
if (result.status !== 0) { console.error(result.stderr); process.exit(result.status || 1); }
writeFileSync(new URL('../packages/shared/database.types.ts', import.meta.url), result.stdout, 'utf8');
