begin;
-- All mutations are server-owned; clients can only list and acknowledge their own events.
revoke all on public.notifications from anon,authenticated;
create index notifications_unread_idx on public.notifications(user_id,municipality_id) where read_at is null;
create function private.notify_pilot_report() returns trigger language plpgsql security definer set search_path='' as $$
declare r public.reports; label text;
begin
 if tg_table_name='reports' then
  r:=new;
  if not r.is_pilot then return new; end if;
  if tg_op='UPDATE' and new.status_id is not distinct from old.status_id then return new; end if;
  select name into label from public.report_statuses where id=r.status_id;
  insert into public.notifications(municipality_id,user_id,report_id,title,body)
  values(r.municipality_id,r.citizen_id,r.id,case when tg_op='INSERT' then 'Reporte de prueba recibido' else 'Tu reporte ha sido actualizado' end,
  'PRUEBA PILOTO · '||r.folio||' · Estado: '||label||'. Sin atención municipal real.');
 else
  select * into r from public.reports where id=new.report_id and is_pilot;
  if not found or new.unassigned_at is not null then return new; end if;
  -- The first assignment emits the ASIGNADO status event in the same transaction.
  if exists(select 1 from public.report_statuses where id=r.status_id and code='VALIDADO') then return new; end if;
  insert into public.notifications(municipality_id,user_id,report_id,title,body)
  values(r.municipality_id,r.citizen_id,r.id,'Asignación de prueba actualizada','PRUEBA PILOTO · '||r.folio||' · Se actualizó el equipo responsable. Sin atención municipal real.');
 end if;
 return new;
end;$$;
revoke all on function private.notify_pilot_report() from public,anon,authenticated;
create trigger pilot_report_notification after insert or update of status_id on public.reports for each row execute function private.notify_pilot_report();
create trigger pilot_assignment_notification after insert on public.report_assignments for each row execute function private.notify_pilot_report();
create function private.citizen_notifications(p_action text,p_id uuid default null,p_offset integer default 0) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid(); home uuid; result jsonb;
begin
 if actor is null or not exists(select 1 from auth.users u join auth.sessions s on s.user_id=u.id
 where u.id=actor and s.id=nullif(auth.jwt()->>'session_id','')::uuid and (s.not_after is null or s.not_after>now())
 and u.email_confirmed_at is not null and u.deleted_at is null and not coalesce(u.is_anonymous,false) and (u.banned_until is null or u.banned_until<=now())) then
 raise exception 'Sesión no autorizada' using errcode='42501'; end if;
 select municipality_id into home from public.profiles where id=actor and is_active and deleted_at is null;
 if home is null then raise exception 'Perfil no autorizado' using errcode='42501'; end if;
 if p_offset is null or p_offset<0 or p_offset>100000 then raise exception 'Página inválida' using errcode='22023'; end if;
 if p_action='read' then
  update public.notifications set read_at=coalesce(read_at,now()) where id=p_id and user_id=actor and municipality_id=home;
  if not found then raise exception 'Aviso no disponible' using errcode='42501'; end if;
 elsif p_action not in ('list','count') or p_action is null then raise exception 'Acción inválida' using errcode='22023'; end if;
 if p_action='read' then return jsonb_build_object('saved',true); end if;
 select jsonb_build_object('unread',count(*) filter(where read_at is null),'total',count(*)) into result
 from public.notifications where user_id=actor and municipality_id=home;
 if p_action='count' then return result; end if;
 return result||jsonb_build_object('items',(select coalesce(jsonb_agg(to_jsonb(n) order by n.created_at desc,n.id desc),'[]') from
 (select id,report_id,title,body,read_at,created_at from public.notifications where user_id=actor and municipality_id=home order by created_at desc,id desc limit 20 offset p_offset) n));
end;$$;
revoke all on function private.citizen_notifications(text,uuid,integer) from public,anon;
grant execute on function private.citizen_notifications(text,uuid,integer) to authenticated;
create function public.citizen_notifications(p_action text,p_id uuid default null,p_offset integer default 0) returns jsonb
language sql security invoker set search_path='' as $$ select private.citizen_notifications(p_action,p_id,p_offset); $$;
revoke all on function public.citizen_notifications(text,uuid,integer) from public,anon;
grant execute on function public.citizen_notifications(text,uuid,integer) to authenticated;
commit;
