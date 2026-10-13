# Huda Android notifications (huda_notifications)

App-owned Android alarms, offline Adhan playback, native controls and execution
history. Scheduled delivery does not require a Flutter engine, network, widget or
location lookup. Flutter remains authoritative for accepted location and initial
calculation settings. Islamic reminders, random Athkar and calendar events are
app-owned here too (see "Reminders" below). Compatibility code reads and delivers
alarms stored by earlier installations of `flutter_local_notifications`; the app
no longer depends on that plugin.

The native backend is enabled for Android.

The prayer page exposes global and per-prayer Full, Short, Silent and Off,
verified reciter downloads, player gain, fade, cutoff, vibration, ringer respect,
optional alarm overview/flip, preview, a synthetic ten-second test and Stop.
The alarm screen and flip default off. DND remains respected. Silent selection
defaults vibration off in the picker; it can be enabled explicitly.

## Package layout

- `pigeons/prayer_notifications_api.dart`: contract source, version 1.
- `lib/src/prayer_api.g.dart` and Android `PrayerApi.g.kt`: generated together.
- `lib/src/platform_api.dart`: Android-only facade and advisory EventChannel.
- Android `PrayerNotificationRuntime`: application singleton, queues, policy,
  snapshots, history, quota and recovery.
- `PrayerPlanCoordinator` / `PrayerAlarmScheduler`: durable plan transactions,
  ownership, immutable PendingIntents, migration and repair.
- `PrayerAlarmReceiver` / `AdhanPlaybackService`: once-only automatic attempts,
  exact-alarm eligibility and prompt media foreground service promotion.
- `AdhanSessionCoordinator` / `AdhanAudioController`: session ordering, foreground
  preview, local MediaPlayer, focus, gain, cutoff and unified cleanup.
- `AdhanAlarmActivity` / `PrayerActionReceiver` / `FlipToStopController`: controls
  independent of Flutter; stale session actions cannot target newer playback.
- `PrayerAudioStore`: private device-protected, verified, immutable paired assets.
- `PrayerSystemReceiver` / `PrayerCoverageRenewalWorker`: future-only recovery
  and ordinary offline renewal from finalized accepted configuration.
- `android/prayer_core` in the application: pure calculator/identity module also
  used by the widget adapter.

See [CONTRACT.md](CONTRACT.md) for field names, states, queue order and errors.

## Reminders

`ReminderScheduler` owns Islamic reminders, random Athkar and calendar events
for Huda's notification orchestrator (`lib/core/notifications/`):

- **One alarm per reminder.** Daily and weekly reminders re-arm after every
  delivery in the device's current time zone, so they follow travel. Random
  Athkar are one interval alarm that picks its text when it fires. Calendar
  events are one-time alarms.
- **Precision.** Fixed-time reminders use exact alarms when allowed. Athkar use
  inexact alarms, so Android can batch them and save battery.
- **Storage.** Rules live in the existing state table under `reminder:<id>`, with
  the last delivered occurrence under `reminderDelivered:<id>`. No schema change
  was needed.
- **Repair.** `PrayerSystemReceiver` repairs reminders with prayers after
  reboot, update, time or time-zone change:
  - a delivery missed while the device was off is still shown within its late
    window (1 hour for repeats, 12 hours for one-time events, one interval for
    Athkar);
  - a delivered occurrence is never repeated, even when the clock moves back.
- **Capacity.** Reminders count against the shared 450-alarm budget, alongside
  plugin reminders.
- **Reset.** An app-wide `resetPrayerBackend` cancels them.
- **Taps.** A tapped reminder launches Huda with its payload. The plugin keeps it
  for `takeReminderTap`, and Dart opens the matching page.

## Storage and limits

Room schema 1 is exported in `android/schemas`. It opens in device-protected
storage, has no destructive fallback and permits no main-thread queries. Its
execution records contain digests and revisions, not coordinates, raw
configuration signatures or compatible schema-3 payloads. Accepted calculation
JSON/signatures and payload companions use credential-protected `noBackupFilesDir`
with atomic writes. Initialization before first unlock does not open those files
or WorkManager.

