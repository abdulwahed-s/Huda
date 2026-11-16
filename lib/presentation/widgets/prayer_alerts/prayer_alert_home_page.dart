import 'package:flutter/material.dart';
import 'package:huda/core/services/ios_prayer_bridge.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alerts.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/notifications/permission_explainer_sheet.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_labels.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_more_page.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_prayer_page.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_sheet.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_sound_controls.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_test_tile.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_widgets.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';

/// The first page: whether prayers alert, how, with which sound, and what
/// differs per prayer. Rarely needed switches are one tap further.
class PrayerAlertHomePage extends StatelessWidget {
  const PrayerAlertHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PrayerAlertPage(
      title: l10n.prayerAlertTitle,
      builder: (context, settings, capabilities) {
        final scope = PrayerAlertScope.of(context);
        final controller = scope.controller;
        final enabledCount = settings.prayers.values
            .where((prayer) => prayer.style != PrayerAlertStyle.off)
            .length;
        return [
          PrayerAlertSection(
            title: l10n.prayerAlertMasterTitle,
            children: [
              PrayerSwitchRow(
                key: const ValueKey('prayer-alert-enabled'),
                icon: settings.enabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_outlined,
                title: l10n.prayerAlertMasterTitle,
                subtitle: settings.enabled
                    ? '${l10n.prayerAlertPrayersOn(enabledCount)} · '
                          '${l10n.alertStyleSummary(settings.style, capabilities, opening: settings.openingOnly)}'
                    : l10n.prayerAlertMasterOff,
                value: settings.enabled,
                onChanged: (value) =>
                    controller.edit(SetPrayerAlertsEnabled(value)),
              ),
            ],
          ),
          if (settings.enabled) ...[
            _StyleSection(settings: settings, capabilities: capabilities),
            if (settings.style == PrayerAlertStyle.focus)
              PrayerFocusSection(
                settings: settings,
                capabilities: capabilities,
              ),
            if (settings.usesAudio || capabilities.perPrayerReciter)
              PrayerSoundSection(
                settings: settings,
                capabilities: capabilities,
              ),
            if (capabilities.perPrayer)
              _PrayersSection(settings: settings, capabilities: capabilities),
            if (capabilities.beforePrayer)
              PrayerBeforeSection(
                settings: settings,
                capabilities: capabilities,
              ),
            PrayerAlertTestTile(
              initialPrayer: scope.nextPrayer ?? prayerAlertPrayers.first,
            ),
            if (capabilities.toggles.isNotEmpty ||
                capabilities.fadeIn ||
                capabilities.fallback)
              PrayerAlertSection(
                title: l10n.prayerAlertSectionMore,
                children: [
                  PrayerSettingRow(
                    key: const ValueKey('prayer-alert-more'),
                    icon: Icons.tune_rounded,
                    title: l10n.prayerAlertSectionMore,
                    onTap: () => scope.push(const PrayerAlertMorePage()),
                  ),
                ],
              ),
          ],
        ];
      },
    );
  }
}

/// Choosing a style that needs a permission explains it first (iOS alarms).
Future<bool> prayerAlertStyleAllowed(
  BuildContext context,
  PrayerAlertStyle style,
) async {
  if (!PlatformUtils.isIOS || style != PrayerAlertStyle.alarm) {
    return true;
  }
  final status = IOSPrayerBridge.status.value;
  if (status.alarmAuthorization == 'authorized') return true;
  final l10n = AppLocalizations.of(context)!;
  if (status.alarmAuthorization == 'denied') {
    await IOSPrayerBridge.openSettings();
    return false;
  }
  if (!await showPermissionExplainer(
    context,
    icon: Icons.alarm_rounded,
    title: l10n.prayerReadyAlarmTitle,
    message: l10n.prayerReadyAlarmMessage,
  )) {
    return false;
  }
  final result = await IOSPrayerBridge.requestAlarms();
  return result.alarmAuthorization == 'authorized';
}

class _StyleSection extends StatelessWidget {
  const _StyleSection({required this.settings, required this.capabilities});

  final PrayerAlertSettings settings;
  final PrayerAlertCapabilities capabilities;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = PrayerAlertScope.of(context).controller;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrayerAlertSectionTitle(l10n.prayerAlertSectionStyle),
          PrayerStyleChoices(
            capabilities: capabilities,
            styles: capabilities.styles,
            unavailable: capabilities.unavailable,
            selected: settings.style,
            onSelected: (style) async {
              if (await prayerAlertStyleAllowed(context, style)) {
                controller.edit(SetPrayerAlertStyle(style));
              }
            },
          ),
        ],
      ),
    );
  }
}

class PrayerAlertSectionTitle extends StatelessWidget {
  const PrayerAlertSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = PrayerPalette.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 6, 8),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.muted,
          ),
        ),
      ),
    );
  }
}

class _PrayersSection extends StatelessWidget {
  const _PrayersSection({required this.settings, required this.capabilities});

