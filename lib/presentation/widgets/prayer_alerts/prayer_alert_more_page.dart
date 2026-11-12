import 'package:flutter/material.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alerts.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_labels.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_sheet.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_widgets.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_flip_check.dart';

/// Switches most people never need, for every prayer.
class PrayerAlertMorePage extends StatelessWidget {
  const PrayerAlertMorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PrayerAlertPage(
      title: l10n.prayerAlertSectionMore,
      builder: (context, settings, capabilities) {
        final controller = PrayerAlertScope.of(context).controller;
        String number(int value) => prayerAlertNumber(context, value);
        return [
          if (capabilities.fadeIn || capabilities.fallback)
            PrayerAlertSection(
              title: l10n.prayerAlertSectionSound,
              children: [
                if (capabilities.fadeIn)
                  PrayerControlRow(
                    title: l10n.prayerAlertFadeIn,
                    child: PrayerSegmented<int>(
                      key: const ValueKey('prayer-alert-fade'),
                      options: {0, 3, 5, 10, settings.fadeInSeconds}.toList()
                        ..sort(),
                      selected: settings.fadeInSeconds,
                      label: (seconds) => seconds == 0
                          ? l10n.prayerAlertNone
                          : l10n.prayerAlertLengthSeconds(number(seconds)),
                      onSelected: (seconds) =>
                          controller.edit(SetPrayerAlertFadeIn(seconds)),
                    ),
                  ),
                if (capabilities.fallback)
                  PrayerControlRow(
                    title: l10n.prayerAlertFallback,
                    child: PrayerSegmented<PrayerAlertStyle>(
                      options: const [
                        PrayerAlertStyle.silent,
                        PrayerAlertStyle.short,
                      ],
                      selected: settings.fallbackStyle,
                      label: l10n.alertStyle,
                      onSelected: (style) =>
                          controller.edit(SetPrayerAlertFallback(style)),
                    ),
                  ),
              ],
            ),
          if (capabilities.toggles.isNotEmpty)
            PrayerAlertSection(
              title: l10n.prayerAlertSectionMore,
              children: [
                for (final toggle in capabilities.toggles)
                  Builder(
                    builder: (context) {
                      final (title, hint) = l10n.alertToggle(toggle.key);
                      final on = settings.toggles[toggle.key] ?? false;
                      final row = PrayerSwitchRow(
                        key: ValueKey('prayer-alert-toggle-${toggle.key}'),
                        title: title,
                        subtitle: hint,
                        value: on,
                        onChanged: (value) => controller.edit(
                          SetPrayerAlertToggle(toggle.key, value),
                        ),
                      );
                      // Flip to stop can be checked right here.
                      if (toggle.key != 'flipToStopEnabled' || !on) return row;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [row, const PrayerFlipCheck()],
                      );
                    },
                  ),
              ],
            ),
        ];
      },
    );
  }
}
