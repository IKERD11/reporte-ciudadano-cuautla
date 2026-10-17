// Extract structural metadata without connecting to, or changing, a database.
import {parse} from 'libpg-query';
import {readFileSync, readdirSync, mkdirSync, writeFileSync} from 'node:fs';
const tables = {};
const name = r => `${r.schemaname ?? 'public'}.${r.relname}`;
const names = a => (a ?? []).map(x => x.String.sval);
function constraint(t, c, column) {
  const cols = column ? [column] : names(c.keys ?? c.fk_attrs);
  if (c.contype === 'CONSTR_PRIMARY') t.primary.push(...cols);
  if (c.contype === 'CONSTR_UNIQUE') t.unique.push(cols);
  if (c.contype === 'CONSTR_FOREIGN') t.foreign.push({columns: cols, target: name(c.pktable), references: names(c.pk_attrs)});
}
function column(t, c) {
  const constraints = (c.constraints ?? []).map(x => x.Constraint);
  t.columns.push({name:c.colname, type:names(c.typeName.names).join('.').replace('pg_catalog.',''), nullable: !constraints.some(x => ['CONSTR_PRIMARY','CONSTR_NOTNULL'].includes(x.contype))});
  constraints.forEach(x => constraint(t,x,c.colname));
}
const migrations = readdirSync('supabase/migrations').filter(x => x.endsWith('.sql')).sort();
for (const file of migrations) {
  const tree = await parse(readFileSync(`supabase/migrations/${file}`,'utf8'));
  for (const {stmt} of tree.stmts) {
    if (stmt.CreateStmt) {
      const s = stmt.CreateStmt;
      const t = tables[name(s.relation)] = {source:file, columns:[],primary:[],unique:[],foreign:[]};
      for (const e of s.tableElts ?? []) {
        if(e.ColumnDef) column(t,e.ColumnDef);
        if(e.Constraint) constraint(t,e.Constraint);
      }
    }
    if (stmt.AlterTableStmt) {
      const s=stmt.AlterTableStmt, t=tables[name(s.relation)];
      if(!t) continue;
      for(const {AlterTableCmd:c} of s.cmds) {
        if(c.subtype==='AT_AddColumn') column(t,c.def.ColumnDef);
        if(c.subtype==='AT_AddConstraint' && c.def.Constraint) constraint(t,c.def.Constraint);
      }
    }
  }
}
for (const t of Object.values(tables)) for(const c of t.columns) if(t.primary.includes(c.name)) c.nullable=false;
mkdirSync('docs/diagramas',{recursive:true});
writeFileSync('docs/diagramas/schema.json',JSON.stringify({migrations,tables},null,2)+'\n');
console.log(`${Object.keys(tables).length} tablas; ${Object.values(tables).reduce((n,t)=>n+t.columns.length,0)} columnas extraídas.`);
