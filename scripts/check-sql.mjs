import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { parse, parsePlPgSQL } from 'libpg-query';

const roots = ['supabase/migrations', 'supabase/tests/database'];
const files = [...roots.flatMap(dir => readdirSync(dir).filter(name => name.endsWith('.sql')).map(name => join(dir, name))), 'supabase/seed.sql'];
let failures = 0;
for (const file of files) {
  try {
    const sql = readFileSync(file, 'utf8');
    const tree = await parse(sql);
    await parsePlPgSQL(sql);
    // Validar también los cuerpos SQL, que CREATE FUNCTION trata como strings.
    for (const statement of tree.stmts) {
      const fn = statement.stmt.CreateFunctionStmt;
      if (!fn) continue;
      const options = fn.options.map(option => option.DefElem);
      const language = options.find(option => option.defname === 'language')?.arg?.String?.sval;
      if (language === 'sql') {
        const body = options.find(option => option.defname === 'as')?.arg?.List?.items?.[0]?.String?.sval;
        if (body) await parse(body);
      }
    }
    console.log(`SQL y PL/pgSQL válidos: ${file}`);
  } catch (error) {
    failures++;
    console.error(`${file}: ${error.message}`);
  }
}
console.log('Parser PostgreSQL 18: verifica sintaxis, no ejecuta RLS, triggers ni Storage. El runtime objetivo es PostgreSQL 17 y debe validarse con db:test.');
process.exitCode = failures ? 1 : 0;
