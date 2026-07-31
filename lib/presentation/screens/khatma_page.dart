import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/services/notification_page_helper.dart';
import 'package:huda/core/services/khatma_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/presentation/widgets/khatma/khatma_active_view.dart';
import 'package:huda/presentation/widgets/khatma/khatma_all_wirds_view.dart';
import 'package:huda/presentation/widgets/khatma/khatma_completed_view.dart';
import 'package:huda/presentation/widgets/khatma/khatma_empty_view.dart';
import 'package:huda/presentation/widgets/khatma/khatma_new_view.dart';
import 'package:huda/presentation/widgets/khatma/khatma_program_meaning_view.dart';
import 'package:huda/presentation/widgets/khatma/khatma_program_parts_view.dart';
import 'package:huda/presentation/widgets/khatma/khatma_start_from_view.dart';
import 'package:huda/presentation/widgets/notifications/notification_requirements_section.dart';
import 'package:huda/presentation/widgets/notifications/permission_handlers.dart';

class KhatmaPage extends StatefulWidget {
  const KhatmaPage({super.key});

  @override
  State<KhatmaPage> createState() => _KhatmaPageState();
}

enum _KhatmaStep {
  empty,
  newKhatma,
  programMeaning,
  programParts,
  startFrom,
  active,
  allWirds,
  completed,
}

