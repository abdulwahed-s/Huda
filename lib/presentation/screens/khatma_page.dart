import 'package:flutter/material.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/notifications/notification_orchestrator.dart';
import 'package:huda/core/notifications/reminder_model.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/khatma_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/khatma/khatma_identity.dart';
import 'package:huda/presentation/widgets/khatma/khatma_views.dart';
import 'package:huda/presentation/widgets/notifications/notification_requirements_section.dart';
import 'package:huda/presentation/widgets/notifications/permission_handlers.dart';
import 'package:huda/presentation/widgets/design/huda_time_picker.dart';

/// Opens the Khatma in the shared sheet: a bottom sheet on phones, a
/// dialog from medium width. Its height follows the step. The Quran
/// reader's More menu opens it.
Future<void> showKhatmaSheet(BuildContext context) => showHudaSheet<void>(
  context: context,
  title: AppLocalizations.of(context)!.khatmaLegendKhatma,
  // Wide windows get two columns: the road and today beside the rest.
  maxDialogWidth: context.windowClass.width >= WindowWidthClass.expanded
      ? 880
      : 640,
  builder: (_) => const KhatmaPage(),
);

/// The Khatma: choose a pace and where to start, then follow the road one
/// portion a day. Lives inside its sheet (see [showKhatmaSheet]); the
/// sheet scrolls it.
class KhatmaPage extends StatefulWidget {
  const KhatmaPage({super.key});

  @override
  State<KhatmaPage> createState() => _KhatmaPageState();
}

enum _Step { setup, chooseDay, active, schedule, completed }

class _KhatmaPageState extends State<KhatmaPage> {
  late final KhatmaService _service;
  _Step _step = _Step.setup;
  int _days = khatmaSuggestedPace;

