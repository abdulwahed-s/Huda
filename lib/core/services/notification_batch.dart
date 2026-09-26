import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> cancelNotificationIds(
  FlutterLocalNotificationsPlugin plugin,
  Iterable<int> ids,
) async {
  final uniqueIds = ids.toSet().toList(growable: false);
  if (uniqueIds.isEmpty) return;

  for (final id in uniqueIds) {
    await plugin.cancel(id: id);
  }
}
