begin;
create table private.geocode_control (
 id boolean primary key default true check(id),
 lease uuid, available_at timestamptz not null default '-infinity',
 usage_day date not null default current_date, requests integer not null default 0
);
insert into private.geocode_control(id) values(true);
create table private.geocode_cache (
 key text primary key check(length(key)=64),
 results jsonb not null check(jsonb_typeof(results)='array' and jsonb_array_length(results)<=5),
 expires_at timestamptz not null
);
alter table private.geocode_control enable row level security;
alter table private.geocode_cache enable row level security;
revoke all on private.geocode_control,private.geocode_cache from public,anon,authenticated;
create function public.pilot_geocode_service(p_actor uuid,p_session uuid,p_action text,p_key text,p_ticket uuid default null,p_results jsonb default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare ctx jsonb; gate private.geocode_control; cached jsonb; ticket uuid;
begin
 ctx:=public.report_pilot_service(p_actor=>p_actor,p_session=>p_session,p_action=>'context');
 if not coalesce((ctx->>'enabled')::boolean,false) or not exists(select 1 from public.profiles p join public.municipalities m on m.id=p.municipality_id where p.id=p_actor and m.name='Cuautla' and m.state='Morelos') then raise exception 'Búsqueda no habilitada para este piloto' using errcode='42501'; end if;
 if p_key is null or p_key !~ '^[a-f0-9]{64}$' then raise exception 'Clave inválida' using errcode='22023'; end if;
 if p_action='reserve' then
   select results into cached from private.geocode_cache where key=p_key and expires_at>now();
   if found then return jsonb_build_object('results',cached); end if;
   select * into gate from private.geocode_control where id for update;
   if gate.available_at>clock_timestamp() then raise exception 'Hay otra búsqueda en curso. Intenta nuevamente en unos segundos.' using errcode='54000'; end if;
   if gate.usage_day=current_date and gate.requests>=100 then raise exception 'Se alcanzó el límite diario del piloto. Usa el mapa o tu ubicación.' using errcode='54000'; end if;
   ticket:=gen_random_uuid();
   update private.geocode_control set lease=ticket,available_at=clock_timestamp()+interval '60 seconds',usage_day=current_date,requests=case when gate.usage_day=current_date then gate.requests+1 else 1 end where id;
   delete from private.geocode_cache where expires_at<=now();
   return jsonb_build_object('ticket',ticket);
 elsif p_action='finish' then
   select * into gate from private.geocode_control where id for update;
   if gate.lease is distinct from p_ticket or p_ticket is null or gate.available_at<=clock_timestamp() then raise exception 'Búsqueda vencida' using errcode='22023'; end if;
   if p_results is not null then
     if jsonb_typeof(p_results)<>'array' or jsonb_array_length(p_results)>5 or length(p_results::text)>16000 then raise exception 'Resultado inválido' using errcode='22023'; end if;
     insert into private.geocode_cache(key,results,expires_at) values(p_key,p_results,now()+interval '30 days') on conflict(key) do update set results=excluded.results,expires_at=excluded.expires_at;
   end if;
   update private.geocode_control set lease=null,available_at=clock_timestamp()+interval '1100 milliseconds' where id;
   return jsonb_build_object('saved',true);
 end if;
 raise exception 'Acción inválida' using errcode='22023';
end;$$;
revoke all on function public.pilot_geocode_service(uuid,uuid,text,text,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.pilot_geocode_service(uuid,uuid,text,text,uuid,jsonb) to service_role;
commit;
