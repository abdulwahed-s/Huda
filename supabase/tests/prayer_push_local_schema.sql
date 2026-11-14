-- Minimal existing installation schema for isolated PostgreSQL regression
-- tests. This fixture is not a production migration.
create schema extensions;
create extension pgcrypto with schema extensions;
do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated; end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then create role service_role; end if;
end $$;
create table public.prayer_push_installations (
  installation_id uuid primary key,
  installation_secret_hash text not null,
  apns_token text not null,
  apns_environment text not null,
  bundle_id text not null,
  app_version text,
  time_zone text not null,
  configuration_signature text not null,
  local_coverage_until timestamptz,
  schedule_through timestamptz not null,
  schedule jsonb not null,
  next_event_index integer,
  next_notification_at timestamptz,
  lease_until timestamptz,
  failure_count integer not null default 0,
  last_apns_status integer,
  last_error text,
  enabled boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
