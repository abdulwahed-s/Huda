-- Durable per-installation retirement. Deploy before releasing native iOS
-- ownership; legacy clients remain supported until they migrate themselves.
begin;

create table if not exists public.prayer_push_retirements (
  installation_id uuid primary key,
  installation_secret_hash text not null,
  retired_at timestamptz not null default now(),
  native_not_before timestamptz not null,
  schedule_revision bigint not null,
  location_revision bigint not null,
  check (schedule_revision between 0 and 9007199254740991),
  check (location_revision between 0 and 9007199254740991)
);
alter table public.prayer_push_retirements enable row level security;
revoke all on public.prayer_push_retirements from public, anon, authenticated;
grant all on public.prayer_push_retirements to service_role;

create or replace function public.enforce_prayer_push_retirement()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.enabled and exists (
    select 1 from public.prayer_push_retirements r
    where r.installation_id = new.installation_id
  ) then
    raise exception 'prayer push installation retired' using errcode = '23514';
  end if;
  return new;
end;
$$;
drop trigger if exists prayer_push_retirement_fence on public.prayer_push_installations;
create trigger prayer_push_retirement_fence before insert or update
on public.prayer_push_installations for each row execute function public.enforce_prayer_push_retirement();

create or replace function public.retire_prayer_push_installation(
  p_installation_id uuid, p_installation_secret_hash text,
  p_location_revision bigint, p_schedule_revision bigint
) returns table (
  status text, accepted_schedule_revision bigint, accepted_location_revision bigint,
  native_not_before timestamptz
) language plpgsql security definer set search_path = '' as $$
declare
  v_existing public.prayer_push_installations%rowtype;
  v_retirement public.prayer_push_retirements%rowtype;
  v_boundary timestamptz;
  v_latest_delivery timestamptz;
begin
  if p_location_revision is null or p_location_revision not between 0 and 9007199254740991
     or p_schedule_revision is null or p_schedule_revision not between 0 and 9007199254740991
     or p_installation_secret_hash is null or p_installation_secret_hash !~ '^[a-f0-9]{64}$' then
    return query select 'invalid_revision', 0::bigint, 0::bigint, null::timestamptz;
    return;
  end if;
  -- Shared with every existing sync/disable RPC, so an in-flight enrollment
  -- cannot commit after this acknowledgement and restore server ownership.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('prayer-installation:' || p_installation_id::text, 0));
  select * into v_existing from public.prayer_push_installations
    where installation_id = p_installation_id for update;
  if found and v_existing.installation_secret_hash <> p_installation_secret_hash then
    return query select 'invalid_installation', 0::bigint, 0::bigint, null::timestamptz;
    return;
  end if;
  select * into v_retirement from public.prayer_push_retirements
    where installation_id = p_installation_id for update;
  if found then
    if v_retirement.installation_secret_hash <> p_installation_secret_hash then
      return query select 'invalid_installation', 0::bigint, 0::bigint, null::timestamptz;
    else
      return query select 'retired', v_retirement.schedule_revision,
        v_retirement.location_revision, v_retirement.native_not_before;
    end if;
    return;
  end if;
  -- APNs already authorized before retirement can finish in flight. Its
  -- expiration is prayer instant + ten minutes. Preserve the old local
  -- alerts within this boundary and create native alerts only after it.
  select max(pg_catalog.to_timestamp(l.event_epoch))
    into v_latest_delivery from public.prayer_push_occurrence_ledger l
    where l.installation_id = p_installation_id
      and l.disposition in ('authorized', 'accepted', 'uncertain');
  -- A new native-first installation has no previous push to drain. Give it
  -- immediate ownership so a prayer in the next ten minutes is not omitted.
  -- Absent legacy installations still retain the conservative drain window.
  if v_existing.installation_id is null and v_latest_delivery is null
     and p_location_revision = 0 and p_schedule_revision = 0 then
    v_boundary := now();
  else
    v_boundary := greatest(now(), v_latest_delivery) + interval '10 minutes';
  end if;
  insert into public.prayer_push_retirements (
    installation_id, installation_secret_hash, native_not_before, schedule_revision, location_revision
  ) values (p_installation_id, p_installation_secret_hash, v_boundary,
    greatest(p_schedule_revision, coalesce(v_existing.schedule_revision, 0)),
    greatest(p_location_revision, coalesce(v_existing.location_revision, 0)))
    returning * into v_retirement;
  perform pg_catalog.set_config('huda.prayer_push_fenced_write', '1', true);
  update public.prayer_push_installations set enabled = false,
    next_notification_at = null, next_event_index = null, lease_token = null,
    claimed_schedule_revision = null, claimed_event_index = null,
    claimed_notification_id = null, claimed_event_epoch = null,
    claim_authorized_at = null, lease_until = null, updated_at = now()
    where installation_id = p_installation_id;
  return query select 'retired', v_retirement.schedule_revision,
    v_retirement.location_revision, v_retirement.native_not_before;
end;
$$;
revoke all on function public.retire_prayer_push_installation(uuid, text, bigint, bigint)
  from public, anon, authenticated;
grant execute on function public.retire_prayer_push_installation(uuid, text, bigint, bigint) to service_role;
commit;