class _KhatmaPageState extends State<KhatmaPage> {
  late final KhatmaService _service;
  _KhatmaStep _step = _KhatmaStep.empty;
  int _selectedProgramDays = 29;
  _KhatmaStep _fromStep = _KhatmaStep.newKhatma;
  _KhatmaStep _allWirdsPrevStep = _KhatmaStep.startFrom;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);
  final _notifHelper = NotificationPageHelper();

  @override
  void initState() {
    super.initState();
    _service = getIt<KhatmaService>();
    _notifHelper.init();
    _load();
  }

  void _load() {
    setState(() {
      if (_service.enabled) {
        _selectedProgramDays = _service.planDays;
        if (_service.isCompleted) {
          _step = _KhatmaStep.completed;
        } else {
          _step = _KhatmaStep.active;
        }
      } else {
        _step = _KhatmaStep.empty;
      }
      _reminderEnabled = _service.reminderEnabled;
      _reminderTime = TimeOfDay(
          hour: _service.reminderHour, minute: _service.reminderMinute);
    });
  }

  String _formatTimeArabic(TimeOfDay t) {
    final l10n = AppLocalizations.of(context)!;
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am
        ? l10n.khatmaAmIndicator
        : l10n.khatmaPmIndicator;
    return '$h:$m $period';
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      if (!mounted) return;
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
      if (_reminderEnabled) {
        await _notifHelper.scheduleKhatmaReminder(true, picked);
      }
      setState(() => _reminderTime = picked);
    }
  }

  Future<void> _toggleReminder(bool value) async {
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
    await _notifHelper.scheduleKhatmaReminder(value, _reminderTime);
    setState(() => _reminderEnabled = value);
  }

  Future<void> _restoreKhatmaReminder() async {
    if (_reminderEnabled) {
      await _notifHelper.scheduleKhatmaReminder(true, _reminderTime);
    }
  }

  TextDirection get _localeDirection {
    const rtlLanguages = {'ar', 'ur'};
    return rtlLanguages.contains(Localizations.localeOf(context).languageCode)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  void _navigateToSurah(int surahNum, int ayahNum) {
    final surah = QuranModel(
      number: surahNum,
      name: quran.getSurahNameArabic(surahNum),
      englishName: quran.getSurahNameEnglish(surahNum),
    );

    Navigator.pop(context);

    Navigator.pushReplacementNamed(context, AppRoute.surahScreen, arguments: {
      'surahInfo': surah,
      'shouldRestorePosition': false,
      'scrollToAyah': ayahNum,
    });
  }

  String _formatRelativeDay(int diff) {
    final l10n = AppLocalizations.of(context)!;
    if (diff == 0) return l10n.today;
    if (diff == 1) return l10n.khatmaTomorrow;
    if (diff == 2) return l10n.khatmaInTwoDays;
    if (diff > 2 && diff <= 10) return l10n.khatmaInDays(diff);
    if (diff > 10) return l10n.khatmaInManyDays(diff);

    if (diff == -1) return l10n.khatmaYesterday;
    if (diff == -2) return l10n.khatmaTwoDaysAgo;
    final absDiff = diff.abs();
    if (absDiff > 2 && absDiff <= 10) return l10n.khatmaDaysAgo(absDiff);
    return l10n.khatmaManyDaysAgo(absDiff);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(_step),
        color: Colors.transparent,
        child: _currentStep(),
      ),
    );
  }

  Widget _currentStep() {
    switch (_step) {
      case _KhatmaStep.empty:
        return _buildEmpty();
      case _KhatmaStep.newKhatma:
        return _buildNewKhatma();
      case _KhatmaStep.programMeaning:
        return _buildProgramMeaning();
      case _KhatmaStep.programParts:
        return _buildProgramParts();
      case _KhatmaStep.startFrom:
        return _buildStartFrom();
      case _KhatmaStep.active:
        return _buildActive();
      case _KhatmaStep.allWirds:
        return _buildAllWirds();
      case _KhatmaStep.completed:
        return _buildCompleted();
    }
  }

  Widget _buildEmpty() => KhatmaEmptyView(
        textDirection: _localeDirection,
        onStartNew: () => setState(() => _step = _KhatmaStep.newKhatma),
      );

  Widget _buildNewKhatma() => KhatmaNewView(
        textDirection: _localeDirection,
        onBack: () => setState(() => _step = _KhatmaStep.empty),
        onRecommendedTap: () {
          _selectedProgramDays = 29;
          _fromStep = _KhatmaStep.newKhatma;
          setState(() => _step = _KhatmaStep.startFrom);
        },
        onProgramMeaning: () =>
            setState(() => _step = _KhatmaStep.programMeaning),
        onProgramParts: () => setState(() => _step = _KhatmaStep.programParts),
      );

  Widget _buildProgramMeaning() => KhatmaProgramMeaningView(
        textDirection: _localeDirection,
        onBack: () => setState(() => _step = _KhatmaStep.newKhatma),
        onSelectDays: (days) {
          _selectedProgramDays = days;
          _fromStep = _KhatmaStep.programMeaning;
          setState(() => _step = _KhatmaStep.startFrom);
        },
        pagesPerDayFn: _service.pagesPerDay,
      );

  Widget _buildProgramParts() => KhatmaProgramPartsView(
        textDirection: _localeDirection,
        onBack: () => setState(() => _step = _KhatmaStep.newKhatma),
        onSelectDays: (days) {
          _selectedProgramDays = days;
          _fromStep = _KhatmaStep.programParts;
          setState(() => _step = _KhatmaStep.startFrom);
        },
      );

  Widget _buildStartFrom() {
    final daysLocal = _selectedProgramDays;
    return KhatmaStartFromView(
      textDirection: _localeDirection,
      onBack: () => setState(() => _step = _fromStep),
      onFromBeginning: () async {
        await _service.startPlan(daysLocal);
        _load();
      },
      onSpecificWird: () {
        _allWirdsPrevStep = _KhatmaStep.startFrom;
        setState(() => _step = _KhatmaStep.allWirds);
      },
    );
  }

  Widget _buildActive() {
    final l10n = AppLocalizations.of(context)!;
    final dayIndex = _service.currentDayIndex;
    final planDays = _service.planDays;
    final todayDetails = _service.rangeDetailsForDay(dayIndex, planDays);
    final yesterdayLabel =
        _service.rangeLabelForDay(max(0, dayIndex - 1), planDays);

    final st = _service.startedAt;
    int diffDays = 0;
    if (st != null) {
      final now = DateTime.now();
      final start = DateTime(st.year, st.month, st.day);
      final today = DateTime(now.year, now.month, now.day);
      final targetDate = start.add(Duration(days: dayIndex));
      diffDays = targetDate.difference(today).inDays;
    }

    return KhatmaActiveView(
      textDirection: _localeDirection,
      dayIndex: dayIndex,
      planDays: planDays,
      percentTotal: _service.percentTotal,
      percentDaily: _service.percentDaily,
      percentPacing: _service.percentPacing,
      daysRemaining: _service.daysRemaining,
      totalPagesRead: _service.totalPagesRead,
      pagesRemaining: _service.pagesRemaining,
      relativeDay: _formatRelativeDay(diffDays),
      startSurahLabel: l10n.khatmaFromSurah(
          todayDetails.startSurahName, todayDetails.startVerse),
      endSurahLabel:
          l10n.khatmaToSurah(todayDetails.endSurahName, todayDetails.endVerse),
      yesterdayLabel: yesterdayLabel,
      reminderEnabled: _reminderEnabled,
      formattedReminderTime: _formatTimeArabic(_reminderTime),
      onMarkDone: () async {
        await _service.markTodayDone();
        _load();
      },
      onAllWirds: () {
        _allWirdsPrevStep = _KhatmaStep.active;
        setState(() => _step = _KhatmaStep.allWirds);
      },
      onDelete: () => _confirmResetPlan(context),
      onNavigateToStart: () =>
          _navigateToSurah(todayDetails.startSurah, todayDetails.startVerse),
      onNavigateToEnd: () =>
          _navigateToSurah(todayDetails.endSurah, todayDetails.endVerse),
      notificationRequirements: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: NotificationRequirementsSection(
          feature: NotificationFeature.khatma,
          onNotificationEnabled: _restoreKhatmaReminder,
        ),
      ),
      onToggleReminder: _toggleReminder,
      onPickReminderTime: _pickReminderTime,
    );
  }

  Widget _buildAllWirds() {
    final bool isSetupMode = _allWirdsPrevStep == _KhatmaStep.startFrom;
    final daysLocal = isSetupMode
        ? _selectedProgramDays
        : (_service.enabled ? _service.planDays : _selectedProgramDays);
    final currentDayIndex =
        isSetupMode ? -1 : (_service.enabled ? _service.currentDayIndex : -1);

    return KhatmaAllWirdsView(
      textDirection: _localeDirection,
      totalDays: daysLocal,
      currentDayIndex: currentDayIndex,
      isSetupMode: isSetupMode,
      onBack: () => setState(() => _step = _allWirdsPrevStep),
      rangeLabelForDay: (dayIdx) =>
          _service.rangeLabelForDay(dayIdx, daysLocal),
      onDayTap: isSetupMode
          ? (dayIdx) async {
              await _service.startPlanFromDay(daysLocal, dayIdx);
              _load();
            }
          : null,
    );
  }

  Widget _buildCompleted() => KhatmaCompletedView(
        textDirection: _localeDirection,
        reminderEnabled: _reminderEnabled,
        formattedReminderTime: _formatTimeArabic(_reminderTime),
        onRepeat: () async {
          await _service.startPlan(_selectedProgramDays);
          _load();
        },
        onStartNew: () => setState(() => _step = _KhatmaStep.newKhatma),
        onAllWirds: () {
          _allWirdsPrevStep = _KhatmaStep.completed;
          setState(() => _step = _KhatmaStep.allWirds);
        },
        onDelete: () => _confirmResetPlan(context),
        notificationRequirements: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: NotificationRequirementsSection(
            feature: NotificationFeature.khatma,
            onNotificationEnabled: _restoreKhatmaReminder,
          ),
        ),
        onToggleReminder: _toggleReminder,
        onPickReminderTime: _pickReminderTime,
      );

  Future<void> _confirmResetPlan(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _localeDirection,
        child: AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Text(l10n.khatmaDeleteTitle,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(l10n.khatmaDeleteConfirmContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.delete,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await _service.resetPlan();
      _load();
    }
  }
}
