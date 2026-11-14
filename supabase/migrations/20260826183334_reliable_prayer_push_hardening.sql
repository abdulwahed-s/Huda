-- Reliability-neutral prayer-push hardening.
--
-- Registration is serialized and atomic, notification content/schedule shape is
-- validated in the Edge Function, and replay metadata is carried on the
-- installation row. None of these changes adds a network hop or database write
-- to the normal due-time APNs path.

begin;

alter table public.prayer_push_installations
  add column if not exists last_delivered_notification_id integer,
  add column if not exists last_delivered_scheduled_at timestamptz;

-- Resolve any pre-existing registration race deterministically before
-- switching all future registrations to the serialized RPC. Keep the row most
-- recently confirmed by an app installation.
with ranked as (
  select
    installation_id,
    row_number() over (
      partition by apns_token, apns_environment
      order by last_seen_at desc, updated_at desc, installation_id
    ) as position
  from public.prayer_push_installations
  where enabled = true
)
update public.prayer_push_installations p
set enabled = false,
    next_notification_at = null,
    lease_until = null,
    last_error = 'Disabled duplicate installation during registration hardening',
    updated_at = now()
from ranked r
where p.installation_id = r.installation_id
  and r.position > 1;

create or replace function public.sync_prayer_push_installation(
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
  p_next_notification_at timestamptz
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_existing_secret text;
begin
  -- Lock the logical installation first, then the destination token. This
  -- serializes races involving either the identity or the APNs destination.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('prayer-installation:' || p_installation_id::text, 0)
  );
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'prayer-token:' || p_apns_environment || ':' || p_apns_token,
      0
    )
  );

  select installation_secret_hash
  into v_existing_secret
  from public.prayer_push_installations
  where installation_id = p_installation_id
  for update;

  if found and v_existing_secret <> p_installation_secret_hash then
    return 'invalid_installation';
  end if;

  -- APNs tokens can survive an app reinstall. Preserve the existing behavior
  -- of transferring a token while making disable + upsert one transaction.
  update public.prayer_push_installations
  set enabled = false,
      next_notification_at = null,
      lease_until = null,
      updated_at = now()
  where apns_token = p_apns_token
    and apns_environment = p_apns_environment
    and installation_id <> p_installation_id
    and enabled = true;

  insert into public.prayer_push_installations (
    installation_id,
    installation_secret_hash,
    apns_token,
    apns_environment,
    bundle_id,
    enabled,
    app_version,
    time_zone,
    configuration_signature,
    local_coverage_until,
    schedule_through,
    schedule,
    next_event_index,
    next_notification_at,
    lease_until,
    failure_count,
    last_apns_status,
    last_error,
    last_seen_at,
    updated_at
  ) values (
    p_installation_id,
    p_installation_secret_hash,
    p_apns_token,
    p_apns_environment,
    p_bundle_id,
    true,
    p_app_version,
    p_time_zone,
    p_configuration_signature,
    p_local_coverage_until,
    p_schedule_through,
    p_schedule,
    p_next_event_index,
    p_next_notification_at,
    null,
    0,
    null,
    null,
    now(),
    now()
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
      failure_count = 0,
      last_apns_status = null,
      last_error = null,
      last_seen_at = now(),
      updated_at = now();

  return 'ok';
end;
$$;

revoke all on function public.sync_prayer_push_installation(
  uuid, text, text, text, text, text, text, text, timestamptz,
  timestamptz, jsonb, integer, timestamptz
) from public, anon, authenticated;
grant execute on function public.sync_prayer_push_installation(
  uuid, text, text, text, text, text, text, text, timestamptz,
  timestamptz, jsonb, integer, timestamptz
) to service_role;

-- Existing projects already have this private table for the shared API
-- limiter. Define it here as well so a clean migration replay remains
-- self-contained.
create table if not exists public.rate_counters (
  bucket text primary key,
  count integer not null default 0,
  expires_at timestamptz not null
);
alter table public.rate_counters enable row level security;
revoke all on table public.rate_counters from public, anon, authenticated;
grant all on table public.rate_counters to service_role;

create or replace function public.check_prayer_push_sync_rate_limit(
  p_ip text,
  p_installation_id uuid,
  p_existing_installation boolean
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := now();
  v_ip text := left(coalesce(nullif(trim(p_ip), ''), 'unknown'), 128);
  v_today text := to_char(v_now, 'YYYY-MM-DD');
  v_burst_window text := floor(extract(epoch from v_now) / 10)::text;
  v_burst_count integer;
  v_ip_count integer;
  v_installation_count integer := 0;
begin
  delete from public.rate_counters
  where expires_at < v_now
    and (
      bucket like 'burst:prayer-push-sync:%'
      or bucket like 'day:prayer-push-sync:%'
      or bucket like 'installation:prayer-push-sync:%'
    );

  insert into public.rate_counters (bucket, count, expires_at)
  values (
    'burst:prayer-push-sync:' || v_ip || ':' || v_burst_window,
    1,
    v_now + interval '20 seconds'
  )
  on conflict (bucket) do update set count = public.rate_counters.count + 1
  returning count into v_burst_count;

  insert into public.rate_counters (bucket, count, expires_at)
  values (
    'day:prayer-push-sync:' || v_ip || ':' || v_today,
    1,
    v_now + interval '2 days'
  )
  on conflict (bucket) do update set count = public.rate_counters.count + 1
  returning count into v_ip_count;

  if p_existing_installation then
    insert into public.rate_counters (bucket, count, expires_at)
    values (
      'installation:prayer-push-sync:' || p_installation_id::text || ':' || v_today,
      1,
      v_now + interval '2 days'
    )
    on conflict (bucket) do update set count = public.rate_counters.count + 1
    returning count into v_installation_count;
  end if;

  -- These ceilings are far above Huda's normal sync frequency. They protect
  -- resources without a project-wide quota that one caller could exhaust. The
  -- per-installation ceiling is also looser than the former per-IP ceiling, so
  -- this migration cannot reduce legitimate refresh capacity.
  return v_burst_count > 30
    or v_ip_count > 1000
    or v_installation_count > 200;
end;
$$;

revoke all on function public.check_prayer_push_sync_rate_limit(
  text, uuid, boolean
) from public, anon, authenticated;
grant execute on function public.check_prayer_push_sync_rate_limit(
  text, uuid, boolean
) to service_role;

-- Version the claim RPC instead of replacing its return type. This permits the
-- migration to be applied before the new dispatcher with no deployment gap.
create or replace function public.claim_due_prayer_pushes_v2(
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
  last_delivered_notification_id integer,
  last_delivered_scheduled_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  return query
  with due as (
    select p.installation_id
    from public.prayer_push_installations p
    where p.enabled = true
      and p.next_notification_at is not null
      and p.next_notification_at <= now()
      and (p.lease_until is null or p.lease_until <= now())
    order by p.next_notification_at
    for update skip locked
    limit least(greatest(coalesce(p_limit, 100), 1), 500)
  ),
  claimed as (
    update public.prayer_push_installations p
    set lease_until = now() + interval '3 minutes',
        updated_at = now()
    from due
    where p.installation_id = due.installation_id
    returning p.*
  )
  select
    c.installation_id,
    c.apns_token,
    c.apns_environment,
    c.bundle_id,
    c.local_coverage_until,
    c.next_event_index,
    c.failure_count,
    ((c.schedule -> 'events' -> c.next_event_index) ->> 0)::bigint,
    ((c.schedule -> 'events' -> c.next_event_index) ->> 1)::integer,
    (c.schedule -> 'events' -> c.next_event_index) ->> 2,
    (c.schedule -> 'content' -> (
      (c.schedule -> 'events' -> c.next_event_index) ->> 2
    )) ->> 'title',
    (c.schedule -> 'content' -> (
      (c.schedule -> 'events' -> c.next_event_index) ->> 2
    )) ->> 'body',
    c.last_delivered_notification_id,
    c.last_delivered_scheduled_at
  from claimed c;
end;
$$;

revoke all on function public.claim_due_prayer_pushes_v2(integer)
  from public, anon, authenticated;
grant execute on function public.claim_due_prayer_pushes_v2(integer)
  to service_role;

create or replace function public.advance_prayer_push(
  p_installation_id uuid,
  p_expected_event_index integer,
  p_apns_status integer default null,
  p_error text default null,
  p_delivered boolean default false,
  p_failure_count integer default 0
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_next_index integer;
  v_next_at timestamptz;
begin
  select
    (event.ordinality - 1)::integer,
    to_timestamp((event.value ->> 0)::bigint)
  into v_next_index, v_next_at
  from public.prayer_push_installations p
  cross join lateral jsonb_array_elements(p.schedule -> 'events')
    with ordinality as event(value, ordinality)
  where p.installation_id = p_installation_id
    and p.next_event_index = p_expected_event_index
    and event.ordinality - 1 > p_expected_event_index
    and to_timestamp((event.value ->> 0)::bigint) > greatest(
      coalesce(p.local_coverage_until, '-infinity'::timestamptz),
      now() - interval '60 seconds'
    )
  order by event.ordinality
  limit 1;

  update public.prayer_push_installations p
  set next_event_index = v_next_index,
      next_notification_at = v_next_at,
      lease_until = null,
      failure_count = case when p_delivered then 0 else p_failure_count end,
      last_delivery_at = case
        when p_delivered then now()
        else p.last_delivery_at
      end,
      last_delivered_notification_id = case
        when p_delivered
          then ((p.schedule -> 'events' -> p_expected_event_index) ->> 1)::integer
        else p.last_delivered_notification_id
      end,
      last_delivered_scheduled_at = case
        when p_delivered
          then to_timestamp(
            ((p.schedule -> 'events' -> p_expected_event_index) ->> 0)::bigint
          )
        else p.last_delivered_scheduled_at
      end,
      last_apns_status = p_apns_status,
      last_error = p_error,
      updated_at = now()
  where p.installation_id = p_installation_id
    and p.next_event_index = p_expected_event_index;
end;
$$;

revoke all on function public.advance_prayer_push(
  uuid, integer, integer, text, boolean, integer
) from public, anon, authenticated;
grant execute on function public.advance_prayer_push(
  uuid, integer, integer, text, boolean, integer
) to service_role;

commit;
