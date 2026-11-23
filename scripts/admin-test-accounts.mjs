import { randomBytes } from 'node:crypto';
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const privateDir = resolve(root, 'tmp/admin-test-accounts');
const credentialsPath = resolve(privateDir, 'credentials.json');
const sqlPath = resolve(privateDir, 'provision.sql');
const mode = process.argv[2];

if (mode === 'prepare') {
  if (existsSync(credentialsPath) || existsSync(sqlPath)) {
    throw new Error('Ya existen archivos privados. No se sobrescriben credenciales.');
  }
  const accounts = Array.from({ length: 6 }, (_, i) => ({
    email: `admin.prueba.${String(i + 1).padStart(2, '0')}@example.test`,
    password: `Rc!${randomBytes(24).toString('base64url')}9a`,
    role: 'MUNICIPAL_ADMIN',
    municipality: 'Cuautla',
  }));
  const template = readFileSync(resolve(root, 'supabase/provisioning/admin-test-accounts.sql'), 'utf8');
  const literal = JSON.stringify(accounts).replaceAll("'", "''");
  mkdirSync(privateDir, { recursive: true });
  writeFileSync(credentialsPath, JSON.stringify(accounts, null, 2) + '\n', { flag: 'wx', mode: 0o600 });
  writeFileSync(sqlPath, `begin;\nselect set_config('app.test_admin_accounts', '${literal}', true);\n${template}\ncommit;\n`, { flag: 'wx', mode: 0o600 });
  console.log('Credenciales y SQL privados preparados en tmp/admin-test-accounts/. No se aplicaron cambios remotos.');
} else if (mode === 'verify') {
  const env = Object.fromEntries(readFileSync(resolve(root, 'apps/admin/.env.local'), 'utf8')
    .replace(/^\uFEFF/, '').split(/\r?\n/).filter(line => /^[A-Z_]+=/.test(line))
    .map(line => { const at = line.indexOf('='); return [line.slice(0, at), line.slice(at + 1).replace(/^(['"])(.*)\1$/, '$2')]; }));
  const url = env.NEXT_PUBLIC_SUPABASE_URL;
  const key = env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  assert.ok(url && key, 'Falta configuración pública del panel');
  for (const account of JSON.parse(readFileSync(credentialsPath, 'utf8'))) {
    const login = await fetch(`${url}/auth/v1/token?grant_type=password`, {
      method: 'POST', headers: { apikey: key, 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: account.email, password: account.password }),
    });
    const session = await login.json();
    assert.equal(login.status, 200, `Login fallido: ${account.email} (${session.error_code ?? login.status})`);
    const headers = { apikey: key, Authorization: `Bearer ${session.access_token}`, 'Content-Type': 'application/json' };
    try {
      for (const action of ['context', 'summary', 'list']) {
        const response = await fetch(`${url}/rest/v1/rpc/admin_pilot`, {
          method: 'POST', headers, body: JSON.stringify({ p_action: action, p_data: {} }),
        });
        assert.equal(response.status, 200, `${action} falló para ${account.email}`);
        const data = await response.json();
        if (action === 'context') {
          assert.equal(data.municipality, 'Cuautla');
          assert.deepEqual(data.roles, ['MUNICIPAL_ADMIN']);
          for (const permission of ['reports.read', 'reports.read_all', 'reports.assign']) {
            assert.ok(data.permissions.includes(permission), `Falta permiso ${permission}`);
          }
        }
      }
      console.log(`OK: ${account.email} — login, rol municipal, resumen y reportes`);
    } finally {
      const logout = await fetch(`${url}/auth/v1/logout?scope=local`, { method: 'POST', headers });
      assert.ok(logout.ok, `No se pudo cerrar sesión de ${account.email}`);
    }
  }
} else {
  throw new Error('Uso: node scripts/admin-test-accounts.mjs prepare|verify');
}