  final PrayerAlertSettings settings;
  final PrayerAlertCapabilities capabilities;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scope = PrayerAlertScope.of(context);
    final palette = PrayerPalette.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return PrayerAlertSection(
      title: l10n.prayerAlertSectionPrayers,
      children: [
        for (final entry in settings.prayers.entries)
          Builder(
            builder: (context) {
              final prayer = entry.value;
              final on = prayer.style != PrayerAlertStyle.off;
              final sound =
                  on &&
                      prayer.style != PrayerAlertStyle.silent &&
                      prayer.style != PrayerAlertStyle.focus
                  ? scope.library.reciter(prayer.reciterId)?.name(locale)
                  : null;
              return PrayerSettingRow(
                key: ValueKey('prayer-alert-prayer-${entry.key}'),
                icon: prayerAlertStyleIcon(prayer.style),
                title: l10n.prayerName(entry.key),
                subtitle: [
                  l10n.alertStyleSummary(
                    prayer.style,
                    capabilities,
                    opening: prayer.openingOnly,
                  ),
                  ?sound,
                  if (prayer.custom) l10n.prayerAlertCustom,
                ].join(' · '),
                subtitleColor: prayer.custom ? palette.primary : null,
                onTap: () =>
                    scope.push(PrayerAlertPrayerPage(prayer: entry.key)),
                trailing: Switch.adaptive(
                  value: on,
                  onChanged: (value) => scope.controller.edit(
                    SetPrayerAlertStyle(
                      value ? null : PrayerAlertStyle.off,
                      prayer: entry.key,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Reminder minutes before every prayer, and its sound where offered.
class PrayerBeforeSection extends StatelessWidget {
  const PrayerBeforeSection({
    super.key,
    required this.settings,
    required this.capabilities,
  });

  final PrayerAlertSettings settings;
  final PrayerAlertCapabilities capabilities;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = PrayerAlertScope.of(context).controller;
    String number(int value) => prayerAlertNumber(context, value);
    return PrayerAlertSection(
      title: l10n.prayerAlertSectionBefore,
      footer: capabilities.needsCompanion
          ? l10n.prayerAlertNeedsCompanion
          : l10n.prayerAlertBeforeHint,
      children: [
        PrayerControlRow(
          title: l10n.prayerAlertSectionBefore,
          child: PrayerSegmented<int>(
            key: const ValueKey('prayer-alert-before'),
            options: [0, ...capabilities.beforeMinutes],
            selected: settings.beforeMinutes,
            label: (minutes) => minutes == 0
                ? l10n.prayerAlertNone
                : l10n.prayerAlertBeforeMinutes(number(minutes)),
            onSelected: (minutes) =>
                controller.edit(SetPrayerAlertBefore(minutes)),
          ),
        ),
        if (capabilities.beforeStyle && settings.beforeMinutes > 0)
          PrayerControlRow(
            title: l10n.prayerAlertBeforeSound,
            child: PrayerSegmented<PrayerAlertStyle>(
              options: const [PrayerAlertStyle.silent, PrayerAlertStyle.short],
              selected: settings.beforeStyle,
              label: (style) => style == PrayerAlertStyle.silent
                  ? l10n.prayerAlertBeforeSilent
                  : l10n.prayerAlertBeforeShort,
              onSelected: (style) =>
                  controller.edit(SetPrayerAlertBeforeStyle(style)),
            ),
          ),
      ],
    );
  }
}

/// Desktop Focus: how long it lasts and whether it can be closed early.
class PrayerFocusSection extends StatelessWidget {
  const PrayerFocusSection({
    super.key,
    required this.settings,
    required this.capabilities,
  });

  final PrayerAlertSettings settings;
  final PrayerAlertCapabilities capabilities;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = PrayerAlertScope.of(context).controller;
    String number(int value) => prayerAlertNumber(context, value);
    final durations = {
      5,
      10,
      15,
      20,
      30,
      settings.focusDurationSeconds ~/ 60,
    }.where((minutes) => minutes >= 1 && minutes <= 60).toList()..sort();
    return PrayerAlertSection(
      title: l10n.prayerAlertSectionFocus,
      children: [
        PrayerControlRow(
          title: l10n.prayerAlertFocusDuration,
          child: PrayerSegmented<int>(
            options: durations,
            selected: settings.focusDurationSeconds ~/ 60,
            label: (minutes) => l10n.prayerAlertLengthMinutes(number(minutes)),
            onSelected: (minutes) => controller.edit(
              SetPrayerAlertFocus(durationSeconds: minutes * 60),
            ),
          ),
        ),
        PrayerSwitchRow(
          title: l10n.prayerAlertFocusAudio,
          value: settings.focusAudio,
          onChanged: (value) =>
              controller.edit(SetPrayerAlertFocus(audio: value)),
        ),
        PrayerSwitchRow(
          title: l10n.prayerAlertFocusCommitment,
          subtitle: l10n.prayerAlertFocusCommitmentHint,
          value: settings.focusCommitment,
          onChanged: (value) =>
              controller.edit(SetPrayerAlertFocus(commitment: value)),
        ),
        if (capabilities.focusStyle)
          PrayerSwitchRow(
            title: l10n.prayerAlertFocusFullScreen,
            value: settings.focusImmersive,
            onChanged: (value) =>
                controller.edit(SetPrayerAlertFocus(immersive: value)),
          ),
      ],
    );
  }
}
