-- Fence prayer-push ownership by schedule generation and stable occurrence.
--
-- Deploy this additive migration before the v2 sync/v3 dispatcher Edge
-- Functions. The previous RPCs remain available to released clients during
-- the rollout; legacy syncs are accepted only while the stored revision is 0.

begin;

alter table public.prayer_push_installations
  add column if not exists schedule_revision bigint not null default 0,
  add column if not exists location_revision bigint not null default 0,
  add column if not exists lease_token uuid,
  add column if not exists claimed_schedule_revision bigint,
  add column if not exists claimed_event_index integer,
  add column if not exists claimed_notification_id integer,
  add column if not exists claimed_event_epoch bigint,
  add column if not exists claim_authorized_at timestamptz,
  add column if not exists ownership_acknowledged_at timestamptz;

alter table public.prayer_push_installations
  drop constraint if exists prayer_push_installations_schedule_revision_safe,
  add constraint prayer_push_installations_schedule_revision_safe
    check (schedule_revision between 0 and 9007199254740991),
  drop constraint if exists prayer_push_installations_location_revision_safe,
  add constraint prayer_push_installations_location_revision_safe
    check (location_revision between 0 and 9007199254740991);

-- Protect generation-owned fields even from a briefly overlapping legacy
-- Edge deployment that still performs a direct service-role upsert. Runtime
-- delivery fields remain mutable within a generation.
create or replace function public.enforce_prayer_push_generation_fence()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.schedule_revision > 0
     and coalesce(
       pg_catalog.current_setting('huda.prayer_push_fenced_write', true),
       ''
     ) <> '1' then
    raise exception 'unfenced prayer push generation write'
      using errcode = '23514';
  end if;
  if tg_op = 'INSERT' then
    return new;
  end if;
  if new.schedule_revision < old.schedule_revision
     or new.location_revision < old.location_revision then
    raise exception 'stale prayer push generation'
      using errcode = '23514';
  end if;
  if old.schedule_revision > 0
     and new.schedule_revision = old.schedule_revision
     and (
       new.location_revision is distinct from old.location_revision
       or new.time_zone is distinct from old.time_zone
       or new.configuration_signature is distinct from old.configuration_signature
       or new.local_coverage_until is distinct from old.local_coverage_until
       or new.schedule_through is distinct from old.schedule_through
       or new.schedule is distinct from old.schedule
     ) then
    raise exception 'conflicting prayer push generation'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

drop trigger if exists prayer_push_generation_fence
  on public.prayer_push_installations;
create trigger prayer_push_generation_fence
before insert or update on public.prayer_push_installations
for each row execute function public.enforce_prayer_push_generation_fence();

create table if not exists public.prayer_push_occurrence_ledger (
  installation_id uuid not null,
  notification_id integer not null,
  schedule_revision bigint not null,
  event_epoch bigint not null,
  disposition text not null,
  apns_status integer,
  recorded_at timestamptz not null default now(),
  primary key (installation_id, notification_id),
  constraint prayer_push_occurrence_ledger_disposition
    check (disposition in ('authorized', 'accepted', 'uncertain', 'suppressed')),
  constraint prayer_push_occurrence_ledger_revision_safe
    check (schedule_revision between 0 and 9007199254740991)
);

create index if not exists prayer_push_occurrence_ledger_retention_idx
  on public.prayer_push_occurrence_ledger (recorded_at);

alter table public.prayer_push_occurrence_ledger enable row level security;
revoke all on table public.prayer_push_occurrence_ledger
  from public, anon, authenticated;
grant all on table public.prayer_push_occurrence_ledger to service_role;

