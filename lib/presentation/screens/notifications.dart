import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/services/ios_prayer_bridge.dart';
import 'package:huda/core/services/notification_delivery_check.dart';
import 'package:huda/core/services/sahur_alarm_gateway.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/hijri_date_utils.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/notifications/notification_access_controller.dart';
import 'package:huda/presentation/widgets/notifications/notification_requirements_section.dart';
import 'package:huda/presentation/widgets/notifications/permission_handlers.dart';
import 'package:huda/presentation/widgets/notifications/reminder_delivery_section.dart';
import 'package:huda/presentation/widgets/notifications/reminder_row.dart';
import 'package:huda/presentation/widgets/notifications/reminder_sheets.dart';
import 'package:huda/presentation/widgets/notifications/reminders_identity.dart';
import 'package:huda/presentation/widgets/design/huda_time_picker.dart';
import 'package:intl/intl.dart' as intl;

extension NotificationContextExtension on BuildContext {
  Future<void> togglePreference(String key, bool value) async {
    final cubit = read<NotificationsCubit>();
    await cubit.togglePreference(key, value);
  }
}

/// The reminders screen. The day dial at the top shows when today's
/// reminders fire and what comes next; under it whatever access is still
/// needed, then the reminders by theme (Athkar, Quran, daily routine), each
/// with its switch and its times as chips, then "Check delivery".
///
/// Phones: one column. Medium windows: one column with the reminders two
/// to a row. From 840 wide and on open folds: the overview (dial, access,
/// delivery) beside the reminders. Tabletop: the dial above the band, the
/// reminders below it.
class Notifications extends StatefulWidget {
  const Notifications({
    super.key,
    this.debugAccess,
    this.debugClock,
    this.debugSahur,
    this.debugIosStatus,
  });

  /// Notification access without the platform, for the device matrix.
  @visibleForTesting
  final NotificationAccessController Function(
    NotificationsCubit cubit,
    Future<void> Function() onAccessGained,
  )?
  debugAccess;

  /// A fixed "now" for the device matrix.
  @visibleForTesting
  final DateTime Function()? debugClock;

  /// Shows the Sahur alarm off a phone (the matrix runs on the desktop).
  @visibleForTesting
  final bool? debugSahur;

  /// The iOS alarm and notification state, as if on an iPhone.
  @visibleForTesting
  final IOSPrayerStatus Function()? debugIosStatus;

  @override
  State<Notifications> createState() => _NotificationsState();
}

/// A reminder's preference key, and what's shown for it.
enum _Reminder {
  athkar('sabahMasaa'),
  random('randomAthkar'),
  quran('quranReminder'),
  kahf('kahfFriday'),
  sahur('sahurAlarmEnabled'),
  checklist('checklistReminder');

  const _Reminder(this.key);
  final String key;
}

class _NotificationsState extends State<Notifications> {
  late final NotificationAccessController _access;

  /// Keys whose last scheduling failed, with what Retry runs.
  final Map<String, Future<void> Function()> _failed = {};

  /// Why a key failed and the fix its action runs, when it's known.
  final Map<String, (String, String)> _failure = {};

