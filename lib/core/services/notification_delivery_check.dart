/// The system did not accept a reminder the user switched on.
class NotificationNotScheduledException implements Exception {
  const NotificationNotScheduledException(this.id);

  final int id;

  @override
  String toString() => 'Notification $id is not pending at the system level.';
}
