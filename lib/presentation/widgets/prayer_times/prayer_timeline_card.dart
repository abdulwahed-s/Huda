import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alerts.dart';
import 'package:huda/core/services/prayer_moment_resolver.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_labels.dart';
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
    this.alerts,
    this.onOpenAlerts,
    this.alertsBlocked = false,
  });

  final bool alertsBlocked;

  final PrayerTimesLoaded state;
  final DateTime now;

  final PrayerAlertSettings? alerts;

  final void Function(String prayer)? onOpenAlerts;

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

  static bool fitsStrip(BuildContext context, double width) =>
      width >= 6 * MediaQuery.textScalerOf(context).scale(100);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final times = state.prayerTimes;
    final nowUtc = now.toUtc();
    final moment = PrayerMomentResolver.resolve(
      now: now,
      iqamah: state.iqamahSettings,
      transitions: [
        for (final entry in PrayerTimesCalculator.dailyAdjustedInstants(
          times,
          state.offsets,
        ).entries)
          PrayerTransition(prayer: entry.key, instant: entry.value),
      ],
    );

    final entries = [
      for (final row in _rows)
        () {
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
          final lit = moment?.prayer == row.prayer;
          final offset = PrayerTimesCalculator.sanitizeOffset(
            state.offsets[PrayerTimesCalculator.keyOf(row.prayer)] ?? 0,
          );
          final key = PrayerTimesCalculator.keyOf(row.prayer);
          final alert = row.prayer == Prayer.sunrise
              ? null
              : alerts?.prayers[key];
          return _Entry(
            prayer: row.prayer,
            key: key,
            name: localizedPrayerName(l10n, row.prayer),
            time: time == null ? '--:--' : DateFormat.jm(locale).format(time),
            icon: row.icon,
            asset: row.asset,
            marker: row.prayer == Prayer.sunrise,
            highlight: lit
                ? (moment!.isElapsed
                      ? l10n.prayerTimelineNow
                      : l10n.prayerTimelineNext)
                : null,
            past: !lit && instant != null && instant.isBefore(nowUtc),
            offset: offset == 0
                ? null
                : l10n.prayerOffsetBadge(
                    offset > 0 ? '+$offset' : '−${-offset}',
                  ),
            alertStyle: row.prayer == Prayer.sunrise
                ? null
                : alertsBlocked
                ? PrayerAlertStyle.off
                : (alerts == null
                      ? null
                      : (alerts!.enabled
                            ? (alert?.style ?? alerts!.style)
                            : PrayerAlertStyle.off)),
            alertCustom: alert?.custom ?? false,
          );
        }(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final strip = fitsStrip(context, constraints.maxWidth);
        return Card(
          key: const ValueKey('prayer-day-times'),
          child: Padding(
            padding: EdgeInsets.all(context.tokens.space.xs),
            child: strip
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final entry in entries)
                          Expanded(
                            flex: 1,
                            child: _StationTile(
                              entry: entry,
                              onOpenAlerts: onOpenAlerts,
                            ),
                          ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final entry in entries)
                        _TimelineRow(entry: entry, onOpenAlerts: onOpenAlerts),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _Entry {
  const _Entry({
    required this.prayer,
    required this.key,
    required this.name,
    required this.time,
    required this.icon,
    required this.asset,
    required this.marker,
    required this.highlight,
    required this.past,
    required this.offset,
    required this.alertStyle,
    required this.alertCustom,
  });

  final Prayer prayer;
  final String key;
  final String name;
  final String time;
  final IconData? icon;
  final String? asset;

  final bool marker;
  final String? highlight;
  final bool past;
  final String? offset;
  final PrayerAlertStyle? alertStyle;
  final bool alertCustom;

  bool get lit => highlight != null;

  String semantics(AppLocalizations l10n, Object? _) =>
      [name, time, ?highlight, ?offset].join(', ');
}

Color _foreground(BuildContext context, _Entry entry) {
  final scheme = Theme.of(context).colorScheme;
  return entry.lit
      ? scheme.primary
      : entry.past || entry.marker
      ? scheme.onSurfaceVariant
      : scheme.onSurface;
}

class _Mark extends StatelessWidget {
  const _Mark({required this.entry});

  final _Entry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = entry.lit
        ? scheme.onPrimary
        : entry.past
        ? scheme.onSurfaceVariant
        : scheme.primary;
    final size = entry.marker ? 16.0 : 19.0;
    return AnimatedContainer(
      duration: context.tokens.motion.of(context, context.tokens.motion.medium),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: entry.lit ? scheme.primary : null,
      ),
      alignment: Alignment.center,
      child: entry.asset != null
          ? SvgPicture(
              AssetBytesLoader(entry.asset!),
              width: size,
              height: size,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            )
          : Icon(entry.icon, size: size, color: color),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, {this.lit = false});

  final String label;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space.xs,
        vertical: tokens.space.xxs / 2,
      ),
      decoration: BoxDecoration(
        color: lit ? scheme.primary : scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(tokens.radius.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: lit ? scheme.onPrimary : scheme.primary,
        ),
      ),
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({required this.entry, required this.onOpenAlerts});

  final _Entry entry;
  final void Function(String prayer)? onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    final style = entry.alertStyle;
    if (entry.marker || onOpenAlerts == null) {
      return const SizedBox(width: 48, height: 48);
    }
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final off = style == PrayerAlertStyle.off;
    return IconButton(
      key: ValueKey('prayer-alert-bell-${entry.key}'),
      tooltip: l10n.prayerAlertFor(entry.name),
      onPressed: () => onOpenAlerts!(entry.key),
      icon: Icon(
        style == null
            ? Icons.notifications_none_rounded
            : prayerAlertStyleIcon(style),
        size: 20,
        color: off
            ? scheme.onSurfaceVariant
            : entry.alertCustom || entry.lit
            ? scheme.primary
            : scheme.onSurfaceVariant,
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.onOpenAlerts});

  final _Entry entry;
  final void Function(String prayer)? onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context)!;
    final foreground = _foreground(context, entry);
    final base = entry.marker
        ? theme.textTheme.bodyMedium
        : theme.textTheme.bodyLarge;
    final textStyle = base?.copyWith(
      color: foreground,
      fontWeight: entry.lit ? FontWeight.w700 : FontWeight.w400,
    );

    return AnimatedContainer(
      duration: tokens.motion.of(context, tokens.motion.medium),
      curve: tokens.motion.standard,
      constraints: const BoxConstraints(minHeight: 52),
      padding: EdgeInsetsDirectional.only(start: tokens.space.xs),
      decoration: BoxDecoration(
        color: entry.lit
            ? theme.colorScheme.primary.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.16 : 0.07,
              )
            : null,
        borderRadius: BorderRadius.circular(tokens.radius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              container: true,
              label: entry.semantics(l10n, null),
              excludeSemantics: true,
              child: Row(
                children: [
                  _Mark(entry: entry),
                  SizedBox(width: tokens.space.sm),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: tokens.space.xs),
                      child: Wrap(
                        spacing: tokens.space.xs,
                        runSpacing: tokens.space.xxs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(entry.name, style: textStyle),
                          if (entry.highlight != null)
                            _Badge(entry.highlight!, lit: true),
                          if (entry.offset != null) _Badge(entry.offset!),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: tokens.space.xs),
                  Flexible(
                    child: Text(
                      entry.time,
                      textAlign: TextAlign.end,
                      style: textStyle?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _Bell(entry: entry, onOpenAlerts: onOpenAlerts),
        ],
      ),
    );
  }
}

class _StationTile extends StatelessWidget {
  const _StationTile({required this.entry, required this.onOpenAlerts});

  final _Entry entry;
  final void Function(String prayer)? onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context)!;
    final foreground = _foreground(context, entry);
    return AnimatedContainer(
      duration: tokens.motion.of(context, tokens.motion.medium),
      curve: tokens.motion.standard,
      margin: EdgeInsets.symmetric(horizontal: tokens.space.xxs / 2),
      padding: EdgeInsets.fromLTRB(
        tokens.space.xxs,
        tokens.space.sm,
        tokens.space.xxs,
        tokens.space.xxs,
      ),
      decoration: BoxDecoration(
        color: entry.lit
            ? theme.colorScheme.primary.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.16 : 0.07,
              )
            : null,
        borderRadius: BorderRadius.circular(tokens.radius.md),
      ),
      child: Column(
        children: [
          Semantics(
            container: true,
            label: entry.semantics(l10n, null),
            excludeSemantics: true,
            child: Column(
              children: [
                _Mark(entry: entry),
                SizedBox(height: tokens.space.xxs),
                Text(
                  entry.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: entry.lit ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                Text(
                  entry.time,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: entry.marker
                        ? FontWeight.w400
                        : FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (entry.highlight != null || entry.offset != null) ...[
                  SizedBox(height: tokens.space.xxs),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: tokens.space.xxs,
                    runSpacing: tokens.space.xxs,
                    children: [
                      if (entry.highlight != null)
                        _Badge(entry.highlight!, lit: true),
                      if (entry.offset != null) _Badge(entry.offset!),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          _Bell(entry: entry, onOpenAlerts: onOpenAlerts),
        ],
      ),
    );
  }
}
