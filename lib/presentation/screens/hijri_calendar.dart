import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hijri_plus/hijri_plus.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/services/hijri_calendar_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/hijri_calendar/hijri_calendar_cubit.dart';
import 'package:huda/data/models/hijri_event.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_day.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_format.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_month.dart';
import 'package:huda/presentation/widgets/hijri_calendar/event_dialog.dart';
import 'package:huda/presentation/widgets/hijri_calendar/hijri_adjustment_dialog.dart';
import 'package:huda/presentation/widgets/hijri_calendar/islamic_calendar_event.dart';
import 'package:huda/presentation/widgets/notifications/notification_access_controller.dart';
import 'package:huda/presentation/widgets/notifications/notification_requirements_section.dart';

/// The Hijri calendar: a month of days and the chosen day's plate (its
/// moon, both dates, occasions) with the person's events. One column on
/// phones; the month beside the day from 840 and on open folds; the month
/// above a tabletop fold. Reads the route's [HijriCalendarCubit].
class HijriCalendarScreenNew extends StatefulWidget {
  const HijriCalendarScreenNew({
    super.key,
    this.calendarService,
    this.debugClock,
    this.debugAccess,
  });

  final HijriCalendarService? calendarService;

  /// The device matrix's fixed "now".
  final DateTime Function()? debugClock;

  /// The device matrix's notification access (no plugins).
  final NotificationAccessController Function()? debugAccess;

