\set ON_ERROR_STOP on
begin;
do $$
declare
  v_id uuid := '00000000-0000-4000-8000-000000000001';
  v_new uuid := '00000000-0000-4000-8000-000000000002';
  v_hash text := repeat('a', 64);
  v_epoch bigint := extract(epoch from now())::bigint - 1;
  v_schedule jsonb;
  v_result record;
  v_claim record;
  v_boundary timestamptz;
  v_rejected boolean := false;
begin
  v_schedule := jsonb_build_object('events', jsonb_build_array(jsonb_build_array(v_epoch, 302610111, 'fajr')),
    'content', jsonb_build_object('fajr', jsonb_build_object('title', 'Fajr', 'body', 'Prayer time')));
  select * into v_result from public.sync_prayer_push_installation_v2(v_id, v_hash, repeat('ab', 32),
    'development', 'com.aw.huda', 'test', 'Asia/Muscat', 'test:1', null, now() + interval '1 day',
    v_schedule, 0, now() - interval '1 second', 1, 1);
  assert v_result.status = 'accepted', 'setup enrollment failed';
  select * into v_claim from public.claim_due_prayer_pushes_v3(10) where installation_id = v_id;
  assert v_claim.lease_token is not null, 'claim not acquired';
  assert public.authorize_prayer_push_delivery(v_id, 1, v_claim.lease_token, 302610111, v_epoch), 'claim not authorized';
  select * into v_result from public.retire_prayer_push_installation(v_id, repeat('b', 64), 1, 1);
  assert v_result.status = 'invalid_installation', 'wrong secret retired an installation';
  assert not exists(select 1 from public.prayer_push_retirements where installation_id = v_id), 'unauthorized tombstone';
  select * into v_result from public.retire_prayer_push_installation(v_id, v_hash, 1, 1);
  assert v_result.status = 'retired', 'retirement failed';
  v_boundary := v_result.native_not_before;
  assert v_boundary >= now() + interval '10 minutes', 'APNs drain boundary missing';
  assert (select not enabled and next_notification_at is null and lease_token is null
    from public.prayer_push_installations where installation_id = v_id), 'server still owns retired installation';
  assert not public.authorize_prayer_push_delivery(v_id, 1, v_claim.lease_token, 302610111, v_epoch), 'stale worker remains authorized';
  assert not public.settle_prayer_push_claim(v_id, 1, v_claim.lease_token, 302610111, v_epoch,
    'accepted', 200, null, 0, null), 'stale worker completion mutated retirement';
  select * into v_result from public.retire_prayer_push_installation(v_id, v_hash, 1, 999);
  assert v_result.status = 'retired' and v_result.native_not_before = v_boundary, 'retry changed durable boundary';
  begin
    perform public.sync_prayer_push_installation_v2(v_id, v_hash, repeat('ab', 32),
      'development', 'com.aw.huda', 'old-retry', 'Asia/Muscat', 'test:2', null, now() + interval '1 day',
      v_schedule, 0, now(), 2, 2);
  exception when check_violation then v_rejected := true;
  end;
  assert v_rejected, 'newer retry resurrected retired installation';
  select * into v_result from public.retire_prayer_push_installation(v_new, v_hash, 0, 0);
  assert v_result.status = 'retired', 'absent installation needs a durable tombstone';
  assert v_result.native_not_before = now(), 'fresh installation unnecessarily skips imminent prayers';
  assert not exists(select 1 from public.prayer_push_installations where installation_id = v_new), 'retirement enrolled a new push';
  v_rejected := false;
  begin
    perform public.sync_prayer_push_installation_v2(v_new, v_hash, repeat('cd', 32),
      'development', 'com.aw.huda', 'delayed-first-sync', 'Asia/Muscat', 'test:1', null, now() + interval '1 day',
      v_schedule, 0, now(), 1, 1);
  exception when check_violation then v_rejected := true;
  end;
  assert v_rejected, 'delayed first sync enrolled a retired installation';
  raise notice 'Native prayer retirement: credentials, in-flight claims, durable retries and absent-row tombstones passed';
end $$;
rollback;