Automatic claims retain canonical suppression for 400 days, including uncertain
attempts. Detailed redacted traces retain at most 200 entries for seven days.
Inactive plan/request receipts expire after 30 days; active and preparing
operations remain protected. No automatic diagnostic upload exists.
The application excludes execution databases, sidecars and downloaded native
audio from both cloud backup and device transfer. Restored Dart receipts are
checked against the new installation epoch and cannot prove installed alarms.

Initial limits are 60 days, 300 prayers and 450 shared planning slots, less
standard-reminder inventory and reservations for Sahur (30), widgets (8),
auxiliary alarms (4) and migration overlap (1). Prayer advance reminders reserve
up to 70 slots for their 14-day window when enabled. Stored registrations describe acknowledged
application operations; Android provides no general inventory API proving every
AlarmManager alarm remains installed.

Full/Short use silent notification channels and an independent player with alarm
audio attributes. Player gain never writes system alarm volume, ringer or DND.
Inexact prayer alarms deliver notifications only. The automatic lateness window
and migration protection window are both 120 seconds. Direct Boot/system repair
does not replay past audio. Ordinary resume repair leaves an already dispatched
callback's grace window available for its original once-only claim.

All five published full MP3 / short PCM WAV pairs have been downloaded, hashed
and decoded by the validation tool. Android's bundled `azan_sound.ogg` is **Opus**,
1,346,905 bytes, 204,446 ms, SHA-256
`4e2fba3996f216b650888f1f556ac5f77a1f56e8c303510aed9070f5d5b2810b`.
Bundled Short uses a 30-second cutoff. The Windows bundled MP3 descriptor is
separate. Delivery never downloads or rehashes a whole asset; failed preparation
can fall back once locally, preserving the Short/cutoff bound.

## Migration from plugin alarms

`LegacyPluginAlarms` reads the stored `flutter_local_notifications` alarm cache
and preserves the receiver class used by existing alarms. `LegacyPrayerDeliveryBridge`
recognizes prayer metadata, imports verified aliases and shares the atomic
occurrence claim. Calendar notifications bypass the prayer gate even when an
old ID overlaps a prayer range.

Obsolete legacy slots are cleaned before new allocation. Each overlapping
transfer waits for durable legacy alarm cancellation before the next transfer.
Near-due legacy work defers cutover. A protected legacy Short produces a quiet
summary instead of playing the legacy full recording.

An app-wide reset stops playback and cancels native prayers, reminders and test
work; it preserves claims by default. Reset does not opt an untouched legacy
installation into native ownership. Calendar/Athkar refreshes use scoped
cancellation.

## Development and verification

Generate both bridge languages from this package:

```sh
flutter pub get
dart run pigeon --input pigeons/prayer_notifications_api.dart
flutter test
```

From the application root:

```sh
flutter test test/core/services/android_prayer_experience_test.dart \
  test/core/services/android_prayer_scheduler_transaction_test.dart \
  test/presentation/widgets/prayer_times/android_prayer_experience_card_test.dart
python3 tool/athan/validate_android_audio_catalog.py
python3 tool/athan/inspect_android_adhan_release.py --flavor all
```

Use Java 17 for Gradle. In `android/`, run:

```sh
bash gradlew --no-parallel --max-workers=1 \
  :huda_notifications:testDebugUnitTest \
  :prayer_core:testDebugUnitTest \
  :huda_notifications:assembleDebugAndroidTest
bash gradlew :huda_notifications:connectedDebugAndroidTest
```

The second command requires a device. The instrumentation APK tests real SQLite
claims across two database clients/reopen. JVM tests use Robolectric API 28;
those results do not establish Doze, FGS, audible output, screen-off sensors,
locked-boot or API 35–37 policy behavior. Keep release/R8 field and WorkManager
class-name rules when changing the versioned persistent schema.
