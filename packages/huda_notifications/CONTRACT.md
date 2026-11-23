# Native prayer contract v1

Source of truth: `pigeons/prayer_notifications_api.dart`. Regenerate Dart and
Kotlin together with Pigeon 26.3.1. The Android runtime is application-scoped and
independent of messenger/Activity attachment. The Dart facade explicitly returns
`unsupportedPlatform` outside Android; standard/non-Android gateways keep their
existing contracts.

## Commands and acknowledgement

| Group | Commands | Meaning |
| --- | --- | --- |
| Discovery | `initialize`, `getSnapshot`, `getCapabilities`, `getPolicy` | Negotiate version 1; read actual durable state and public capability observations. Initialization requests future repair. |
| Policy | `setPolicy(policy, expectedRevision)` | Validate the complete policy and ready audio selection, then durably CAS before acknowledgement. A stale caller must re-read and reapply only its own edit. |
| Capacity | `updateQuota` | Publish plugin inventory and conservative external reservations; return the available prayer budget. |
| Plans | `preparePlan`, `getPlanReceipt`, `activatePlan`, `finalizePlan`, `abortPlan` | Recoverable native transaction while Dart holds its durable file lock. Activation precedes Dart application commit; finalization follows it. |
| Migration | `getLegacyInventory`, `suppressUnmappedLegacy`, `acknowledgeLegacyCleanup` | Inspect actual FLN cache metadata; disable known safe unmapped rows; acknowledge durable plugin cancellation before continuing transfer. |
| History | `getDeliveryHistory`, `acknowledgeHistory` | Cursor-based canonical outcomes. Dart saves imported suppression records before acknowledging. Ack does not delete canonical claims. |
| Cancellation | `cancelOccurrences`, `resetPrayerBackend` | Generation-checked scoped cancellation, or deliberate app/prayer reset. History reset is explicit. |
| Rollback | `beginRollback`, `completeRollback` | Checkpoint native cancellation, return compatible future events, verify durable legacy installation and transfer ownership. |
| Assets | `getAudioStorage`, `isAudioReady`, `registerVerifiedAudio`, `removeUnreferencedAudio` | Private staging roots and atomic immutable paired manifests; selection/active pinning prevents cleanup races. |
| Reminders | `applyReminders`, `getReminders`, `takeReminderTap` | App-owned reminders as `ReminderData` rules (`once`, `daily`, `weekly`, `interval`). A batch cancels first, then schedules; it returns the IDs not accepted. Repeats re-arm natively; `takeReminderTap` returns a tapped reminder's payload once. |
| Foreground controls | `startPreview`, `stopPreview`, `runDeliveryTest`, `setSessionGain`, `openAlarmOverview`, `openSettings`, `requestNotificationPermission` | Require an attached Activity where applicable. Preview/test never use a real prayer identity. |
| Native controls | `stopSession`, `dismissSession` | Name a session; stale identities are harmless. Automatic playback survives Flutter detachment. |

Native work returns structured `FlutterError(code, message, details)` with a
`recoverable` hint. Typical codes include `unsupportedContract`, `invalidPolicy`,
`stalePolicy`, `invalidPlan`, `stalePlan`, `quotaExceeded`, `deadlineProtected`,
`migrationRecoveryRequired`, `registrationFailed`, `registrationIncomplete`,
`rollbackInProgress`, `unsupportedRollbackPolicy`, `userLocked`,
`assetUnavailable`, `invalidAssetHash`, `invalidAssetDuration`,
`immutableAssetConflict`, `activityUnavailable`, `exactAccessDenied`,
`notificationsBlocked` and `storageUnavailable`. Do not fall back to FLN when a
native operation fails. Unknown platform/storage errors remain recoverable and
retain the last known ownership/checkpoint.

## Policy

`PolicyData` contains `schemaVersion: 1`, native monotonically increasing
`revision`, and `values`. Unknown keys/schema versions are rejected. Global
defaults:

```json
{
  "enabled": true,
  "defaultMode": "full",
  "reciterId": "huda-default",
  "audioVersion": "v1",
  "volumeGain": 1.0,
  "fadeInSeconds": 0,
  "stopAfterSeconds": null,
  "alarmScreenEnabled": true,
  "flipToStopEnabled": false,
  "respectRingerMode": false,
  "respectDoNotDisturb": true,
  "vibrate": true,
  "stopOnHeadsetDisconnect": true,
  "showNextPrayer": true,
  "showMissedSummary": false,
  "followUpEnabled": false,
  "localeCode": "en",
  "advanceMinutes": 0,
  "perPrayer": {}
}
```

Global modes are `full`, `short`, `silent`. Master disabled resolves every prayer
to `off`. `perPrayer` permits only `fajr`, `dhuhr`, `asr`, `maghrib`, `isha`; each
entry is sparse. Override keys are `mode` (including `off`), `reciterId`,
`audioVersion`, `volumeGain`, `fadeInSeconds`, `stopAfterSeconds`,
`alarmScreenEnabled`, `flipToStopEnabled`, `vibrate`, `advanceMinutes` (0, 5,
10, 15 or 30; 0 is no reminder before the prayer). Inherit/reset removes keys,
not copies of global defaults. Native overrides contain no null values; the Dart
edit helper interprets null as removal. Gain is finite 0–1; fade is integer
0–30 seconds; cutoff is null or integer 1–3600 seconds. IDs match
`^[a-z0-9]+(?:-[a-z0-9]+)*$`; versions match `^v[1-9][0-9]*$`.

Only enabled/Off eligibility changes enter the Android timestamp configuration
signature. Gain applies to active playback; cutoff can shorten it. Off/Silent
stop automatic active audio. Reciter/length/fade and other interaction changes
apply to a subsequent session. Ringer respect can be enabled explicitly; DND
respect is always true. Selecting Silent in the UI sets vibration false until
the user changes it.

## Identity and plan transaction

`EventData` carries canonical ID, prayer, UTC milliseconds, accepted IANA zone,
civil date, localized title/body and an optional compatible schema-3 payload.
Canonical IDs remain:

```text
300000000 + (YYYYMMDD - 20000000) * 10 + prayerIndex
prayerIndex: fajr=1, dhuhr=2, asr=3, maghrib=4, isha=5
```

`PlanRequest` freezes operation ID, expected active generation and policy
revision, location/schedule revisions, SHA-256 configuration/event digests,
eligibility signature, quota, desired events, imported suppression history and
verified legacy aliases. Events must be unique, valid, future-only and within
60 days. Input dates around that horizon include a seven-day margin for accepted
manual offsets; this does not extend the UTC delivery horizon.

`PlanReceipt` carries epoch/source identity, actual generation, per-event token,
precision (`exact`, `inexact`, `unknown`), registration outcome, coverage boundary,
cleanup IDs and error. States include `preparing`, `deferred`, `failed`,
`prepared`, `activated`, `finalized`, `aborted`, `rollingBack`.

1. Dart locks its authoritative reliability file and writes an immutable journal.
2. Native preparation persists stripped requests/events before OS registration.
   Legacy transfer is incremental with a durable cleanup acknowledgement between
   each overlap. A different operation cannot abandon unacknowledged cleanup or
   an unclaimed due window. Invalid/stale requests do not abort a valid preparation.
3. Activation checks complete registrations/claims and eligibility, then changes
   ownership and publishes the native root. Dart commits its application journal.
4. Finalization flushes accepted CE configuration, then publishes the matching DP
   source generation. The accepted user's event instants must also pass native
   parity before autonomous renewal is permitted. Failed parity clears any older
   marker for the same digest and leaves explicit finite/degraded coverage.

Retained unchanged events keep installed tokens and their own row generation.
New generations exceed both the active root and any partially persisted worker
rows. A native worker cannot renew during another preparation or from staged,
unfinalized, guessed, widget-display or stale configurations. Worker extensions
retain the accepted source schedule revision; Dart adopts actual native receipts
instead of fabricating new payload acknowledgements.