create or replace function public.sync_prayer_push_installation_v2(
  p_installation_id uuid,
  p_installation_secret_hash text,
  p_apns_token text,
  p_apns_environment text,
  p_bundle_id text,
  p_app_version text,
  p_time_zone text,
  p_configuration_signature text,
  p_local_coverage_until timestamptz,
  p_schedule_through timestamptz,
  p_schedule jsonb,
  p_next_event_index integer,
  p_next_notification_at timestamptz,
  p_location_revision bigint,
  p_schedule_revision bigint
)
returns table (
  status text,
  accepted_schedule_revision bigint,
  accepted_location_revision bigint,
  acknowledged_local_coverage_until timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_existing public.prayer_push_installations%rowtype;
  v_next_index integer;
  v_next_at timestamptz;
  v_is_legacy boolean := coalesce(p_schedule_revision, 0) = 0;
  v_had_existing boolean := false;
  v_idempotent boolean := false;
begin
  perform pg_catalog.set_config('huda.prayer_push_fenced_write', '1', true);
  if p_schedule_revision is null
     or p_schedule_revision < 0
     or p_schedule_revision > 9007199254740991
     or p_location_revision is null
     or p_location_revision < 0
     or p_location_revision > 9007199254740991
     or (p_schedule_revision = 0 and p_location_revision <> 0)
     or (p_schedule_revision > 0 and p_location_revision = 0) then
    return query select 'invalid_revision', 0::bigint, 0::bigint, null::timestamptz;
    return;
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('prayer-installation:' || p_installation_id::text, 0)
  );
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'prayer-token:' || p_apns_environment || ':' || p_apns_token,
      0
    )
  );

  select p.* into v_existing
  from public.prayer_push_installations p
  where p.installation_id = p_installation_id
  for update;
  v_had_existing := found;

  if v_had_existing and v_existing.installation_secret_hash <> p_installation_secret_hash then
    return query select
      'invalid_installation',
      v_existing.schedule_revision,
      v_existing.location_revision,
      v_existing.local_coverage_until;
    return;
  end if;

  if v_had_existing
     and (v_existing.schedule_revision > p_schedule_revision
          or v_existing.location_revision > p_location_revision) then
    return query select
      'stale_revision',
      v_existing.schedule_revision,
      v_existing.location_revision,
      v_existing.local_coverage_until;
    return;
  end if;

  if v_had_existing and not v_is_legacy
     and v_existing.schedule_revision = p_schedule_revision then
    if v_existing.location_revision <> p_location_revision
       or v_existing.time_zone <> p_time_zone
       or v_existing.configuration_signature <> p_configuration_signature
       or v_existing.local_coverage_until is distinct from p_local_coverage_until
       or v_existing.schedule_through is distinct from p_schedule_through
       or v_existing.schedule <> p_schedule then
      return query select
        'revision_conflict',
        v_existing.schedule_revision,
        v_existing.location_revision,
        v_existing.local_coverage_until;
      return;
    end if;
    v_idempotent := v_existing.enabled
      and v_existing.apns_token = p_apns_token
      and v_existing.apns_environment = p_apns_environment
      and v_existing.bundle_id = p_bundle_id;
    if v_idempotent
       and v_existing.apns_token = p_apns_token
       and v_existing.apns_environment = p_apns_environment
       and v_existing.bundle_id = p_bundle_id then
      update public.prayer_push_installations p
      set app_version = p_app_version,
          last_seen_at = now(),
          ownership_acknowledged_at = now(),
          updated_at = now()
      where p.installation_id = p_installation_id;
      return query select
        'idempotent', p_schedule_revision, p_location_revision,
        p_local_coverage_until;
      return;
    end if;
  end if;

  -- APNs tokens can survive reinstall. Move token ownership in the same
  -- transaction as schedule acceptance and invalidate every unapproved claim.
  update public.prayer_push_installations p
  set enabled = false,
      next_notification_at = null,
      lease_until = null,
      lease_token = null,
      claimed_schedule_revision = null,
      claimed_event_index = null,
      claimed_notification_id = null,
      claimed_event_epoch = null,
      claim_authorized_at = null,
      updated_at = now()
  where p.apns_token = p_apns_token
    and p.apns_environment = p_apns_environment
    and p.installation_id <> p_installation_id
    and p.enabled = true;

  insert into public.prayer_push_installations (
    installation_id, installation_secret_hash, apns_token, apns_environment,
    bundle_id, enabled, app_version, time_zone, configuration_signature,
    local_coverage_until, schedule_through, schedule, next_event_index,
    next_notification_at, lease_until, failure_count, last_apns_status,
    last_error, last_seen_at, updated_at, schedule_revision,
    location_revision, lease_token, claimed_schedule_revision,
    claimed_event_index, claimed_notification_id, claimed_event_epoch,
    claim_authorized_at, ownership_acknowledged_at
  ) values (
    p_installation_id, p_installation_secret_hash, p_apns_token,
    p_apns_environment, p_bundle_id, true, p_app_version, p_time_zone,
    p_configuration_signature, p_local_coverage_until, p_schedule_through,
    p_schedule, p_next_event_index, p_next_notification_at, null, 0, null,
    null, now(), now(), p_schedule_revision, p_location_revision, null, null,
    null, null, null, null, now()
  )
  on conflict (installation_id) do update
  set installation_secret_hash = excluded.installation_secret_hash,
      apns_token = excluded.apns_token,
      apns_environment = excluded.apns_environment,
      bundle_id = excluded.bundle_id,
      enabled = true,
      app_version = excluded.app_version,
      time_zone = excluded.time_zone,
      configuration_signature = excluded.configuration_signature,
      local_coverage_until = excluded.local_coverage_until,
      schedule_through = excluded.schedule_through,
      schedule = excluded.schedule,
      next_event_index = excluded.next_event_index,
      next_notification_at = excluded.next_notification_at,
      lease_until = null,
      lease_token = null,
      claimed_schedule_revision = null,
      claimed_event_index = null,
      claimed_notification_id = null,
      claimed_event_epoch = null,
      claim_authorized_at = null,
      failure_count = 0,
      last_apns_status = null,
      last_error = null,
      last_seen_at = now(),
      updated_at = now(),
      schedule_revision = excluded.schedule_revision,
      location_revision = excluded.location_revision,
      ownership_acknowledged_at = now();

  -- A delivery decision outlives schedule replacement. Do not select the same
  -- stable occurrence again merely because its epoch moved westward.
  select
    (event.ordinality - 1)::integer,
    pg_catalog.to_timestamp((event.value ->> 0)::bigint)
  into v_next_index, v_next_at
  from pg_catalog.jsonb_array_elements(p_schedule -> 'events')
    with ordinality as event(value, ordinality)
  where pg_catalog.to_timestamp((event.value ->> 0)::bigint) > greatest(
      coalesce(p_local_coverage_until, '-infinity'::timestamptz),
      now() - interval '60 seconds'
    )
    and not exists (
      select 1 from public.prayer_push_occurrence_ledger l
      where l.installation_id = p_installation_id
        and l.notification_id = ((event.value ->> 1)::integer)
    )
  order by event.ordinality
  limit 1;

  update public.prayer_push_installations p
  set next_event_index = v_next_index,
      next_notification_at = v_next_at
  where p.installation_id = p_installation_id;

  delete from public.prayer_push_occurrence_ledger l
  where l.installation_id = p_installation_id
    and l.recorded_at < now() - interval '400 days';

  return query select
    case when v_idempotent then 'idempotent' else 'accepted' end,
    p_schedule_revision,
    p_location_revision,
    p_local_coverage_until;