  /// Setup was reached from a finished khatma (it has a way back).
  bool _setupFromCompleted = false;
  _Step _scheduleBack = _Step.active;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);

  /// Where the road was last shown, so a view that appears walks on from
  /// there instead of drawing in again. 0 on open: the road draws in.
  double _trailShown = 0;

  @override
  void initState() {
    super.initState();
    _service = getIt<KhatmaService>();
    _load();
  }

  void _load() {
    setState(() {
      if (_service.enabled) {
        _days = _service.planDays;
        _step = _service.isCompleted ? _Step.completed : _Step.active;
      } else {
        _step = _Step.setup;
        _setupFromCompleted = false;
      }
      _reminderEnabled = _service.reminderEnabled;
      _reminderTime = TimeOfDay(
        hour: _service.reminderHour,
        minute: _service.reminderMinute,
      );
    });
  }

  void _go(_Step step) => setState(() => _step = step);

  /// A new step starts at the top of the sheet.
  @override
  void setState(VoidCallback fn) {
    final before = _step;
    super.setState(fn);
    if (_step == before) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final position = Scrollable.maybeOf(context)?.position;
      if (position == null || position.pixels == 0) return;
      final motion = context.tokens.motion;
      final duration = motion.of(context, motion.medium);
      if (duration == Duration.zero) {
        position.jumpTo(0);
      } else {
        position.animateTo(0, duration: duration, curve: motion.standard);
      }
    });
  }

  /// Where the Khatma's own dialogs open: its trailing bottom corner of the
  /// whole window, so on a half-open fold they share the sheet's half.
  Offset get _anchor {
    final view = View.of(context);
    final size = view.physicalSize / view.devicePixelRatio;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Offset(rtl ? 0 : size.width, size.height);
  }

  // Plan ------------------------------------------------------------------

  Future<void> _start(int fromDay) async {
    HudaHaptics.light(context);
    if (fromDay == 0) {
      await _service.startPlan(_days);
    } else {
      await _service.startPlanFromDay(_days, fromDay);
    }
    _trailShown = 0;
    _load();
  }

  Future<void> _markDone() async {
    final before = _service.totalPagesRead;
    _trailShown = KhatmaJourney.position(before);
    await _service.markTodayDone();
    if (!mounted) return;
    final after = _service.totalPagesRead;
    // A juz finished or the whole khatma: a milestone. Otherwise a check.
    if (_service.isCompleted ||
        KhatmaJourney.juzDone(after) > KhatmaJourney.juzDone(before)) {
      HudaHaptics.medium(context);
    } else {
      HudaHaptics.light(context);
    }
    _load();
  }

  Future<void> _repeat() async {
    HudaHaptics.light(context);
    await _service.startPlan(_days);
    _trailShown = 0;
    _load();
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      anchorPoint: _anchor,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.khatmaDeleteTitle),
        content: Text(l10n.khatmaDeleteConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const ValueKey('khatma-delete-confirm'),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    HudaHaptics.light(context);
    await _service.resetPlan();
    _trailShown = 0;
    _days = khatmaSuggestedPace;
    _load();
  }

  void _open(int surah, int verse) {
    final model = QuranModel(
      number: surah,
      name: quran.getSurahNameArabic(surah),
      englishName: quran.getSurahNameEnglish(surah),
    );
    Navigator.pop(context);
    Navigator.pushReplacementNamed(
      context,
      AppRoute.surahScreen,
      arguments: {
        'surahInfo': model,
        'shouldRestorePosition': false,
        'scrollToAyah': verse,
      },
    );
  }

  // Reminder --------------------------------------------------------------

  Future<void> _pickReminderTime() async {
    final picked = await showHudaTimePicker(
      context: context,
      initialTime: _reminderTime,
      title: AppLocalizations.of(context)!.khatmaReminderTime,
      daily: true,
    );
    if (picked == null || !mounted) return;
    if (_reminderEnabled &&
        !await PermissionHandlers.requestNotificationPermission(context)) {
      return;
    }
    if (!mounted) return;
    await _service.setReminder(
      enabled: _reminderEnabled,
      hour: picked.hour,
      minute: picked.minute,
    );
    if (_reminderEnabled) await _syncReminder();
    if (mounted) setState(() => _reminderTime = picked);
  }

  Future<void> _toggleReminder(bool value) async {
    HudaHaptics.selection(context);
    if (value &&
        !await PermissionHandlers.requestNotificationPermission(context)) {
      return;
    }
    if (!mounted) return;
    await _service.setReminder(
      enabled: value,
      hour: _reminderTime.hour,
      minute: _reminderTime.minute,
    );
    await _syncReminder();
    if (mounted) setState(() => _reminderEnabled = value);
  }

  /// The orchestrator reads the saved reminder setting.
  Future<void> _syncReminder() => NotificationOrchestrator.shared.requestSync(
    'khatma-reminder',
    categories: {ReminderCategory.reminder},
  );

  Future<void> _restoreReminder() async {
    if (_reminderEnabled) await _syncReminder();
  }

  // Views -----------------------------------------------------------------

  String _relativeDay(AppLocalizations l10n) {
    final started = _service.startedAt;
    var diff = 0;
    if (started != null) {
      final now = DateTime.now();
      final start = DateTime(started.year, started.month, started.day);
      final today = DateTime(now.year, now.month, now.day);
      diff = start
          .add(Duration(days: _service.currentDayIndex))
          .difference(today)
          .inDays;
    }
    if (diff == 0) return l10n.today;
    if (diff == 1) return l10n.khatmaTomorrow;
    if (diff == 2) return l10n.khatmaInTwoDays;
    if (diff > 2 && diff <= 10) return l10n.khatmaInDays(diff);
    if (diff > 10) return l10n.khatmaInManyDays(diff);
    if (diff == -1) return l10n.khatmaYesterday;
    if (diff == -2) return l10n.khatmaTwoDaysAgo;
    final ago = diff.abs();
    if (ago <= 10) return l10n.khatmaDaysAgo(ago);
    return l10n.khatmaManyDaysAgo(ago);
  }

  /// The days the khatma took, from its start to today.
  int _journeyDays() {
    final started = _service.startedAt;
    if (started == null) return _service.planDays;
    final now = DateTime.now();
    final start = DateTime(started.year, started.month, started.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(start).inDays + 1;
  }

  Widget _reminder() => KhatmaReminderSection(
    enabled: _reminderEnabled,
    time: MaterialLocalizations.of(context).formatTimeOfDay(
      _reminderTime,
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    ),
    requirements: NotificationRequirementsSection(
      feature: NotificationFeature.khatma,
      onNotificationEnabled: _restoreReminder,
      bottomSpacing: context.tokens.space.sm,
    ),
    onToggle: _toggleReminder,
    onPickTime: _pickReminderTime,
  );

  Widget _plan(_Step from) => KhatmaPlanSection(
    onSchedule: () {
      _scheduleBack = from;
      _go(_Step.schedule);
    },
    onDelete: _confirmDelete,
  );

  Widget _current(AppLocalizations l10n) {
    final from = _trailShown;
    switch (_step) {
      case _Step.setup:
        _trailShown = 0;
        return KhatmaSetupView(
          days: _days,
          pagesPerDay: _service.pagesPerDay,
          onDays: (days) {
            HudaHaptics.selection(context);
            setState(() => _days = days);
          },
          onFromBeginning: () => _start(0),
          onChooseDay: () => _go(_Step.chooseDay),
          onBack: _setupFromCompleted
              ? () {
                  _days = _service.planDays;
                  _go(_Step.completed);
                }
              : null,
        );
      case _Step.chooseDay:
        return KhatmaScheduleView(
          key: ValueKey('choose-$_days'),
          service: _service,
          days: _days,
          currentDay: -1,
          title: l10n.khatmaStartFromTitle,
          message: l10n.khatmaSpecificWirdSubtitle,
          onBack: () => _go(_Step.setup),
          onDay: _start,
        );
      case _Step.active:
        _trailShown = KhatmaJourney.position(_service.totalPagesRead);
        return KhatmaActiveView(
          service: _service,
          trailFrom: from,
          relativeDay: _relativeDay(l10n),
          reminder: _reminder(),
          plan: _plan(_Step.active),
          onOpen: _open,
          onMarkDone: _markDone,
        );
      case _Step.schedule:
        return KhatmaScheduleView(
          service: _service,
          days: _service.planDays,
          currentDay: _service.isCompleted ? -1 : _service.currentDayIndex,
          title: l10n.khatmaAllWirds,
          onBack: () => _go(_scheduleBack),
        );
      case _Step.completed:
        _trailShown = 30;
        return KhatmaCompletedView(
          trailFrom: from,
          days: _journeyDays(),
          reminder: _reminder(),
          plan: _plan(_Step.completed),
          onRepeat: _repeat,
          onStartNew: () {
            _setupFromCompleted = true;
            _go(_Step.setup);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HudaRevealScope(
      child: HudaStateSwitcher(
        stateKey: _step,
        sequential: true,
        child: _current(l10n),
      ),
    );
  }
}
