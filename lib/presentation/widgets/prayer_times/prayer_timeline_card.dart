import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:huda/core/services/prayer_moment_resolver.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/utils/hijri_date_utils.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';
import 'package:intl/intl.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';
import 'package:vector_graphics/vector_graphics.dart';

String localizedPrayerName(AppLocalizations l10n, Prayer prayer) =>
    switch (prayer) {
      Prayer.fajr => l10n.fajr,
      Prayer.sunrise => l10n.prayerSunriseLabel,
      Prayer.dhuhr => l10n.dhuhr,
      Prayer.asr => l10n.asr,
      Prayer.maghrib => l10n.maghrib,
      Prayer.isha => l10n.isha,
      Prayer.none => '',
    };

class PrayerTimelineCard extends StatelessWidget {
  const PrayerTimelineCard({
    super.key,
    required this.state,
    required this.now,
    required this.onAdjust,
  });

  final PrayerTimesLoaded state;
  final DateTime now;
  final VoidCallback onAdjust;

  static const _rows = <({Prayer prayer, IconData? icon, String? asset})>[
    (prayer: Prayer.fajr, icon: Icons.wb_twilight, asset: null),
    (
      prayer: Prayer.sunrise,
      icon: null,
      asset: 'assets/images/sunrise.svg.vec',
    ),
    (prayer: Prayer.dhuhr, icon: Icons.wb_sunny_rounded, asset: null),
    (prayer: Prayer.asr, icon: Icons.wb_sunny_outlined, asset: null),
    (prayer: Prayer.maghrib, icon: null, asset: 'assets/images/sunset.svg.vec'),
    (prayer: Prayer.isha, icon: Icons.nights_stay_rounded, asset: null),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final times = state.prayerTimes;
    final day = times.fajr ?? times.dhuhr;
    final nowUtc = now.toUtc();
    final moment = PrayerMomentResolver.resolve(
      now: now,
      transitions: [
        for (final entry in PrayerTimesCalculator.dailyAdjustedInstants(
          times,
          state.offsets,
        ).entries)
          PrayerTransition(prayer: entry.key, instant: entry.value),
      ],
    );

    bool highlighted(int i) => moment?.prayer == _rows[i].prayer;
    final rows = <Widget>[];
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final time = PrayerTimesCalculator.adjustedTimeFor(
        times,
        row.prayer,
        state.offsets,
      );
      final instant = PrayerTimesCalculator.adjustedInstantFor(
        times,
        row.prayer,
        state.offsets,
      );
      if (i > 0) {
        rows.add(
          highlighted(i) || highlighted(i - 1)
              ? const SizedBox(height: 2)
              : Divider(
                  height: 1,
                  thickness: 1,
                  indent: 54,
                  endIndent: 8,
                  color: palette.divider,
                ),
        );
      }
      rows.add(
        _TimelineRow(
          name: localizedPrayerName(l10n, row.prayer),
          time: time == null ? '--:--' : DateFormat.jm(locale).format(time),
          icon: row.icon,
          asset: row.asset,
          marker: row.prayer == Prayer.sunrise,
          highlight: highlighted(i)
              ? (moment!.isElapsed
                    ? l10n.prayerTimelineNow
                    : l10n.prayerTimelineNext)
              : null,
          past: !highlighted(i) && instant != null && instant.isBefore(nowUtc),
          offset: PrayerTimesCalculator.sanitizeOffset(
            state.offsets[PrayerTimesCalculator.keyOf(row.prayer)] ?? 0,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: palette.cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 0, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.today,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: palette.ink,
                        ),
                      ),
                      if (day != null)
                        Text(
                          _dayLine(l10n, locale, day),
                          maxLines: 2,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onAdjust,
                  tooltip: l10n.prayerTimeAdjustment,
                  style: IconButton.styleFrom(
                    backgroundColor: palette.tint,
                    foregroundColor: palette.primary,
                  ),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.tune_rounded, size: 20),
                ),
              ],
            ),
          ),
          ...rows,
        ],
      ),
    );
  }
}

String _dayLine(AppLocalizations l10n, String locale, DateTime day) {
  final hijri = hijriDateFromDateTime(day);
  return '${DateFormat.MMMEd(locale).format(day)} · '
      '${hijri.day} ${hijriMonthName(l10n, hijri.month)} ${hijri.year}';
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.name,
    required this.time,
    required this.icon,
    required this.asset,
    required this.marker,
    required this.highlight,
    required this.past,
    required this.offset,
  });

  final String name;
  final String time;
  final IconData? icon;
  final String? asset;

  final bool marker;

  final String? highlight;
  final bool past;
  final int offset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final active = highlight != null;
    final foreground = active
        ? palette.primary
        : past
        ? palette.faint
        : marker
        ? palette.muted
        : palette.ink;
    final iconColor = active
        ? palette.onPrimary
        : past
        ? palette.faint
        : palette.primary.withValues(alpha: palette.isDark ? 0.9 : 0.75);
    final base = marker
        ? theme.textTheme.bodyMedium
        : theme.textTheme.titleMedium;
    final textStyle = base?.copyWith(
      color: foreground,
      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
    );
    final offsetLabel = offset == 0
        ? null
        : l10n.prayerOffsetBadge(offset > 0 ? '+$offset' : '−${-offset}');

    return Semantics(
      container: true,
      label: [name, time, ?highlight, ?offsetLabel].join(', '),
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: marker ? 8 : (active ? 12 : 11),
        ),
        decoration: BoxDecoration(
          color: active
              ? palette.tintStrong.withValues(
                  alpha: palette.isDark ? 0.34 : 0.16,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Center(
                child: Container(
                  width: active ? 34 : 28,
                  height: active ? 34 : 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? palette.primary : null,
                  ),
                  alignment: Alignment.center,
                  child: asset != null
                      ? SvgPicture(
                          AssetBytesLoader(asset!),
                          width: marker ? 16 : 19,
                          height: marker ? 16 : 19,
                          colorFilter: ColorFilter.mode(
                            iconColor,
                            BlendMode.srcIn,
                          ),
                        )
                      : Icon(icon, size: 19, color: iconColor),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(name, style: textStyle),
                  if (active)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: palette.primary,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        highlight!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  if (offsetLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: palette.tint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        offsetLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: textStyle?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
