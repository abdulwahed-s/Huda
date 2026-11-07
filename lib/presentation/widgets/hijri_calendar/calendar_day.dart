import 'package:flutter/material.dart';
import 'package:hijri_plus/hijri_plus.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/hijri_event.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_format.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_identity.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_month.dart';
import 'package:huda/presentation/widgets/hijri_calendar/islamic_calendar_event.dart';

/// The day plate, the calendar's signature: the day's moon in luminous
/// gilt on the chrome beside the date in both calendars, and the day's
/// occasions. Another day turns the moon to its phase and the words
/// cross-fade.
class CalendarDayPlate extends StatelessWidget {
  const CalendarDayPlate({
    super.key,
    required this.date,
    required this.gregorian,
    required this.isToday,
    required this.occasions,
  });

  final HijriDate date;
  final DateTime gregorian;
  final bool isToday;
  final List<IslamicCalendarEvent> occasions;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final format = CalendarFormat.of(context);
    final l10n = AppLocalizations.of(context)!;
    final scaler = MediaQuery.textScalerOf(context);
    final narrow = MediaQuery.sizeOf(context).width < 400;
    final moon = scaler.scale(1) > 1.4 || narrow ? 56.0 : 76.0;
    final weekday = format.weekday(gregorian);

    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (isToday ? '${l10n.today} · $weekday' : weekday).toUpperCase(),
          style: context.type.eyebrow.copyWith(color: tokens.gilt),
        ),
        SizedBox(height: space.xxs),
        Text(
          format.hijriDate(date),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: tokens.onChrome,
          ),
        ),
        Text(
          format.gregorianDate(gregorian),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: tokens.onChromeMuted,
          ),
        ),
      ],
    );

    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: tokens.chromeGradient,
          borderRadius: tokens.radius.card,
        ),
        child: Padding(
          padding: EdgeInsets.all(space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CalendarMoon(day: date.day, size: moon, onChrome: true),
                  SizedBox(width: space.lg),
                  Expanded(
                    child: HudaStateSwitcher(
                      stateKey: '${date.year}-${date.month}-${date.day}',
                      alignment: AlignmentDirectional.centerStart,
                      sequential: true,
                      child: words,
                    ),
                  ),
                ],
              ),
              HudaStateSwitcher(
                stateKey: occasions.map((o) => o.eventKey).join(','),
                sequential: true,
                child: occasions.isEmpty
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: EdgeInsets.only(top: space.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final occasion in occasions)
                              _Occasion(occasion: occasion),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Occasion extends StatelessWidget {
  const _Occasion({required this.occasion});

  final IslamicCalendarEvent occasion;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: EdgeInsets.only(top: space.xs),
      padding: EdgeInsets.only(top: space.sm),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: tokens.gilt.withValues(alpha: 0.28),
            width: tokens.stroke.hairline,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(occasion.icon, size: 20, color: tokens.gilt),
          ),
          SizedBox(width: space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  occasionTitle(l10n, occasion.eventKey),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: tokens.onChrome,
                  ),
                ),
                Text(
                  occasionSubtitle(l10n, occasion.eventKey),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.onChromeMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The person's events on the selected day, with the one Add event
/// button. A row opens its sheet (edit, delete).
class CalendarEventsSection extends StatelessWidget {
  const CalendarEventsSection({
    super.key,
    required this.events,
    required this.onAdd,
    required this.onOpen,
    required this.dayKey,
  });

  final List<HijriEvent> events;
  final VoidCallback onAdd;
  final ValueChanged<HijriEvent> onOpen;

  /// Cross-fades the list when the day changes.
  final String dayKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final space = context.tokens.space;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HudaSectionHeader(
          l10n.calendarYourEvents,
          trailing: TextButton.icon(
            key: const ValueKey('calendar-add-event'),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.addEvent),
          ),
        ),
        HudaStateSwitcher(
          stateKey: '$dayKey/${events.map((e) => e.id).join(',')}',
          sequential: true,
          child: events.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: space.xs),
                  child: Text(
                    l10n.noEventsForThisDate,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : HudaCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < events.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            indent: space.md,
                            endIndent: space.md,
                          ),
                        _EventRow(
                          event: events[i],
                          onTap: () => onOpen(events[i]),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.onTap});

  final HijriEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final l10n = AppLocalizations.of(context)!;
    final format = CalendarFormat.of(context);
    final start = event.startTime;
    final end = event.endTime;
    final when = event.isAllDay || start == null
        ? l10n.allDay
        : end == null
        ? format.time(start)
        : '${format.time(start)} – ${format.time(end)}';
    return InkWell(
      key: ValueKey('calendar-event-${event.id}'),
      onTap: onTap,
      borderRadius: tokens.radius.card,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: space.md,
            vertical: space.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(event.colorValue),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: theme.textTheme.titleSmall),
                    SizedBox(height: space.xxs / 2),
                    Wrap(
                      spacing: space.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          when,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (event.notify)
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 16,
                            semanticLabel: l10n.receiveNotification,
                            color: scheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                    if (event.description.isNotEmpty) ...[
                      SizedBox(height: space.xxs),
                      Text(
                        event.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: space.xs),
              Icon(
                Icons.edit_outlined,
                size: 20,
                semanticLabel: l10n.editEvent,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
