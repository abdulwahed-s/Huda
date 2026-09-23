import 'package:flutter_test/flutter_test.dart';
import 'package:huda/core/services/prayer_moment_resolver.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';

void main() {
  DateTime at(int hour, int minute, [int second = 0, int day = 1]) =>
      DateTime.utc(2026, 1, day, hour, minute, second);

  group('PrayerMomentResolver', () {
    final fajr = PrayerTransition(prayer: Prayer.fajr, instant: at(5, 0));
    final dhuhr = PrayerTransition(prayer: Prayer.dhuhr, instant: at(12, 30));

    test('counts down across a 7+ hour Fajr to Dhuhr gap', () {
      final moment = PrayerMomentResolver.resolve(
        now: at(5, 1),
        transitions: [fajr, dhuhr],
      )!;
      expect(moment.mode, PrayerMomentMode.elapsed);

      final afterGrace = PrayerMomentResolver.resolve(
        now: at(5, 30),
        transitions: [fajr, dhuhr],
      )!;
      expect(afterGrace.mode, PrayerMomentMode.countdown);
      expect(afterGrace.prayer, Prayer.dhuhr);
      expect(afterGrace.prayerInstant.difference(at(5, 30)).inHours, 7);
    });

    test('exact prayer boundary is +00:00', () {
      final moment = PrayerMomentResolver.resolve(
        now: at(5, 0),
        transitions: [fajr, dhuhr],
      )!;
      expect(moment.mode, PrayerMomentMode.elapsed);
      expect(moment.prayer, Prayer.fajr);
      expect(moment.prayerInstant, at(5, 0));
    });

    test(
      'every normal prayer transition observes the exact grace boundary',
      () {
        final transitions = [
          PrayerTransition(prayer: Prayer.fajr, instant: at(5, 0)),
          PrayerTransition(prayer: Prayer.dhuhr, instant: at(12, 10)),
          PrayerTransition(prayer: Prayer.asr, instant: at(15, 30)),
          PrayerTransition(prayer: Prayer.maghrib, instant: at(18, 20)),
          PrayerTransition(prayer: Prayer.isha, instant: at(20, 0)),
          PrayerTransition(prayer: Prayer.fajr, instant: at(5, 0, 0, 2)),
        ];
        for (final event in transitions.take(transitions.length - 1)) {
          expect(
            PrayerMomentResolver.resolve(
              now: event.instant.subtract(const Duration(seconds: 1)),
              transitions: transitions,
            )!.mode,
            PrayerMomentMode.countdown,
          );
          for (final elapsed in const [
            Duration.zero,
            Duration(seconds: 1),
            Duration(minutes: 24, seconds: 59),
          ]) {
            final moment = PrayerMomentResolver.resolve(
              now: event.instant.add(elapsed),
              transitions: transitions,
            )!;
            expect(moment.mode, PrayerMomentMode.elapsed);
            expect(moment.prayer, event.prayer);
          }
          expect(
            PrayerMomentResolver.resolve(
              now: event.instant.add(const Duration(minutes: 25)),
              transitions: transitions,
            )!.mode,
            PrayerMomentMode.countdown,
          );
        }
      },
    );

    test('+24:59 remains elapsed and +25:00 switches', () {
      expect(
        PrayerMomentResolver.resolve(
          now: at(5, 24, 59),
          transitions: [fajr, dhuhr],
        )!.mode,
        PrayerMomentMode.elapsed,
      );
      final switched = PrayerMomentResolver.resolve(
        now: at(5, 25),
        transitions: [fajr, dhuhr],
      )!;
      expect(switched.mode, PrayerMomentMode.countdown);
      expect(switched.prayer, Prayer.dhuhr);
    });

    test('most recently started prayer wins when gaps are under 25m', () {
      final moment = PrayerMomentResolver.resolve(
        now: at(10, 11),
        transitions: [
          PrayerTransition(prayer: Prayer.fajr, instant: at(10, 0)),
          PrayerTransition(prayer: Prayer.dhuhr, instant: at(10, 10)),
          PrayerTransition(prayer: Prayer.asr, instant: at(11, 0)),
        ],
      )!;
      expect(moment.mode, PrayerMomentMode.elapsed);
      expect(moment.prayer, Prayer.dhuhr);
      expect(moment.prayerInstant, at(10, 10));
    });

    test('Isha grace transitions to next-day Fajr', () {
      final isha = PrayerTransition(prayer: Prayer.isha, instant: at(20, 0));
      final tomorrowFajr = PrayerTransition(
        prayer: Prayer.fajr,
        instant: at(5, 0, 0, 2),
      );
      expect(
        PrayerMomentResolver.resolve(
          now: at(20, 24, 59),
          transitions: [isha, tomorrowFajr],
        )!.prayer,
        Prayer.isha,
      );
      expect(
        PrayerMomentResolver.resolve(
          now: at(20, 25),
          transitions: [isha, tomorrowFajr],
        )!.prayer,
        Prayer.fajr,
      );
      expect(
        PrayerMomentResolver.resolve(
          now: at(23, 59),
          transitions: [isha, tomorrowFajr],
        )!.prayerInstant,
        tomorrowFajr.instant,
      );
      expect(
        PrayerMomentResolver.resolve(
          now: at(0, 0, 0, 2),
          transitions: [isha, tomorrowFajr],
        )!.prayerInstant,
        tomorrowFajr.instant,
      );
    });
  });

  group('PrayerCountdownFormatter', () {
    test('uses signed H:MM:SS above an hour and MM:SS below it', () {
      expect(
        PrayerCountdownFormatter.formatSigned(
          const Duration(hours: 7, minutes: 9),
          elapsed: false,
        ),
        '−7:09:00',
      );
      expect(
        PrayerCountdownFormatter.formatSigned(
          const Duration(minutes: 59, seconds: 59),
          elapsed: false,
        ),
        '−59:59',
      );
      expect(
        PrayerCountdownFormatter.formatSigned(
          const Duration(minutes: 3, seconds: 20),
          elapsed: true,
        ),
        '+03:20',
      );
    });
  });
}