end;
$$;

revoke all on function public.sync_prayer_push_installation_v2(
  uuid, text, text, text, text, text, text, text, timestamptz,
  timestamptz, jsonb, integer, timestamptz, bigint, bigint
) from public, anon, authenticated;
grant execute on function public.sync_prayer_push_installation_v2(
  uuid, text, text, text, text, text, text, text, timestamptz,
  timestamptz, jsonb, integer, timestamptz, bigint, bigint
) to service_role;

create or replace function public.disable_prayer_push_installation_v2(
  p_installation_id uuid,
  p_installation_secret_hash text,
  p_location_revision bigint,
  p_schedule_revision bigint
)
returns table (
  status text,
  accepted_schedule_revision bigint,
  accepted_location_revision bigint
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_existing public.prayer_push_installations%rowtype;
begin
  perform pg_catalog.set_config('huda.prayer_push_fenced_write', '1', true);
  if p_schedule_revision is null
     or p_schedule_revision < 0
     or p_schedule_revision > 9007199254740991
     or p_location_revision is null
     or p_location_revision < 0
     or p_location_revision > 9007199254740991
     or (p_schedule_revision = 0 and p_location_revision <> 0)
     or (p_schedule_revision > 0 and p_location_revision = 0) then
    return query select 'invalid_revision', 0::bigint, 0::bigint;
    return;
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('prayer-installation:' || p_installation_id::text, 0)
  );
  select p.* into v_existing
  from public.prayer_push_installations p
  where p.installation_id = p_installation_id
  for update;
  if not found then
    return query select
      'absent',
      greatest(coalesce(p_schedule_revision, 0), 0),
      greatest(coalesce(p_location_revision, 0), 0);
    return;
  end if;
  if v_existing.installation_secret_hash <> p_installation_secret_hash then
    return query select
      'invalid_installation',
      v_existing.schedule_revision,
      v_existing.location_revision;
    return;
  end if;
  if p_schedule_revision < v_existing.schedule_revision
     or p_location_revision < v_existing.location_revision
     or (p_schedule_revision = v_existing.schedule_revision
         and p_location_revision <> v_existing.location_revision) then
    return query select
      'stale_revision',
      v_existing.schedule_revision,
      v_existing.location_revision;
    return;
  end if;
  update public.prayer_push_installations p
  set enabled = false,
      schedule_revision = greatest(p.schedule_revision, p_schedule_revision),
      location_revision = greatest(p.location_revision, p_location_revision),
      next_notification_at = null,
      lease_until = null,
      lease_token = null,
      claimed_schedule_revision = null,
      claimed_event_index = null,
      claimed_notification_id = null,
      claimed_event_epoch = null,
      claim_authorized_at = null,
      ownership_acknowledged_at = now(),
      last_seen_at = now(),
      updated_at = now()
  where p.installation_id = p_installation_id;
  return query select
    'accepted',
    greatest(v_existing.schedule_revision, p_schedule_revision),
    greatest(v_existing.location_revision, p_location_revision);
