List<DateTime> missingAthkarTimes({
  required DateTime now,
  required Duration interval,
  required Duration horizon,
  required int capacity,
  required Iterable<DateTime> existing,
}) {
  if (interval <= Duration.zero || capacity < 0) {
    throw ArgumentError('Athkar interval and capacity must be positive');
  }
  final end = now.add(horizon);
  final futureAll = existing.where((time) => time.isAfter(now)).toSet().toList()
    ..sort();
  final future = futureAll.where((time) => time.isBefore(end));
  final missing = <DateTime>[];
  var cursor = now.add(interval);
  var remaining = capacity - futureAll.length;
  if (remaining <= 0) return missing;

  for (final scheduled in future) {
    while (remaining > 0 &&
        cursor.isBefore(scheduled.subtract(const Duration(minutes: 1)))) {
      missing.add(cursor);
      remaining--;
      cursor = cursor.add(interval);
    }
    cursor = scheduled.add(interval);
  }
  while (remaining > 0 && cursor.isBefore(end)) {
    missing.add(cursor);
    remaining--;
    cursor = cursor.add(interval);
  }
  return missing;
}