  /// Re-checks a known cause when Huda comes back from Settings.
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: () {
      if (_failure.containsKey(_Reminder.sahur.key)) _explainSahur();
    },
  );

  /// Keys being scheduled again after Retry.
  final Set<String> _retrying = {};

  /// Keys whose time is being saved and scheduled.
  final Set<String> _saving = {};

  bool get _sahurAvailable => widget.debugSahur ?? PlatformUtils.isMobile;

  DateTime _now() => widget.debugClock?.call() ?? DateTime.now();

  /// Moves the shadow and the countdown on with the clock.
  Timer? _minute;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<NotificationsCubit>();
    _access =
        widget.debugAccess?.call(cubit, _initializeNotifications) ??
        NotificationAccessController(
          cubit: cubit,
          onAccessGained: _initializeNotifications,
        );
    _access.addListener(_onAccess);
    _lifecycle;
    _initializeNotifications();
    if (widget.debugClock == null) {
      _minute = Timer.periodic(const Duration(minutes: 1), (_) => _onAccess());
    }
  }

  @override
  void dispose() {
    _minute?.cancel();
    _lifecycle.dispose();
    _access
      ..removeListener(_onAccess)
      ..dispose();
    super.dispose();
  }

  void _onAccess() {
    if (mounted) setState(() {});
  }

  Future<void> _initializeNotifications() async {
    final cubit = context.read<NotificationsCubit>();
    await cubit.getIsNotificationEnabled();
    await cubit.loadPreferences();
    await cubit.initializeNotifications();
    // Sahur that's on but can't ring (alarms denied, sounds off…) says so.
    final state = cubit.state;
    if (state is NotificationPreferencesLoaded && state.sahurAlarmEnabled) {
      await _explainSahur(onlyIfUnscheduled: true);
    }
  }

  /// The iOS alarm and notification state; null off iOS.
  Future<IOSPrayerStatus?> _iosStatus() async {
    final debug = widget.debugIosStatus;
    if (debug != null) return debug();
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return null;
    try {
      return await IOSPrayerBridge.refresh();
    } on Object {
      return null;
    }
  }

  /// Why Sahur can't be scheduled on iOS, and the fix, on its row. A
  /// denied permission never prompts again, so Retry alone can't help.
  Future<void> _explainSahur({bool onlyIfUnscheduled = false}) async {
    final status = await _iosStatus();
    if (status == null || !mounted) return;
    final key = _Reminder.sahur.key;
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<NotificationsCubit>();
    final state = cubit.state;
    final beforeFajr =
        state is NotificationPreferencesLoaded && state.sahurAlarmType == 1;
    Future<void> settings() async {
      try {
        await IOSPrayerBridge.openSettings();
      } on Object {
        // Settings can't open (or no iOS bridge): the message still says where.
      }
    }

    final (String, String, Future<void> Function())? problem =
        status.supportsAlarms && status.alarmAuthorization == 'denied'
        ? (l10n.remindersSahurAlarmsDenied, l10n.openSettings, settings)
        : !status.supportsAlarms && status.notificationAuthorization == 'denied'
        ? (l10n.remindersSahurNotificationsOff, l10n.openSettings, settings)
        : !status.supportsAlarms && !status.notificationSound
        ? (l10n.remindersSahurSoundOff, l10n.openSettings, settings)
        : beforeFajr && !status.ready
        ? (
            l10n.remindersSahurNeedsPrayerTimes,
            l10n.remindersUseExactTime,
            () async {
              try {
                await cubit.setSahurAlarmType(0);
              } on NotificationNotScheduledException {
                // Saved; turning it on below schedules it, or says why not.
              }
              await _toggle(key, true, retry: true);
            },
          )
        : null;
    if (!mounted) return;
    if (problem == null) {
      // Fixed in Settings since: clear the explanation.
      if (_failure.containsKey(key)) {
        setState(() {
          _failure.remove(key);
          _failed.remove(key);
        });
      }
      if (onlyIfUnscheduled && !status.sahurScheduled) {
        setState(() => _failed[key] = () => _toggle(key, true, retry: true));
      }
      return;
    }
    if (onlyIfUnscheduled && status.sahurScheduled) return;
    setState(() {
      _failure[key] = (problem.$1, problem.$2);
      _failed[key] = problem.$3;
    });
  }

  void _toast(String message, {HudaToastKind kind = HudaToastKind.done}) {
    if (!mounted) return;
    showHudaToast(context, message: message, kind: kind);
  }

  /// Notification access first, when turning a reminder on needs it.
  Future<bool> _allowed(bool on, {bool sahur = false}) async {
    // The matrix has no native Sahur gateway (debugSahur): it asks.
    final needs =
        on &&
        (!sahur ||
            widget.debugSahur != null ||
            await NativeSahurAlarmGateway.requiresNotificationPermission());
    if (!mounted) return false;
    // Already allowed (the access card knows): no need to ask again.
    if (!needs || (_access.access?.notificationsEnabled ?? false)) return true;
    return PermissionHandlers.requestNotificationPermission(context);
  }

  Future<void> _toggle(String key, bool value, {bool retry = false}) async {
    if (!retry) HudaHaptics.selection(context);
    if (!await _allowed(value, sahur: key == _Reminder.sahur.key)) return;
    if (!mounted) return;
    setState(() {
      _failed.remove(key);
      _failure.remove(key);
      if (retry) _retrying.add(key);
    });
    try {
      await context.togglePreference(key, value);
    } on NotificationNotScheduledException {
      if (!mounted) return;
      setState(() => _failed[key] = () => _toggle(key, true, retry: true));
      if (key == _Reminder.sahur.key) await _explainSahur();
    } finally {
      if (mounted) setState(() => _retrying.remove(key));
    }
  }

  /// Saves a time or interval and, for a reminder that's on, schedules it;
  /// a failure stays on the row with Retry.
  Future<void> _saveSetting(
    String key,
    Future<void> Function() save, {
    bool retry = false,
  }) async {
    setState(() {
      _failed.remove(key);
      _failure.remove(key);
      _saving.add(key);
      if (retry) _retrying.add(key);
    });
    try {
      await save();
    } on NotificationNotScheduledException {
      if (!mounted) return;
      setState(() => _failed[key] = () => _saveSetting(key, save, retry: true));
      if (key == _Reminder.sahur.key) await _explainSahur();
    } finally {
      if (mounted) {
        setState(() {
          _saving.remove(key);
          _retrying.remove(key);
        });
      }
    }
  }

  Future<void> _pickTime({
    required String key,
    required bool enabled,
    required String current,
    required String help,
    required Future<void> Function(String time) save,
    bool daily = true,
  }) async {
    if (!await _allowed(enabled)) return;
    if (!mounted) return;
    final picked = await showHudaTimePicker(
      context: context,
      initialTime: parseReminderTime(current),
      title: help,
      // Al-Kahf is weekly: "in 7 h" would be wrong for it.
      daily: daily,
      clock: _now,
    );
    if (picked == null || !mounted) return;
    HudaHaptics.selection(context);
    await _saveSetting(key, () => save(formatReminderTime(picked)));
  }

  Future<void> _pickFrequency(NotificationPreferencesLoaded state) async {
    if (!await _allowed(state.randomAthkar)) return;
    if (!mounted) return;
    final cubit = context.read<NotificationsCubit>();
    final minutes = await showReminderFrequencySheet(
      context,
      state.randomAthkarFrequency,
    );
    if (minutes == null || !mounted) return;
    await _saveSetting(
      _Reminder.random.key,
      () => cubit.setRandomAthkarFrequency(minutes),
    );
  }

  Future<void> _openSahur(NotificationPreferencesLoaded state) async {
    if (!await _allowed(state.sahurAlarmEnabled, sahur: true)) return;
    if (!mounted) return;
    await showSahurSheet(
      context,
      context.read<NotificationsCubit>(),
      clock: _now,
    );
  }

  ReminderRowStatus _status(NotificationPreferencesLoaded state, String key) {
    if (state.loadingKeys.contains(key) || _saving.contains(key)) {
      return _retrying.contains(key)
          ? ReminderRowStatus.retrying
          : ReminderRowStatus.scheduling;
    }
    if (_failed.containsKey(key)) return ReminderRowStatus.failed;
    return ReminderRowStatus.idle;
  }

  // Rows ----------------------------------------------------------------------

  Widget _row(NotificationPreferencesLoaded state, _Reminder reminder) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<NotificationsCubit>();
    String time(String value) => localReminderTime(context, value);
    Widget chip(
      String label,
      String spoken,
      VoidCallback onPressed, {
      IconData icon = Icons.schedule_rounded,
    }) => ReminderTimeChip(
      label: label,
      icon: icon,
      semanticLabel: l10n.remindersChangeTime(spoken),
      onPressed: onPressed,
    );
    final key = reminder.key;
    final (icon, title, description, on, schedule) = switch (reminder) {
      _Reminder.athkar => (
        Icons.wb_twilight_rounded,
        l10n.morningEveningAthkarTitle,
        l10n.dailyRemindersAthkar,
        state.sabahMasaa,
        [
          chip(
            '${l10n.morning}${time(state.morningAthkarTime)}',
            time(state.morningAthkarTime),
            () => _pickTime(
              key: key,
              enabled: state.sabahMasaa,
              current: state.morningAthkarTime,
              help: l10n.selectMorningAthkarTime,
              save: cubit.setMorningAthkarTime,
            ),
          ),
          chip(
            '${l10n.evening}${time(state.eveningAthkarTime)}',
            time(state.eveningAthkarTime),
            () => _pickTime(
              key: key,
              enabled: state.sabahMasaa,
              current: state.eveningAthkarTime,
              help: l10n.selectEveningAthkarTime,
              save: cubit.setEveningAthkarTime,
            ),
          ),
        ],
      ),
      _Reminder.random => (
        Icons.auto_awesome_rounded,
        l10n.randomAthkarTitle,
        l10n.periodicRemindersAthkar,
        state.randomAthkar,
        [
          chip(
            l10n.everyMinutes(_digits(_frequency(state)), ''),
            l10n.everyMinutes(_digits(_frequency(state)), ''),
            () => _pickFrequency(state),
            icon: Icons.repeat_rounded,
          ),
        ],
      ),
      _Reminder.quran => (
        Icons.menu_book_rounded,
        l10n.quranReadingReminderTitle,
        l10n.dailyReminderQuran,
        state.quranReminder,
        [
          chip(
            l10n.dailyAtTime(time(state.quranReminderTime)),
            time(state.quranReminderTime),
            () => _pickTime(
              key: key,
              enabled: state.quranReminder,
              current: state.quranReminderTime,
              help: l10n.selectQuranReminderTime,
              save: cubit.setQuranReminderTime,
            ),
          ),
        ],
      ),
      _Reminder.kahf => (
        Icons.auto_stories_rounded,
        l10n.suratAlKahf,
        l10n.weeklyReminderKahf,
        state.kahfFriday,
        [
          chip(
            l10n.everyFridayAtTime(time(state.kahfFridayTime)),
            time(state.kahfFridayTime),
            () => _pickTime(
              key: key,
              enabled: state.kahfFriday,
              current: state.kahfFridayTime,
              help: l10n.selectKahfFridayTime,
              save: cubit.setKahfFridayTime,
              daily: false,
            ),
          ),
        ],
      ),
      _Reminder.sahur => (
        Icons.alarm_rounded,
        l10n.sahurAlarmTitle,
        l10n.sahurAlarmDescription,
        state.sahurAlarmEnabled,
        [
          chip(
            _sahurSchedule(state, l10n),
            _sahurSchedule(state, l10n),
            () => _openSahur(state),
          ),
        ],
      ),
      _Reminder.checklist => (
        Icons.checklist_rtl_rounded,
        l10n.dailyChecklistReminder,
        l10n.checklistReminderDescription,
        state.checklistReminder,
        [
          chip(
            l10n.dailyChecklistSubtitle(time(state.checklistReminderTime)),
            time(state.checklistReminderTime),
            () => _pickTime(
              key: key,
              enabled: state.checklistReminder,
              current: state.checklistReminderTime,
              help: l10n.selectChecklistReminderTime,
              save: cubit.setChecklistReminderTime,
            ),
          ),
        ],
      ),
    };
    return ReminderRow(
      key: ValueKey('reminder-$key'),
      icon: icon,
      title: title,
      description: description,
      value: on,
      onChanged: (value) => _toggle(key, value),
      schedule: schedule,
      status: _status(state, key),
      onRetry: _failed[key],
      failure: _failure[key],
      footnote: reminder == _Reminder.sahur && state.sahurNotificationOnly
          ? l10n.sahurNotificationOnlyDescription
          : null,
    );
  }

  int _frequency(NotificationPreferencesLoaded state) =>
      state.randomAthkarScheduledFrequency ?? state.randomAthkarFrequency;

  String _digits(int value) => intl.NumberFormat.decimalPattern(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(value);

  String _sahurSchedule(
    NotificationPreferencesLoaded state,
    AppLocalizations l10n,
  ) => state.sahurAlarmType == 0
      ? l10n.atExactTime(localReminderTime(context, state.sahurExactTime))
      : l10n.minsBeforeFajr(state.sahurMinutesBeforeFajr);

  List<(String, List<_Reminder>)> _groups(AppLocalizations l10n) => [
    (l10n.athkar, [_Reminder.athkar, _Reminder.random]),
    (l10n.quran, [_Reminder.quran, _Reminder.kahf]),
    (
      l10n.remindersRoutineSection,
      [if (_sahurAvailable) _Reminder.sahur, _Reminder.checklist],
    ),
  ];

  // The day --------------------------------------------------------------------

  /// What fires on a day: (id, title, time, Friday only, icon). Each
  /// carries its row's icon; morning and evening Athkar are named apart.
  List<(String, String, TimeOfDay, bool, IconData)> _occurrences(
    NotificationPreferencesLoaded state,
    AppLocalizations l10n,
  ) => [
    if (state.sabahMasaa) ...[
      (
        'athkar-morning',
        l10n.morningAthkar,
        parseReminderTime(state.morningAthkarTime),
        false,
        Icons.wb_twilight_rounded,
      ),
      (
        'athkar-evening',
        l10n.eveningAthkar,
        parseReminderTime(state.eveningAthkarTime),
        false,
        Icons.nights_stay_rounded,
      ),
    ],
    if (state.quranReminder)
      (
        'quran',
        l10n.quranReadingReminderTitle,
        parseReminderTime(state.quranReminderTime),
        false,
        Icons.menu_book_rounded,
      ),
    if (state.kahfFriday)
      (
        'kahf',
        l10n.suratAlKahf,
        parseReminderTime(state.kahfFridayTime),
        true,
        Icons.auto_stories_rounded,
      ),
    // Before Fajr depends on the day's prayer times: not placed.
    if (_sahurAvailable && state.sahurAlarmEnabled && state.sahurAlarmType == 0)
      (
        'sahur',
        l10n.sahurAlarmTitle,
        parseReminderTime(state.sahurExactTime),
        false,
        Icons.alarm_rounded,
      ),
    if (state.checklistReminder)
      (
        'checklist',
        l10n.dailyChecklistReminder,
        parseReminderTime(state.checklistReminderTime),
        false,
        Icons.checklist_rtl_rounded,
      ),
  ];

  Widget _dayCard(NotificationPreferencesLoaded state) {
    final l10n = AppLocalizations.of(context)!;
    final now = _now();
    final occurrences = _occurrences(state, l10n);
    double hours(TimeOfDay t) => t.hour + t.minute / 60;

    // The next one to fire, within a week.
    (String, String, DateTime, int)? next;
    final today = DateTime(now.year, now.month, now.day);
    for (var day = 0; day < 8 && next == null; day++) {
      final date = today.add(Duration(days: day));
      for (final (id, title, time, friday, _) in occurrences) {
        if (friday && date.weekday != DateTime.friday) continue;
        final at = date.add(Duration(hours: time.hour, minutes: time.minute));
        if (!at.isAfter(now)) continue;
        if (next == null || at.isBefore(next.$3)) next = (id, title, at, day);
      }
    }

    final todays = [
      for (final o in occurrences)
        if (!o.$4 || now.weekday == DateTime.friday) o,
    ]..sort((a, b) => hours(a.$3).compareTo(hours(b.$3)));
    final format = MaterialLocalizations.of(context);
    final h24 = MediaQuery.alwaysUse24HourFormatOf(context);
    String spoken(TimeOfDay t) =>
        format.formatTimeOfDay(t, alwaysUse24HourFormat: h24);

    final dial = RemindersDial(
      marks: [
        for (final (id, _, time, _, icon) in todays)
          ReminderMark(
            id,
            hours(time),
            icon,
            next: next != null && next.$4 == 0 && next.$1 == id,
          ),
      ],
      now: now.hour + now.minute / 60,
      rhythmMinutes: state.randomAthkar ? _frequency(state) : null,
      semanticLabel: todays.isEmpty
          ? l10n.remindersDialEmptyLabel
          : l10n.remindersDialLabel(
              todays.map((o) => '${o.$2} ${spoken(o.$3)}').join(', '),
            ),
    );

    final space = context.tokens.space;
    final Widget caption;
    if (next != null) {
      final time = spoken(TimeOfDay.fromDateTime(next.$3));
      final when = switch (next.$4) {
        0 => l10n.remindersNextToday(time),
        1 => l10n.remindersNextTomorrow(time),
        _ => l10n.remindersNextOnDay(
          intl.DateFormat.EEEE(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(next.$3),
          time,
        ),
      };
      // Within a day: how long until it fires.
      final left = (next.$3.difference(now).inSeconds + 59) ~/ 60;
      final until = left > 24 * 60 ? null : hudaTimeUntil(context, left);
      caption = _Caption(
        key: ValueKey('next-${next.$1}'),
        eyebrow: l10n.remindersNextReminder,
        title: next.$2,
        message: when,
        until: until,
      );
    } else if (state.randomAthkar) {
      caption = _Caption(
        key: const ValueKey('random'),
        eyebrow: l10n.remindersNextReminder,
        title: l10n.randomAthkarTitle,
        message: l10n.everyMinutes(_digits(_frequency(state)), ''),
      );
    } else {
      caption = _Caption(
        key: const ValueKey('none'),
        title: l10n.remindersNoneOnTitle,
        message: l10n.remindersNoneOnMessage,
      );
    }
    final ready = _access.access?.isReady ?? false;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HudaStateSwitcher(stateKey: caption.key!, child: caption),
        if (ready) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: space.md),
            child: const Divider(height: 1),
          ),
          const NotificationsReadyStatus(),
        ],
      ],
    );
    return HudaCard(
      key: const ValueKey('reminders-day'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Side by side when there's room, so the card stays short.
          final short = MediaQuery.sizeOf(context).height < 480;
          if (width >= 480) {
            return Row(
              children: [
                SizedBox(width: math.min(width * 0.5, 360), child: dial),
                SizedBox(width: space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DayLine(now),
                      SizedBox(height: space.md),
                      text,
                    ],
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DayLine(now),
              SizedBox(height: space.sm),
              Center(
                // Short windows (phone landscape): a smaller dial, so the
                // caption and status stay on the first screen.
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: short ? 220 : 400),
                  child: dial,
                ),
              ),
              SizedBox(height: space.md),
              text,
            ],
          );
        },
      ),
    );
  }

  // Layouts --------------------------------------------------------------------

  Widget _accessSection() => NotificationRequirementsSection(
    feature: NotificationFeature.reminders,
    controller: _access,
  );

  List<Widget> _sectionSlivers(NotificationPreferencesLoaded state) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final slivers = <Widget>[];
    var reveal = 2;
    for (final (title, reminders) in _groups(l10n)) {
      if (reminders.isEmpty) continue;
      slivers
        ..add(
          SliverPadding(
            padding: EdgeInsets.only(top: space.lg),
            sliver: SliverToBoxAdapter(child: HudaSectionHeader(title)),
          ),
        )
        ..add(
          SliverAdaptiveGrid(
            itemCount: reminders.length,
            minTileWidth: AdaptiveGrid.tileWidth(context, 300),
            spacing: space.sm,
            maxColumns: 2,
            itemBuilder: (context, i) =>
                HudaReveal(index: reveal + i, child: _row(state, reminders[i])),
          ),
        );
      reveal += reminders.length;
    }
    return slivers;
  }

  /// Very wide panes: the groups side by side, each a column of rows.
  Widget _groupColumns(NotificationPreferencesLoaded state) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final groups = [
      for (final group in _groups(l10n))
        if (group.$2.isNotEmpty) group,
    ];
    var reveal = 2;
    final columns = <Widget>[];
    for (final (title, reminders) in groups) {
      if (columns.isNotEmpty) columns.add(SizedBox(width: space.md));
      final from = reveal;
      columns.add(
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HudaSectionHeader(title),
              for (var i = 0; i < reminders.length; i++) ...[
                if (i > 0) SizedBox(height: space.sm),
                HudaReveal(index: from + i, child: _row(state, reminders[i])),
              ],
            ],
          ),
        ),
      );
      reveal += reminders.length;
    }
    return _box(
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: columns),
      top: space.lg,
    );
  }

  /// A scroll view whose content keeps a readable width, centered.
  Widget _scroll(List<Widget> slivers, {double maxWidth = 760}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final space = context.tokens.space;
        final width = constraints.maxWidth;
        final gutter = space.gutter(width);
        final side = math.max(gutter, (width - maxWidth) / 2);
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: context.scrollPadding(
                EdgeInsets.fromLTRB(side, space.sm, side, space.xl),
              ),
              sliver: SliverMainAxisGroup(slivers: slivers),
            ),
          ],
        );
      },
    );
  }

  Widget _box(Widget child, {double top = 0}) => SliverPadding(
    padding: EdgeInsets.only(top: top),
    sliver: SliverToBoxAdapter(child: child),
  );

  List<Widget> _overview(NotificationPreferencesLoaded state) {
    final space = context.tokens.space;
    return [
      _box(HudaReveal(child: _dayCard(state))),
      _box(HudaReveal(index: 1, child: _accessSection()), top: space.md),
    ];
  }

  Widget _delivery({double top = 0}) =>
      _box(ReminderDeliverySection(toast: _toast), top: top);

  Widget _loaded(NotificationPreferencesLoaded state) {
    final space = context.tokens.space;
    final width = MediaQuery.sizeOf(context).width;
    final fold = FoldInfo.of(context);
    if (AdaptivePanes.showsTwoPanes(width, fold)) {
      return AdaptivePanes(
        primaryFraction: 0.4,
        maxPrimaryWidth: 480,
        primary: _scroll([..._overview(state), _delivery(top: space.lg)]),
        secondary: LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= 1080
              ? _scroll([_groupColumns(state)], maxWidth: 1400)
              : _scroll(_sectionSlivers(state), maxWidth: 1000),
        ),
      );
    }
    return _scroll([
      ..._overview(state),
      ..._sectionSlivers(state),
      _delivery(top: space.lg),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<NotificationsCubit>().state;
    final loaded = state is NotificationPreferencesLoaded ? state : null;
    final width = MediaQuery.sizeOf(context).width;
    final fold = FoldInfo.of(context);

    if (loaded != null &&
        !AdaptivePanes.showsTwoPanes(width, fold) &&
        TabletopSplit.applies(context)) {
      final space = context.tokens.space;
      return HudaRevealScope(
        child: TabletopSplit(
          top: HudaScaffold(
            title: l10n.remindersTitle,
            body: _scroll([_box(HudaReveal(child: _dayCard(loaded)))]),
          ),
          bottom: Scaffold(
            backgroundColor: Colors.transparent,
            body: _scroll([
              _box(HudaReveal(index: 1, child: _accessSection())),
              ..._sectionSlivers(loaded),
              _delivery(top: space.lg),
            ]),
          ),
        ),
      );
    }

    return HudaRevealScope(
      child: HudaScaffold(
        title: l10n.remindersTitle,
        body: HudaStateSwitcher(
          stateKey: loaded != null,
          child: loaded == null ? const _Skeleton() : _loaded(loaded),
        ),
      ),
    );
  }
}

