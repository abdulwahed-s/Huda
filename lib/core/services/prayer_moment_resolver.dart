import 'package:prayer_time_plus/prayer_time_plus.dart';

enum PrayerMomentMode { countdown, elapsed }

class PrayerTransition {
  const PrayerTransition({required this.prayer, required this.instant});

  final Prayer prayer;
  final DateTime instant;
}

class PrayerMoment {
  const PrayerMoment({
    required this.mode,
    required this.prayer,
    required this.prayerInstant,
    required this.stateEnd,
  });

  final PrayerMomentMode mode;
  final Prayer prayer;
  final DateTime prayerInstant;
  final DateTime stateEnd;

  bool get isElapsed => mode == PrayerMomentMode.elapsed;
}

abstract final class PrayerMomentResolver {
  static const Duration gracePeriod = Duration(minutes: 25);

  static PrayerMoment? resolve({
    required DateTime now,
    required Iterable<PrayerTransition> transitions,
    Duration grace = gracePeriod,
  }) {
    final nowUtc = now.toUtc();
    final ordered =
        transitions
            .map(
              (transition) => PrayerTransition(
                prayer: transition.prayer,
                instant: transition.instant.toUtc(),
              ),
            )
            .toList()
          ..sort((left, right) => left.instant.compareTo(right.instant));

    PrayerTransition? latestStarted;
    for (final transition in ordered) {
      if (transition.instant.isAfter(nowUtc)) break;
      latestStarted = transition;
    }

    if (latestStarted != null) {
      final graceEnd = latestStarted.instant.add(grace);
      if (nowUtc.isBefore(graceEnd)) {
        return PrayerMoment(
          mode: PrayerMomentMode.elapsed,
          prayer: latestStarted.prayer,
          prayerInstant: latestStarted.instant,
          stateEnd: graceEnd,
        );
      }
    }

    for (final transition in ordered) {
      if (transition.instant.isAfter(nowUtc)) {
        return PrayerMoment(
          mode: PrayerMomentMode.countdown,
          prayer: transition.prayer,
          prayerInstant: transition.instant,
          stateEnd: transition.instant,
        );
      }
    }
    return null;
  }
}

abstract final class PrayerCountdownFormatter {
  static String formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final minuteText = minutes.toString().padLeft(2, '0');
    final secondText = seconds.toString().padLeft(2, '0');
    return hours > 0
        ? '$hours:$minuteText:$secondText'
        : '$minuteText:$secondText';
  }

  static String formatSigned(Duration duration, {required bool elapsed}) =>
      '${elapsed ? '+' : '−'}${formatDuration(duration)}';
}