end;
$$;

revoke all on function public.disable_prayer_push_installation_v2(
  uuid, text, bigint, bigint
)
  from public, anon, authenticated;
grant execute on function public.disable_prayer_push_installation_v2(
  uuid, text, bigint, bigint
)
  to service_role;

create or replace function public.claim_due_prayer_pushes_v3(
  p_limit integer default 100
)
returns table (
  installation_id uuid,
  apns_token text,
  apns_environment text,
  bundle_id text,
  local_coverage_until timestamptz,
  next_event_index integer,
  failure_count integer,
  event_epoch bigint,
  notification_id integer,
  prayer text,
  title text,
  body text,
  schedule_revision bigint,
  location_revision bigint,
  lease_token uuid
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform pg_catalog.set_config('huda.prayer_push_fenced_write', '1', true);
  return query
  with due as (
    select p.installation_id
    from public.prayer_push_installations p
    where p.enabled = true
      and p.next_notification_at is not null
      and p.next_notification_at <= now()
      and (p.lease_until is null or p.lease_until <= now())
      and p.next_event_index is not null
      and not exists (
        select 1 from public.prayer_push_occurrence_ledger l
        where l.installation_id = p.installation_id
          and l.notification_id =
            ((p.schedule -> 'events' -> p.next_event_index) ->> 1)::integer
      )
    order by p.next_notification_at
    for update skip locked
    limit least(greatest(coalesce(p_limit, 100), 1), 500)
  ),
  claimed as (
    update public.prayer_push_installations p
    set lease_until = now() + interval '3 minutes',
        lease_token = extensions.gen_random_uuid(),
        claimed_schedule_revision = p.schedule_revision,
        claimed_event_index = p.next_event_index,
        claimed_notification_id =
          ((p.schedule -> 'events' -> p.next_event_index) ->> 1)::integer,
        claimed_event_epoch =
          ((p.schedule -> 'events' -> p.next_event_index) ->> 0)::bigint,
        claim_authorized_at = null,
        updated_at = now()
    from due
    where p.installation_id = due.installation_id
    returning p.*
  )
  select
    c.installation_id, c.apns_token, c.apns_environment, c.bundle_id,
    c.local_coverage_until, c.next_event_index, c.failure_count,
    c.claimed_event_epoch, c.claimed_notification_id,
    (c.schedule -> 'events' -> c.next_event_index) ->> 2,
    (c.schedule -> 'content' ->
      ((c.schedule -> 'events' -> c.next_event_index) ->> 2)) ->> 'title',
    (c.schedule -> 'content' ->
      ((c.schedule -> 'events' -> c.next_event_index) ->> 2)) ->> 'body',
    c.schedule_revision, c.location_revision, c.lease_token
  from claimed c;
end;
$$;

revoke all on function public.claim_due_prayer_pushes_v3(integer)
  from public, anon, authenticated;
grant execute on function public.claim_due_prayer_pushes_v3(integer)
  to service_role;

create or replace function public.authorize_prayer_push_delivery(
  p_installation_id uuid,
  p_schedule_revision bigint,
  p_lease_token uuid,
  p_notification_id integer,
  p_event_epoch bigint
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_inserted integer;
  v_row public.prayer_push_installations%rowtype;
  v_next_index integer;
  v_next_at timestamptz;
begin
  perform pg_catalog.set_config('huda.prayer_push_fenced_write', '1', true);
  select p.* into v_row
  from public.prayer_push_installations p
  where p.installation_id = p_installation_id
    and p.enabled = true
    and p.schedule_revision = p_schedule_revision
    and p.lease_token = p_lease_token
    and p.claimed_schedule_revision = p_schedule_revision
    and p.claimed_notification_id = p_notification_id
    and p.claimed_event_epoch = p_event_epoch
    and p.lease_until > now()
    and pg_catalog.to_timestamp(p_event_epoch) >
      coalesce(p.local_coverage_until, '-infinity'::timestamptz)
  for update;
  if not found then return false; end if;

  insert into public.prayer_push_occurrence_ledger (
    installation_id, notification_id, schedule_revision, event_epoch,
    disposition, recorded_at
  ) values (
    p_installation_id, p_notification_id, p_schedule_revision, p_event_epoch,
    'authorized', now()
  ) on conflict (installation_id, notification_id) do nothing;
  get diagnostics v_inserted = row_count;
  if v_inserted <> 1 then return false; end if;

  select
    (event.ordinality - 1)::integer,
    pg_catalog.to_timestamp((event.value ->> 0)::bigint)
  into v_next_index, v_next_at
  from pg_catalog.jsonb_array_elements(v_row.schedule -> 'events')
    with ordinality as event(value, ordinality)
  where event.ordinality - 1 > v_row.claimed_event_index
    and pg_catalog.to_timestamp((event.value ->> 0)::bigint) > greatest(
      coalesce(v_row.local_coverage_until, '-infinity'::timestamptz),
      now() - interval '60 seconds'
    )
    and not exists (
      select 1 from public.prayer_push_occurrence_ledger l
      where l.installation_id = p_installation_id
        and l.notification_id = ((event.value ->> 1)::integer)
    )
  order by event.ordinality
  limit 1;

  update public.prayer_push_installations p
  set claim_authorized_at = now(),
      next_event_index = v_next_index,
      next_notification_at = v_next_at,
      updated_at = now()
  where p.installation_id = p_installation_id
    and p.schedule_revision = p_schedule_revision
    and p.lease_token = p_lease_token;
  return found;
end;
$$;

revoke all on function public.authorize_prayer_push_delivery(
  uuid, bigint, uuid, integer, bigint
) from public, anon, authenticated;
grant execute on function public.authorize_prayer_push_delivery(
  uuid, bigint, uuid, integer, bigint
) to service_role;

create or replace function public.settle_prayer_push_claim(
  p_installation_id uuid,
  p_schedule_revision bigint,
  p_lease_token uuid,
  p_notification_id integer,
  p_event_epoch bigint,
  p_outcome text,
  p_apns_status integer default null,
  p_error text default null,
  p_failure_count integer default 0,
  p_retry_at timestamptz default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.prayer_push_installations%rowtype;
  v_next_index integer;
  v_next_at timestamptz;
begin
  perform pg_catalog.set_config('huda.prayer_push_fenced_write', '1', true);
  select p.* into v_row
  from public.prayer_push_installations p
  where p.installation_id = p_installation_id
    and p.schedule_revision = p_schedule_revision
    and p.lease_token = p_lease_token
    and p.claimed_schedule_revision = p_schedule_revision
    and p.claimed_notification_id = p_notification_id
    and p.claimed_event_epoch = p_event_epoch
  for update;
  if not found then return false; end if;
  if p_outcome not in (
    'accepted', 'uncertain', 'suppressed', 'retry', 'reschedule', 'permanent'
  ) then return false; end if;

  if p_outcome in ('accepted', 'uncertain', 'suppressed') then
    insert into public.prayer_push_occurrence_ledger (
      installation_id, notification_id, schedule_revision, event_epoch,
      disposition, apns_status, recorded_at
    ) values (
      p_installation_id, p_notification_id, p_schedule_revision, p_event_epoch,
      p_outcome, p_apns_status, now()
    ) on conflict (installation_id, notification_id) do update
      set disposition = excluded.disposition,
          apns_status = excluded.apns_status,
          recorded_at = excluded.recorded_at
      where public.prayer_push_occurrence_ledger.schedule_revision =
        p_schedule_revision;
  elsif p_outcome in ('retry', 'reschedule') then
    delete from public.prayer_push_occurrence_ledger l
    where l.installation_id = p_installation_id
      and l.notification_id = p_notification_id
      and l.schedule_revision = p_schedule_revision
      and l.disposition = 'authorized';
  end if;

  if p_outcome = 'permanent' then
    update public.prayer_push_installations p
    set enabled = false,
        next_notification_at = null,
        lease_until = null,
        lease_token = null,
        claimed_schedule_revision = null,
        claimed_event_index = null,
        claimed_notification_id = null,
        claimed_event_epoch = null,
        claim_authorized_at = null,
        failure_count = p_failure_count,
        last_apns_status = p_apns_status,
        last_error = p_error,
        updated_at = now()
    where p.installation_id = p_installation_id;
    return true;
  end if;

  if p_outcome in ('retry', 'reschedule') then
    update public.prayer_push_installations p
    set next_event_index = case
          when p_outcome = 'retry' then v_row.claimed_event_index
          else p.next_event_index
        end,
        next_notification_at = coalesce(p_retry_at, p.next_notification_at),
        lease_until = null,
        lease_token = null,
        claimed_schedule_revision = null,
        claimed_event_index = null,
        claimed_notification_id = null,
        claimed_event_epoch = null,
        claim_authorized_at = null,
        failure_count = case
          when p_outcome = 'retry' then p_failure_count
          else p.failure_count
        end,
        last_apns_status = p_apns_status,
        last_error = p_error,
        updated_at = now()
    where p.installation_id = p_installation_id;
    return true;
  end if;

  select
    (event.ordinality - 1)::integer,
    pg_catalog.to_timestamp((event.value ->> 0)::bigint)
  into v_next_index, v_next_at
  from pg_catalog.jsonb_array_elements(v_row.schedule -> 'events')
    with ordinality as event(value, ordinality)
  where event.ordinality - 1 > v_row.claimed_event_index
    and pg_catalog.to_timestamp((event.value ->> 0)::bigint) > greatest(
      coalesce(v_row.local_coverage_until, '-infinity'::timestamptz),
      now() - interval '60 seconds'
    )
    and not exists (
      select 1 from public.prayer_push_occurrence_ledger l
      where l.installation_id = p_installation_id
        and l.notification_id = ((event.value ->> 1)::integer)
    )
  order by event.ordinality
  limit 1;

  update public.prayer_push_installations p
  set next_event_index = v_next_index,
      next_notification_at = v_next_at,
      lease_until = null,
      lease_token = null,
      claimed_schedule_revision = null,
      claimed_event_index = null,
      claimed_notification_id = null,
      claimed_event_epoch = null,
      claim_authorized_at = null,
      failure_count = case when p_outcome = 'accepted' then 0 else p_failure_count end,
      last_delivery_at = case when p_outcome = 'accepted' then now() else p.last_delivery_at end,
      last_delivered_notification_id = case
        when p_outcome = 'accepted' then p_notification_id
        else p.last_delivered_notification_id
      end,
      last_delivered_scheduled_at = case
        when p_outcome = 'accepted' then pg_catalog.to_timestamp(p_event_epoch)
        else p.last_delivered_scheduled_at
      end,
      last_apns_status = p_apns_status,
      last_error = p_error,
      updated_at = now()
  where p.installation_id = p_installation_id;
  return true;
end;
$$;

revoke all on function public.settle_prayer_push_claim(
  uuid, bigint, uuid, integer, bigint, text, integer, text, integer, timestamptz
) from public, anon, authenticated;
grant execute on function public.settle_prayer_push_claim(
  uuid, bigint, uuid, integer, bigint, text, integer, text, integer, timestamptz
) to service_role;

create or replace function public.correct_prayer_push_environment(
  p_installation_id uuid,
  p_schedule_revision bigint,
  p_lease_token uuid,
  p_notification_id integer,
  p_apns_token text,
  p_corrected_environment text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform pg_catalog.set_config('huda.prayer_push_fenced_write', '1', true);
  perform 1 from public.prayer_push_installations p
  where p.installation_id = p_installation_id
    and p.schedule_revision = p_schedule_revision
    and p.lease_token = p_lease_token
    and p.claimed_notification_id = p_notification_id
    and p.apns_token = p_apns_token
  for update;
  if not found then return false; end if;

  update public.prayer_push_installations p
  set enabled = false,
      next_notification_at = null,
      lease_until = null,
      lease_token = null,
      updated_at = now()
  where p.apns_token = p_apns_token
    and p.apns_environment = p_corrected_environment
    and p.installation_id <> p_installation_id;

  update public.prayer_push_installations p
  set apns_environment = p_corrected_environment, updated_at = now()
  where p.installation_id = p_installation_id
    and p.schedule_revision = p_schedule_revision
    and p.lease_token = p_lease_token;
  return found;
end;
$$;

revoke all on function public.correct_prayer_push_environment(
  uuid, bigint, uuid, integer, text, text
) from public, anon, authenticated;
grant execute on function public.correct_prayer_push_environment(
  uuid, bigint, uuid, integer, text, text
) to service_role;

commit;
