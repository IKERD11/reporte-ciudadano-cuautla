-- Keep existing session, permission, quota and idempotency checks unchanged.
-- A written address is valid without inventing a geographic point.
do $migration$
declare
  definition text := pg_get_functiondef('private.report_pilot(uuid,uuid,text,uuid,jsonb,uuid,integer,text)'::regprocedure);
  previous text := '(cat.requires_location and lat is null)';
  replacement text := '(cat.requires_location and lat is null and length(trim(coalesce(d->>''address'',''''))) < 10)';
begin
  if strpos(definition, previous) = 0 then
    raise exception 'Expected report location validation not found';
  end if;
  execute replace(definition, previous, replacement);
end
$migration$;
