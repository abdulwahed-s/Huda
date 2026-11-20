import 'package:flutter/material.dart';
import 'package:hijri_plus/hijri_plus.dart';
import 'package:huda/core/services/hijri_calendar_service.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/hijri_event.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_format.dart';
import 'package:huda/presentation/widgets/hijri_calendar/islamic_calendar_event.dart';

class CalendarMonthCard extends StatelessWidget {
  const CalendarMonthCard({
    super.key,
    required this.month,
    required this.service,
    required this.selected,
    required this.today,
    required this.events,
    required this.direction,
    required this.onSelect,
    required this.onPrevious,
    required this.onNext,
    this.minCellHeight = 0,
    this.dense = false,
  });

  final HijriDate month;
  final HijriCalendarService service;
  final HijriDate selected;
  final HijriDate today;

  final Map<String, List<HijriEvent>> events;
  final int direction;
  final ValueChanged<HijriDate> onSelect;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  final double minCellHeight;

  final bool dense;

  static double chromeHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    final space = context.tokens.space;
    return space.sm * 2 +
        48 +
        scaler.scale(13) * 1.3 +
        space.xs +
        scaler.scale(12) * 1.3 +
        space.sm +
        space.xs * 2 +
        space.xxs * 5;
  }

  static double naturalCellHeight(BuildContext context, {bool dense = false}) {
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    if (dense) return scaler.scale(17) * 1.4 + scaler.scale(12) + 18;
    return scaler.scale(17) * 1.4 +
        scaler.scale(12) * 1.4 +
        scaler.scale(12) +
        18;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final format = CalendarFormat.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final material = MaterialLocalizations.of(context);
    final first = _gregorian(month);
    final last = _gregorian(
      HijriDate(
        month.year,
        month.month,
        service.daysInMonth(month.year, month.month),
      ),
    );
    final natural = naturalCellHeight(context, dense: dense);
    final cellHeight = natural > minCellHeight ? natural : minCellHeight;

    void swipe(DragEndDetails details) {
      final v = details.primaryVelocity ?? 0;
      if (v.abs() < 250) return;
      final next = rtl ? v > 0 : v < 0;
      next ? onNext() : onPrevious();
    }

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: HudaCard(
        padding: EdgeInsets.fromLTRB(space.xs, space.sm, space.xs, space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  key: const ValueKey('calendar-previous-month'),
                  tooltip: material.previousMonthTooltip,
                  onPressed: onPrevious,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: _Slide(
                    keyValue: _monthKey,
                    direction: direction,
                    child: Semantics(
                      liveRegion: true,
                      child: Column(
                        children: [
                          Text(
                            format.hijriMonthYear(month),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            format.gregorianSpan(first, last),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('calendar-next-month'),
                  tooltip: material.nextMonthTooltip,
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            SizedBox(height: space.xs),
            _Weekdays(firstDay: format.firstDayOfWeek),
            SizedBox(height: space.xs),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: swipe,
              child: _EaseSize(
                child: _Slide(
                  keyValue: _monthKey,
                  direction: direction,
                  distance: 0.3,
                  child: _Grid(
                    month: month,
                    service: service,
                    selected: selected,
                    today: today,
                    events: events,
                    cellHeight: cellHeight,
                    dense: dense,
                    firstDay: format.firstDayOfWeek,
                    onSelect: onSelect,
                  ),
                ),
              ),
            ),
            _EaseSize(
              child: _Slide(
                keyValue: _monthKey,
                direction: direction,
                child: _OccasionKey(
                  month: month,
                  days: service.daysInMonth(month.year, month.month),
                  selected: selected,
                  onSelect: onSelect,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _monthKey => '${month.year}-${month.month}';

  DateTime _gregorian(HijriDate date) {
    try {
      return service.toGregorian(date);
    } catch (_) {
      return DateTime.now();
    }
  }
}

class _EaseSize extends StatelessWidget {
  const _EaseSize({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final duration = tokens.motion.of(context, tokens.motion.long);
    final clipped = ClipRect(child: child);
    if (duration == Duration.zero) return clipped;
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: clipped,
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.keyValue,
    required this.direction,
    required this.child,
    this.distance = 0.15,
  });

  final String keyValue;
  final int direction;
  final double distance;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final sign = (direction >= 0 ? 1.0 : -1.0) * (rtl ? -1 : 1);
    final key = ValueKey(keyValue);
    return AnimatedSwitcher(
      duration: tokens.motion.of(context, tokens.motion.long),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        final incoming = child.key == key;
        final fade = CurvedAnimation(
          parent: animation,
          curve: incoming ? const Interval(0.35, 1) : const Interval(0.5, 1),
        );
        final offset = Tween<Offset>(
          begin: Offset((incoming ? 1 : -1) * sign * distance, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: KeyedSubtree(key: key, child: child),
    );
  }
}

class _Weekdays extends StatelessWidget {
  const _Weekdays({required this.firstDay});

  final int firstDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = CalendarFormat.of(context);
    final sunday = DateTime(2026, 11, 1);
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Builder(
                builder: (context) {
                  final date = sunday.add(Duration(days: (firstDay + i) % 7));
                  final friday = date.weekday == DateTime.friday;
                  return Text(
                    format.weekdayShort(date),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: friday
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: friday ? FontWeight.w700 : null,
                      letterSpacing: 0.4,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.month,
    required this.service,
    required this.selected,
    required this.today,
    required this.events,
    required this.cellHeight,
    required this.dense,
    required this.firstDay,
    required this.onSelect,
  });

  final HijriDate month;
  final HijriCalendarService service;
  final HijriDate selected;
  final HijriDate today;
  final Map<String, List<HijriEvent>> events;
  final double cellHeight;
  final bool dense;
  final int firstDay;
  final ValueChanged<HijriDate> onSelect;

  bool _startsRun(int day) {
    String? key(int d) {
      if (d < 1) return null;
      final list = IslamicCalendarEvents.forDate(
        HijriDate(month.year, month.month, d),
      );
      return list.isEmpty ? null : primaryOccasion(list).eventKey;
    }

    return key(day) != key(day - 1);
  }

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final days = service.daysInMonth(month.year, month.month);
    DateTime gregorian(int day) {
      try {
        return service.toGregorian(HijriDate(month.year, month.month, day));
      } catch (_) {
        return DateTime.now();
      }
    }

    final first = gregorian(1);
    final lead = (first.weekday % 7 - firstDay) % 7;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - space.xxs * 6) / 7;
        final detailed =
            cellWidth >= 88 &&
            cellHeight >= CalendarMonthCard.naturalCellHeight(context) + 10;
        final weeks = ((lead + days) / 7).ceil();
        return Column(
          children: [
            for (var week = 0; week < weeks; week++)
              Padding(
                padding: EdgeInsets.only(top: week == 0 ? 0 : space.xxs),
                child: SizedBox(
                  height: cellHeight,
                  child: Row(
                    children: [
                      for (var col = 0; col < 7; col++) ...[
                        if (col > 0) SizedBox(width: space.xxs),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final day = week * 7 + col - lead + 1;
                              if (day < 1 || day > days) {
                                return const SizedBox.shrink();
                              }
                              final date = HijriDate(
                                month.year,
                                month.month,
                                day,
                              );
                              return CalendarDayCell(
                                key: ValueKey('calendar-day-$day'),
                                date: date,
                                gregorian: gregorian(day),
                                selected: date == selected,
                                today: date == today,
                                events:
                                    events[HijriCalendarService.eventKey(
                                      date,
                                    )] ??
                                    const [],
                                occasions: IslamicCalendarEvents.forDate(date),
                                startsRun: _startsRun(day),
                                detailed: detailed,
                                dense: dense,
                                onTap: () => onSelect(date),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.date,
    required this.gregorian,
    required this.selected,
    required this.today,
    required this.events,
    required this.occasions,
    required this.detailed,
    required this.onTap,
    this.dense = false,
    this.startsRun = true,
  });

  final bool startsRun;
  final HijriDate date;
  final DateTime gregorian;
  final bool selected;
  final bool today;
  final List<HijriEvent> events;
  final List<IslamicCalendarEvent> occasions;
  final bool detailed;

  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final format = CalendarFormat.of(context);
    final l10n = AppLocalizations.of(context)!;
    final radius = BorderRadius.circular(tokens.radius.md);
    final ink = selected ? tokens.onChrome : scheme.onSurface;
    final muted = selected ? tokens.onChromeMuted : scheme.onSurfaceVariant;

    final label = [
      format.hijriDate(date),
      '${format.weekday(gregorian)} ${format.gregorianDate(gregorian)}',
      if (today) l10n.today,
      for (final occasion in occasions) occasionTitle(l10n, occasion.eventKey),
      if (events.isNotEmpty) l10n.calendarEventsCount(events.length),
    ].join(', ');

    final markSize = MediaQuery.textScalerOf(context).scale(12);
    final markColor = selected ? tokens.onChrome : scheme.tertiary;
    final occasion = occasions.isEmpty ? null : primaryOccasion(occasions);
    final marks = <Widget>[
      if (occasion != null)
        Icon(occasion.icon, size: markSize, color: markColor),
      for (final event in events.take(3))
        _Dot(color: Color(event.colorValue), ring: selected),
    ];

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: tokens.motion.of(context, tokens.motion.short),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? tokens.lit : Colors.transparent,
          borderRadius: radius,
          border: Border.all(
            color: today && !selected ? scheme.primary : Colors.transparent,
            width: tokens.stroke.fine,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Stack(
              children: [
                if (occasion != null && detailed)
                  PositionedDirectional(
                    top: space.xxs,
                    end: space.xxs,
                    child: Icon(
                      occasion.icon,
                      size: markSize + 2,
                      color: markColor,
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: space.xxs,
                    vertical: detailed ? space.xxs : space.xxs + 2,
                  ),
                  child: Column(
                    mainAxisAlignment: detailed
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    crossAxisAlignment: detailed
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            format.number(date.day),
                            style: theme.textTheme.titleMedium?.copyWith(
                              height: 1.2,
                              color: today && !selected ? scheme.primary : ink,
                              fontWeight: selected || today
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          if (detailed) ...[
                            SizedBox(width: space.xs),
                            Text(
                              format.number(gregorian.day),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (!detailed && !dense)
                        Text(
                          format.number(gregorian.day),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: muted,
                            letterSpacing: 0,
                            height: 1.2,
                          ),
                        ),
                      if (detailed)
                        ..._titles(context, ink: ink, muted: muted)
                      else ...[
                        SizedBox(height: dense ? 1 : 3),
                        SizedBox(
                          height: markSize,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < marks.length; i++) ...[
                                if (i > 0) const SizedBox(width: 3),
                                marks[i],
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _titles(
    BuildContext context, {
    required Color ink,
    required Color muted,
  }) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context)!;
    final style = theme.textTheme.labelSmall?.copyWith(
      color: ink,
      letterSpacing: 0,
    );
    return [
      const SizedBox(height: 2),
      Expanded(
        child: ClipRect(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final occasion in [
                if (occasions.isNotEmpty && startsRun)
                  primaryOccasion(occasions),
              ])
                Text(
                  occasionTitle(l10n, occasion.eventKey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style?.copyWith(
                    color: selected
                        ? tokens.onChrome
                        : theme.colorScheme.tertiary,
                  ),
                ),
              for (final event in events)
                Row(
                  children: [
                    _Dot(color: Color(event.colorValue), ring: selected),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ];
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.ring});

  final Color color;
  final bool ring;

  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: ring
          ? Border.all(color: context.tokens.onChrome, width: 0.75)
          : null,
    ),
  );
}

IslamicCalendarEvent primaryOccasion(List<IslamicCalendarEvent> occasions) {
  final sorted = [...occasions]
    ..sort(
      (a, b) => (a.hijriDayEnd - a.hijriDayStart).compareTo(
        b.hijriDayEnd - b.hijriDayStart,
      ),
    );
  return sorted.first;
}

class _OccasionKey extends StatelessWidget {
  const _OccasionKey({
    required this.month,
    required this.days,
    required this.selected,
    required this.onSelect,
  });

  final HijriDate month;
  final int days;
  final HijriDate selected;
  final ValueChanged<HijriDate> onSelect;

  @override
  Widget build(BuildContext context) {
    final occasions =
        IslamicCalendarEvents.all
            .where((o) => o.hijriMonth == month.month)
            .toList()
          ..sort((a, b) {
            final start = a.hijriDayStart.compareTo(b.hijriDayStart);
            return start != 0
                ? start
                : (a.hijriDayEnd - a.hijriDayStart).compareTo(
                    b.hijriDayEnd - b.hijriDayStart,
                  );
          });
    if (occasions.isEmpty) return const SizedBox(width: double.infinity);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final format = CalendarFormat.of(context);
    final l10n = AppLocalizations.of(context)!;
    final radius = BorderRadius.circular(tokens.radius.md);
    return Padding(
      padding: EdgeInsets.only(top: space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(
            height: 1,
            indent: space.xs,
            endIndent: space.xs,
            color: scheme.outlineVariant,
          ),
          SizedBox(height: space.xxs),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 340 ? 2 : 1;
              final width =
                  (constraints.maxWidth - space.xxs * (columns - 1)) / columns;
              return Wrap(
                spacing: space.xxs,
                children: [
                  for (final occasion in occasions)
                    SizedBox(
                      width: width,
                      child: Builder(
                        builder: (context) {
                          final end = occasion.hijriDayEnd.clamp(1, days);
                          final range = end == occasion.hijriDayStart
                              ? format.number(end)
                              : '\u2066${format.number(occasion.hijriDayStart)}\u2060–\u2060'
                                    '${format.number(end)}\u2069';
                          final on =
                              selected.month == month.month &&
                              selected.year == month.year &&
                              occasion.occursOn(selected);
                          return Material(
                            color: on
                                ? scheme.tertiary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: radius,
                            child: InkWell(
                              key: ValueKey(
                                'calendar-key-${occasion.eventKey}',
                              ),
                              borderRadius: radius,
                              onTap: () => onSelect(
                                HijriDate(
                                  month.year,
                                  month.month,
                                  occasion.hijriDayStart,
                                ),
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: space.xs,
                                    vertical: space.xxs,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        occasion.icon,
                                        size: MediaQuery.textScalerOf(
                                          context,
                                        ).scale(16),
                                        color: scheme.tertiary,
                                      ),
                                      SizedBox(width: space.xs),
                                      Flexible(
                                        child: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: occasionTitle(
                                                  l10n,
                                                  occasion.eventKey,
                                                ),
                                              ),
                                              TextSpan(
                                                text: '\u00A0\u00A0$range',
                                                style: TextStyle(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

String occasionTitle(AppLocalizations l10n, String key) => switch (key) {
  'ramadan' => l10n.calendarEventFirstDayRamadan,
  'last_ten_ramadan' => l10n.eventLastTenRamadan,
  'eid_al_fitr' => l10n.calendarEventEidAlFitr,
  'eid_al_adha' => l10n.calendarEventEidAlAdha,
  'day_of_arafah' => l10n.eventDayOfArafah,
  'first_ten_dhul_hijjah' => l10n.eventFirstTenDhulHijjah,
  'ashura' => l10n.eventAshura,
  'days_of_tashreeq' => l10n.eventDaysTashreeq,
  _ => l10n.eventSpecialOccasion,
};

String occasionSubtitle(AppLocalizations l10n, String key) => switch (key) {
  'ramadan' => l10n.eventRamadanSubtitle,
  'last_ten_ramadan' => l10n.eventLastTenRamadanSubtitle,
  'eid_al_fitr' => l10n.eventEidAlFitrSubtitle,
  'eid_al_adha' => l10n.eventEidAlAdhaSubtitle,
  'day_of_arafah' => l10n.eventDayOfArafahSubtitle,
  'first_ten_dhul_hijjah' => l10n.eventFirstTenDhulHijjahSubtitle,
  'ashura' => l10n.eventAshuraSubtitle,
  'days_of_tashreeq' => l10n.eventDaysTashreeqSubtitle,
  _ => l10n.eventSpecialOccasionSubtitle,
};