  @override
  State<HijriCalendarScreenNew> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreenNew> {
  late final HijriCalendarService _service =
      widget.calendarService ?? getIt<HijriCalendarService>();
  late final NotificationAccessController? _access = widget.debugAccess?.call();

  /// The chosen day, kept as a Gregorian date so an adjustment keeps it.
  late DateTime _day;
  late HijriDate _selected;
  late HijriDate _month;
  late HijriDate _today;

  /// +1 when the last month change went later, −1 earlier.
  int _direction = 1;
  bool _ready = false;

  DateTime _now() => widget.debugClock?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onCalendarChanged);
    final now = _now();
    _day = DateTime(now.year, now.month, now.day);
    _sync();
    _service.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _ready = true;
        _sync();
      });
    });
  }

  @override
  void dispose() {
    _service.removeListener(_onCalendarChanged);
    _access?.dispose();
    super.dispose();
  }

  /// Hijri dates from the Gregorian ones, after an adjustment too.
  void _sync() {
    final now = _now();
    _today = _service.toHijri(DateTime(now.year, now.month, now.day));
    _selected = _service.toHijri(_day);
    _month = HijriDate(_selected.year, _selected.month, 1);
  }

  void _onCalendarChanged() {
    if (mounted) setState(_sync);
  }

  DateTime _gregorian(HijriDate date) {
    try {
      return _service.toGregorian(date);
    } catch (_) {
      return _day;
    }
  }

  void _select(HijriDate date) {
    if (date == _selected) return;
    setState(() {
      _selected = date;
      _day = _gregorian(date);
    });
  }

  void _turn(int by) {
    var year = _month.year;
    var month = _month.month + by;
    if (month < 1) {
      month = 12;
      year--;
    } else if (month > 12) {
      month = 1;
      year++;
    }
    setState(() {
      _direction = by;
      _month = HijriDate(year, month, 1);
      // The selection moves with the month: the same day where it exists.
      final day = math.min(_selected.day, _service.daysInMonth(year, month));
      _selected = HijriDate(year, month, day);
      _day = _gregorian(_selected);
    });
  }

  void _goToToday() {
    final now = _now();
    final day = DateTime(now.year, now.month, now.day);
    setState(() {
      _direction = day.isBefore(_day) ? -1 : 1;
      _day = day;
      _sync();
    });
  }

  Future<void> _adjust() => showHijriAdjustmentSheet(
    context,
    initialChoice: _service.adjustmentChoice,
    onSave: _service.setAdjustmentChoice,
  );

  String get _dateLabel {
    final format = CalendarFormat.of(context);
    return '${format.hijriDate(_selected)} · '
        '${format.gregorianDate(_gregorian(_selected))}';
  }

  Future<void> _openEvent([HijriEvent? event]) async {
    final cubit = context.read<HijriCalendarCubit>();
    final l10n = AppLocalizations.of(context)!;
    final day = _gregorian(_selected);
    final result = await showEventSheet(
      context,
      dateLabel: _dateLabel,
      event: event,
    );
    if (!mounted || result == null) return;
    switch (result) {
      case EventSaved(event: final saved) when event != null:
        _reportScheduling(await cubit.editEvent(day, saved));
      case EventSaved(event: final saved):
        _reportScheduling(await cubit.addEvent(day, saved));
      case EventDeleted() when event != null:
        cubit.removeEvent(day, event);
        if (!mounted) return;
        HudaHaptics.light(context);
        showHudaToast(
          context,
          message: l10n.calendarEventDeleted,
          actionLabel: l10n.undo,
          onAction: () => cubit.addEvent(day, event).then(_reportScheduling),
        );
      case EventDeleted():
        break;
    }
  }

  void _reportScheduling(bool scheduled) {
    if (scheduled || !mounted) return;
    showHudaToast(
      context,
      message: AppLocalizations.of(context)!.notificationScheduleFailed,
      kind: HudaToastKind.failed,
    );
  }

  List<Widget> _actions(AppLocalizations l10n) => [
    IconButton(
      key: const ValueKey('calendar-today'),
      tooltip: l10n.today,
      onPressed: _goToToday,
      icon: const Icon(Icons.today_rounded),
    ),
    IconButton(
      key: const ValueKey('hijri-adjustment-action'),
      tooltip: l10n.hijriAdjustmentAction,
      onPressed: _adjust,
      icon: const Icon(Icons.tune_rounded),
    ),
  ];

  /// A scroll view whose content keeps a readable width, centered.
  Widget _scroll(List<Widget> children, {double maxWidth = 760}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final space = context.tokens.space;
        final width = constraints.maxWidth;
        final side = math.max(space.gutter(width), (width - maxWidth) / 2);
        return ListView(
          padding: context.scrollPadding(
            EdgeInsets.fromLTRB(side, space.sm, side, space.xxl),
          ),
          children: children,
        );
      },
    );
  }

  Widget? _prompt() {
    if (!_ready || _service.hasAdjustmentChoice) return null;
    return HudaReveal(
      child: Padding(
        padding: EdgeInsets.only(bottom: context.tokens.space.md),
        child: HijriAdjustmentPrompt(
          onUseAutomatic: () =>
              _service.setAdjustmentChoice(HijriAdjustmentChoice.automatic),
          onAdjust: _adjust,
        ),
      ),
    );
  }

  Widget _monthCard(HijriCalendarState state, {double minCellHeight = 0}) =>
      CalendarMonthCard(
        dense: context.windowClass.isCompactHeight,
        month: _month,
        service: _service,
        selected: _selected,
        today: _today,
        events: state.events,
        direction: _direction,
        onSelect: _select,
        onPrevious: () => _turn(-1),
        onNext: () => _turn(1),
        minCellHeight: minCellHeight,
      );

  List<Widget> _dayChildren(HijriCalendarState state) {
    final space = context.tokens.space;
    final events =
        state.events[HijriCalendarService.eventKey(_selected)] ?? const [];
    return [
      HudaReveal(
        index: 1,
        child: CalendarDayPlate(
          date: _selected,
          gregorian: _gregorian(_selected),
          isToday: _selected == _today,
          occasions: IslamicCalendarEvents.forDate(_selected),
        ),
      ),
      SizedBox(height: space.lg),
      HudaReveal(
        index: 2,
        child: CalendarEventsSection(
          dayKey: HijriCalendarService.eventKey(_selected),
          events: events,
          onAdd: _openEvent,
          onOpen: _openEvent,
        ),
      ),
      SizedBox(height: space.md),
      NotificationRequirementsSection(
        feature: NotificationFeature.hijriCalendar,
        controller: _access,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<HijriCalendarCubit>().state;
    final space = context.tokens.space;
    final width = MediaQuery.sizeOf(context).width;
    final fold = FoldInfo.of(context);
    final prompt = _prompt();
    // Short windows get dense rows (`_monthCard`); below 840 the month
    // keeps the width: beside the Duo's side column a split leaves cells
    // too narrow to tap.
    const twoPaneMinWidth = 840.0;

    if (AdaptivePanes.showsTwoPanes(
      width,
      fold,
      twoPaneMinWidth: twoPaneMinWidth,
    )) {
      return HudaRevealScope(
        child: HudaScaffold(
          title: l10n.hijriCalendar,
          actions: _actions(l10n),
          body: AdaptivePanes(
            twoPaneMinWidth: twoPaneMinWidth,
            primaryFraction: 0.6,
            minPrimaryWidth: 440,
            maxPrimaryWidth: 920,
            primary: LayoutBuilder(
              builder: (context, constraints) {
                // Rows grow to fill the pane's height, then the page scrolls.
                final room =
                    constraints.maxHeight -
                    space.sm -
                    space.xxl -
                    context.bottomInset -
                    CalendarMonthCard.chromeHeight(context) -
                    (prompt == null ? 0 : 180) -
                    // The month's key of occasions under the grid.
                    (IslamicCalendarEvents.all.any(
                          (o) => o.hijriMonth == _month.month,
                        )
                        ? 72
                        : 0);
                final cell = (room / 6).clamp(0.0, 132.0); // six weeks fit
                return _scroll([
                  ?prompt,
                  HudaReveal(child: _monthCard(state, minCellHeight: cell)),
                ], maxWidth: 920);
              },
            ),
            secondary: _scroll(_dayChildren(state), maxWidth: 560),
          ),
        ),
      );
    }

    if (TabletopSplit.applies(context)) {
      return HudaRevealScope(
        child: TabletopSplit(
          top: HudaScaffold(
            title: l10n.hijriCalendar,
            actions: _actions(l10n),
            body: _scroll([?prompt, HudaReveal(child: _monthCard(state))]),
          ),
          bottom: Scaffold(
            backgroundColor: Colors.transparent,
            body: _scroll(_dayChildren(state)),
          ),
        ),
      );
    }

    return HudaRevealScope(
      child: HudaScaffold(
        title: l10n.hijriCalendar,
        actions: _actions(l10n),
        body: _scroll([
          ?prompt,
          // Tablets in portrait: rows tall enough to name the day's events.
          HudaReveal(
            child: _monthCard(state, minCellHeight: width >= 600 ? 84 : 0),
          ),
          SizedBox(height: space.lg),
          ..._dayChildren(state),
        ]),
      ),
    );
  }
}