/// The dial's caption: what fires next, or that nothing's on.
class _Caption extends StatelessWidget {
  const _Caption({
    super.key,
    required this.title,
    required this.message,
    this.eyebrow,
    this.until,
  });

  final String? eyebrow;
  final String title;
  final String message;

  /// How long until it fires ("in 2 h 40 min"), when it's within a day.
  final String? until;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final space = context.tokens.space;
    final eyebrow = this.eyebrow;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (eyebrow != null) ...[
            HudaEyebrow(eyebrow),
            SizedBox(height: space.xxs),
          ],
          Text(title, style: theme.textTheme.titleLarge),
          SizedBox(height: space.xxs),
          Wrap(
            spacing: space.xs,
            runSpacing: space.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (until case final until?)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      context.tokens.radius.md,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: space.xs,
                      vertical: 2,
                    ),
                    child: Text(
                      until,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The day the dial shows: the weekday and the Hijri date, so a Friday's
/// Al-Kahf and the day's place in the month read at a glance.
class _DayLine extends StatelessWidget {
  const _DayLine(this.now);

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final digits = intl.NumberFormat('0', locale);
    final hijri = hijriDateFromDateTime(now);
    final day = intl.DateFormat.EEEE(locale).format(now);
    final date =
        '${digits.format(hijri.day)} ${hijriMonthName(l10n, hijri.month)} '
        '${digits.format(hijri.year)}';
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    // Two pieces that wrap whole at large text, never mid-name.
    return Wrap(
      spacing: context.tokens.space.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(day, style: theme.textTheme.titleSmall),
        // The separator leads the date, so a wrap never leaves it dangling.
        Text('·  $date', style: muted),
      ],
    );
  }
}

/// Loading: the dial card and a few rows, in their shapes.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final width = MediaQuery.sizeOf(context).width;
    final side = math.max(space.gutter(width), (width - 760) / 2);
    Widget row() => HudaCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HudaSkeletonBlock(width: 38, height: 38, circle: true),
          SizedBox(width: space.sm),
          Expanded(
            child: HudaSkeletonLines(
              lines: 3,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          SizedBox(width: space.sm),
          const HudaSkeletonBlock(width: 52, height: 32),
        ],
      ),
    );
    return HudaSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: context.scrollPadding(
          EdgeInsets.fromLTRB(side, space.sm, side, space.xl),
        ),
        children: [
          HudaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: const HudaSkeletonBlock(height: 200),
                  ),
                ),
                SizedBox(height: space.md),
                HudaSkeletonLines(
                  lines: 2,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          SizedBox(height: space.lg),
          row(),
          SizedBox(height: space.sm),
          row(),
          SizedBox(height: space.sm),
          row(),
        ],
      ),
    );
  }
}
