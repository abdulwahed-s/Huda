import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_format.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_identity.dart';
import 'package:huda/presentation/widgets/ramadan/fasting_progress_widget.dart';

class RamadanPlate extends StatelessWidget {
  const RamadanPlate({
    super.key,
    required this.isRamadan,
    required this.currentDay,
    required this.daysUntilRamadan,
    required this.hijriYear,
    required this.fajrTime,
    required this.maghribTime,
    this.clock,
  });

  final bool isRamadan;
  final int currentDay;
  final int daysUntilRamadan;
  final int hijriYear;
  final DateTime fajrTime;
  final DateTime maghribTime;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final space = tokens.space;
    final format = CalendarFormat.of(context);
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.4;

    return DecoratedBox(
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
                CalendarMoon(
                  day: isRamadan ? currentDay : 1,
                  size: large || MediaQuery.sizeOf(context).width < 400
                      ? 56
                      : 76,
                  onChrome: true,
                ),
                SizedBox(width: space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (isRamadan
                                ? l10n.ramadanYearLabel(
                                    format.number(hijriYear),
                                  )
                                : l10n.ramadan)
                            .toUpperCase(),
                        style: context.type.eyebrow.copyWith(
                          color: tokens.gilt,
                        ),
                      ),
                      SizedBox(height: space.xxs),
                      Text(
                        isRamadan
                            ? l10n.ramadanDayLabel(currentDay)
                            : l10n.daysUntilRamadan(daysUntilRamadan),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: tokens.onChrome,
                        ),
                      ),
                      if (isRamadan)
                        Text(
                          '${format.number(currentDay)} / ${format.number(30)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: tokens.onChromeMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: space.lg),
              child: Divider(
                height: 1,
                thickness: tokens.stroke.hairline,
                color: tokens.gilt.withValues(alpha: 0.28),
              ),
            ),
            RamadanFast(
              isRamadan: isRamadan,
              fajrTime: fajrTime,
              maghribTime: maghribTime,
              clock: clock,
            ),
          ],
        ),
      ),
    );
  }
}
