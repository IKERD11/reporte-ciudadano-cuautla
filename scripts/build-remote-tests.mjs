import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
const seed = readFileSync('supabase/seed.sql','utf8').replace(/^begin;\s*$/gmi,'').replace(/^commit;\s*$/gmi,'');
const guard = `do $$ begin
  if exists(select 1 from public.municipalities where id in ('10000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002'))
    or exists(select 1 from auth.users) or exists(select 1 from public.reports) then
    raise exception 'Estas pruebas requieren ausencia de usuarios, reportes y UUID de fixtures; permiten configuración municipal existente';
  end if;
end $$;`;
mkdirSync('supabase/.tests-generated',{recursive:true});
for (const file of ['001_security.test.sql','002_storage.test.sql']) {
  let sql = readFileSync(`supabase/tests/database/${file}`,'utf8');
  sql = sql.replace(/^begin;/mi, () => `begin;\nset local search_path=public,extensions;\n${guard}\n${seed}\ncreate temporary table phase1_test_results(result text); grant all on phase1_test_results to authenticated,anon;`);
  sql = sql.replace(/\bselect (is|ok|throws_ok)\(/gi,'insert into phase1_test_results(result) select $1(');
  sql = sql.replace('select * from finish();','reset role;\ninsert into phase1_test_results select * from finish();\nselect jsonb_agg(result) as assertions from phase1_test_results;');
  writeFileSync(`supabase/.tests-generated/${file}`, sql);
  console.log(`Preparado: supabase/.tests-generated/${file}`);
}