Room cannot commit atomically with AlarmManager. Registration failure and
interrupted activation use stored checkpoints, owner/claim checks and repair.
Receipts describe acknowledged registration operations, not an OS inventory.

## Claims, sessions and repair

Both callback paths atomically check ownership and insert a unique claim by
canonical ID. Unknown legacy metadata fails closed after strict cutover begins.
Clearly classified standard/calendar reminders bypass the prayer claim gate.
Native tokens must match epoch, occurrence, purpose, registration and owner.
Early native callbacks re-register the original instant; early legacy callbacks
retain/restore the original durable cache row.

Claims record received UTC time, intended UTC time, source revisions, backend,
outcome/reason and session ID. `attempted`/`started` never prove audible output.
`uncertain`/process interruption prevents automatic replay. Silent, missed,
suppressed, failed and stopped outcomes also remain canonical suppression records.
Delivery outcomes can advance their cursor; acknowledgement preserves claims.

Automatic audio requires app/Adhan-channel permission, exact precision/access,
ringer policy, observable DND alarm allowance and nonzero alarm stream/player
gain. Unknown DND priority policy suppresses conservatively. Inexact callbacks
produce quiet notifications. Audio starts only within 120 seconds of its intended
instant. A foreground media service promotes before focus/file preparation and
uses `START_NOT_STICKY`. One scheduled session preempts preview/older playback;
older callbacks cannot preempt a newer occurrence. All Stop/flip/actions are
session-scoped. Preview is Activity-bound and has no canonical claim or FGS.

System broadcasts restore future work only. Locked boot opens DP state/audio and
does not initialize CE configuration/WorkManager or start playback. A normal
resume/worker preserves the grace window of an original dispatched callback;
system repair records elapsed occurrences without playing a backlog. Time moves
backward cannot resurrect consumed claims. Native renewal is unique ordinary
12-hour work plus a bounded five-event after-delivery append; it has no network
constraint and honors the acknowledged/current quota.

FGS ID is `410000001`; preview `410000002`; synthetic test `410000003`;
`410000010`–`410000012` were follow-ups (removed). Reminders before a prayer
use the prayer ID + `140000000`. Native summaries use tag `huda.native.prayer`.
Channels are `huda_prayer_silent_v1`, `huda_prayer_adhan_v1` and
`huda_prayer_status_v1`, all acoustically silent, and `huda_prayer_before_v1`
(reminders before a prayer, the channel's default sound).
`huda_prayer_followup_v1` is deleted at startup.
New Android calendar IDs use a separate `420000000` namespace and typed payloads.

## Concurrency, privacy and recovery boundaries

Lock order is Dart durable file lock → native maintenance queue → short Room
transaction. Delivery/control have a separate queue and main-looper controls;
asset hashing/promotion has an audio I/O queue. No Room transaction crosses an
AlarmManager or Flutter call. Asset selection/cleanup share an asset lock before
their short Room transaction. The runtime retains application context, never an
Activity/engine; adapters unregister their own listeners on detach.

DP state stores hashes, minimal event labels, tokens, policy, owners, claims and
bounded redacted diagnostic entries. Raw coordinates/signatures/schema-3 payloads
remain in CE companions. Rollback's DP checkpoint also strips payloads and
reconstructs compatibility data only after unlock. The shared schema starts at
Room version 1; every future schema change requires an explicit tested migration.

`RuntimeSnapshot` includes policy/capabilities, actual future owned registrations,
active/preparing receipts, session, latest canonical outcomes, repair reason and
navigation token. The EventChannel at
`com.aw.huda/prayer_notifications/events` supplies advisory type, runtime-instance
and sequence hints. Clients refresh full snapshots/history on reconnect/resume;
no delivery relies on receiving an event. Navigation tokens are deduplicated.

Rollback durably disables native owners before cancelling OS work and verifies
compatible future registrations from the original FLN cache before enabling
legacy ownership. It keeps canonical claims. Unsupported legacy playback policies
are rejected before mutation; see [README.md](README.md). Binary downgrades do
not participate in this contract.
