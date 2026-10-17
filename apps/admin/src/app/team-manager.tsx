'use client';
import {useEffect,useState} from 'react';
import {supabase} from '../lib/api';
import {ModernSelect} from './modern-controls';

type Member={id:string;name:string;roles:string[];cases:number};
type Role={code:string;description:string;permissions:string[]};
type TeamPage={actor:string;total:number;members:Member[];roles:Role[]};
export function TeamManager({onSaved}:{onSaved:()=>Promise<void>}) {
 const [data,setData]=useState<TeamPage|null>(null),[query,setQuery]=useState(''),[filter,setFilter]=useState(''),[offset,setOffset]=useState(0);
 const [busy,setBusy]=useState(false),[error,setError]=useState(''),[message,setMessage]=useState(''),[revision,setRevision]=useState(0);
 const [selected,setSelected]=useState<Member|null>(null),[role,setRole]=useState('OPERATOR');
 useEffect(()=>{let active=true;setBusy(true);setError('');setData(null);setSelected(null);
  void supabase.rpc('admin_team',{p_action:'list',p_data:{query:filter,offset}}).then(({data,error})=>{if(!active)return;if(error)setError(error.message);else setData(data as TeamPage);setBusy(false);});
  return()=>{active=false;};
 },[filter,offset,revision]);
 async function save(){if(!selected)return;setBusy(true);setError('');setMessage('');
  try{const {error}=await supabase.rpc('admin_team',{p_action:'set_role',p_data:{id:selected.id,role,expected_roles:selected.roles}});if(error)throw error;
   setSelected(null);setMessage('Rol actualizado y registrado en la bitácora.');setRevision(v=>v+1);await onSaved();
  }catch(e){setError((e as Error).message);}finally{setBusy(false);}
 }
 return <section className="card"><div className="card-heading"><h3>Administrar accesos municipales</h3></div>
 <p>Selecciona una cuenta registrada del municipio. El rol Ciudadano retira su acceso al panel; conserva sus reportes.</p>
 <form className="filters" onSubmit={e=>{e.preventDefault();setOffset(0);setFilter(query.trim());}}><input aria-label="Buscar integrante" placeholder="Buscar por nombre" maxLength={160} value={query} onChange={e=>setQuery(e.target.value)}/><button className="outline" disabled={busy}>Buscar</button><button type="button" className="outline" disabled={busy} onClick={()=>setRevision(v=>v+1)}>Recargar</button></form>
 {error&&<p role="alert" className="alert error">{error}</p>}{message&&<p role="status" className="alert success">{message}</p>}
 {busy&&<p role="status">Actualizando equipo…</p>}
 {data&&<><div className="table-scroll"><table><thead><tr><th>Nombre</th><th>Roles</th><th>Casos activos</th><th>Acceso</th></tr></thead><tbody>{data.members.map(m=><tr key={m.id}><td>{m.name||'Sin nombre'}</td><td>{m.roles.join(', ')}</td><td>{m.cases}</td><td><button className="outline" disabled={busy||m.id===data.actor||m.roles.includes('SUPER_ADMIN')} onClick={()=>{setSelected(m);setRole(m.roles.find(r=>r!=='CITIZEN')||'CITIZEN');setMessage('');}}>Cambiar rol</button></td></tr>)}</tbody></table></div>
 {!data.members.length&&<p>No se encontraron cuentas.</p>}
 <div className="pagination"><span>{data.total} cuentas</span><button className="outline" disabled={busy||offset===0} onClick={()=>setOffset(v=>v-20)}>Anterior</button><button className="outline" disabled={busy||offset+20>=data.total} onClick={()=>setOffset(v=>v+20)}>Siguiente</button></div>
 {selected&&<section className="action-card" aria-label="Confirmar cambio de rol"><h3>Cambiar acceso de {selected.name}</h3><p>Actual: {selected.roles.join(', ')}</p><ModernSelect aria-label="Rol municipal" value={role} onChange={e=>setRole(e.target.value)}>{data.roles.map(r=><option key={r.code} value={r.code}>{r.description}</option>)}</ModernSelect><p>Permisos del nuevo rol: {data.roles.find(r=>r.code===role)?.permissions.join(', ')}</p><button className="primary" disabled={busy} onClick={()=>void save()}>Confirmar cambio de rol</button><button className="outline" disabled={busy} onClick={()=>setSelected(null)}>Cancelar</button></section>}
 <details><summary>Consultar roles y permisos</summary>{data.roles.map(r=><p key={r.code}><strong>{r.description}</strong><br/>{r.permissions.join(', ')}</p>)}</details></>}
 </section>;
}
