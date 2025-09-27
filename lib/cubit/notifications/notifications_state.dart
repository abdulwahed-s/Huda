part of 'notifications_cubit.dart';

@immutable
sealed class NotificationsState {}

final class NotificationsInitial extends NotificationsState {}

class NotificationPreferencesLoaded extends NotificationsState {
  final bool kahfFriday;
  final bool randomAthkar;
  final bool sabahMasaa;
  final bool quranReminder;
  final bool checklistReminder;
  final String quranReminderTime;
  final String checklistReminderTime;
  final int randomAthkarFrequency;

  final String kahfFridayTime;
  final String morningAthkarTime;
  final String eveningAthkarTime;

  NotificationPreferencesLoaded({
    required this.kahfFriday,
    required this.randomAthkar,
    required this.sabahMasaa,
    required this.quranReminder,
    required this.quranReminderTime,
    required this.randomAthkarFrequency,
    this.kahfFridayTime = '09:00',
    this.morningAthkarTime = '07:00',
    this.eveningAthkarTime = '18:00',
    this.checklistReminder = false,
    this.checklistReminderTime = '20:00',
  });
}
