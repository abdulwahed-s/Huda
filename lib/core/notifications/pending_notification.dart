/// A notification the system holds, as a platform lists it.
class PendingNotification {
  const PendingNotification(this.id, this.title, this.body, this.payload);

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}
