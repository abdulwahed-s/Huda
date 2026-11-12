import 'package:flutter/material.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alerts.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_home_page.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_labels.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_sheet.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_sound_controls.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_test_tile.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_widgets.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';

/// One prayer: follow every prayer's settings, or set its own.
class PrayerAlertPrayerPage extends StatelessWidget {
  const PrayerAlertPrayerPage({super.key, required this.prayer});

  final String prayer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PrayerAlertPage(
      title: l10n.prayerName(prayer),
      builder: (context, settings, capabilities) {
        final controller = PrayerAlertScope.of(context).controller;
        final own = settings.prayers[prayer]!;
        final palette = PrayerPalette.of(context);
        final usesSound =
            own.style != PrayerAlertStyle.off &&
            own.style != PrayerAlertStyle.silent &&
            own.style != PrayerAlertStyle.focus;
        String number(int value) => prayerAlertNumber(context, value);
        return [
          PrayerAlertSectionTitle(l10n.prayerAlertSectionStyle),
          PrayerStyleChoices(
            capabilities: capabilities,
            styles: [
              if (capabilities.perPrayer) PrayerAlertStyle.off,
              ...capabilities.styles,
            ],
            unavailable: capabilities.unavailable,
            selected: own.ownStyle ? own.style : null,
            leading: [
              PrayerChoiceTile(
                key: const ValueKey('prayer-alert-style-default'),
                icon: Icons.layers_rounded,
                title: l10n.prayerAlertSameAsAll,
                subtitle: l10n.alertStyleSummary(
                  settings.style,
                  capabilities,
                  opening: settings.openingOnly,
                ),
                selected: !own.ownStyle,
                onTap: () =>
                    controller.edit(SetPrayerAlertStyle(null, prayer: prayer)),
              ),
            ],
            onSelected: (style) async {
              if (await prayerAlertStyleAllowed(context, style)) {
                controller.edit(SetPrayerAlertStyle(style, prayer: prayer));
              }
            },
          ),
          const SizedBox(height: 18),
          if (usesSound && capabilities.perPrayerReciter)
            PrayerSoundSection(
              settings: settings,
              capabilities: capabilities,
              prayer: prayer,
            ),
          if (capabilities.beforePrayer && own.style != PrayerAlertStyle.off)
            PrayerAlertSection(
              title: l10n.prayerAlertSectionBefore,
              children: [
                PrayerControlRow(
                  title: l10n.prayerAlertSectionBefore,
                  child: PrayerSegmented<int?>(
                    options: [null, 0, ...capabilities.beforeMinutes],
                    selected: own.ownBefore ? own.beforeMinutes : null,
                    label: (minutes) => minutes == null
                        ? l10n.prayerAlertDefault
                        : minutes == 0
                        ? l10n.prayerAlertNone
                        : l10n.prayerAlertBeforeMinutes(number(minutes)),
                    onSelected: (minutes) => controller.edit(
                      SetPrayerAlertBefore(minutes, prayer: prayer),
                    ),
                  ),
                ),
              ],
            ),
          if (capabilities.perPrayerTuning && own.style != PrayerAlertStyle.off)
            PrayerAlertSection(
              title: l10n.prayerAlertMoreFor(l10n.prayerName(prayer)),
              children: [
                for (final toggle in capabilities.toggles.where(
                  (toggle) => toggle.perPrayer,
                ))
                  _TriStateRow(
                    title: l10n.alertToggle(toggle.key).$1,
                    value: own.tuning[toggle.key] as bool?,
                    fallback: settings.toggles[toggle.key] ?? false,
                    onChanged: (value) => controller.edit(
                      SetPrayerAlertToggle(toggle.key, value, prayer: prayer),
                    ),
                  ),
              ],
            ),
          PrayerAlertTestTile(initialPrayer: prayer, fixedPrayer: true),
          if (own.custom)
            Center(
              child: TextButton.icon(
                key: const ValueKey('prayer-alert-reset'),
                onPressed: () => controller.edit(ResetPrayerAlert(prayer)),
                icon: Icon(Icons.restart_alt_rounded, color: palette.primary),
                label: Text(l10n.prayerAlertReset(l10n.prayerName(prayer))),
              ),
            ),
        ];
      },
    );
  }
}

/// Default (following every prayer), on, or off.
class _TriStateRow extends StatelessWidget {
  const _TriStateRow({
    required this.title,
    required this.value,
    required this.fallback,
    required this.onChanged,
  });

  final String title;
  final bool? value;
  final bool fallback;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PrayerControlRow(
      title: title,
      child: PrayerSegmented<bool?>(
        options: const [null, true, false],
        selected: value,
        label: (option) => switch (option) {
          null =>
            '${l10n.prayerAlertDefault} (${fallback ? l10n.prayerAlertOn : l10n.prayerAlertNone})',
          true => l10n.prayerAlertOn,
          false => l10n.prayerAlertNone,
        },
        onSelected: onChanged,
      ),
    );
  }
}
