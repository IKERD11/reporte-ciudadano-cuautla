import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
let sql=readFileSync('supabase/tests/database/003_auth.test.sql','utf8');
sql=sql.replace('select plan(22);','select plan(22);\ncreate temporary table phase2_test_results(result text); grant all on phase2_test_results to anon,authenticated;');
sql=sql.replace(/\bselect (is|ok|throws_ok)\(/gi,'insert into phase2_test_results select $1(');
sql=sql.replace('select * from finish();','insert into phase2_test_results select * from finish();\nselect jsonb_agg(result) as assertions from phase2_test_results;');
mkdirSync('supabase/.tests-generated',{recursive:true});
writeFileSync('supabase/.tests-generated/003_auth.test.sql',sql);
