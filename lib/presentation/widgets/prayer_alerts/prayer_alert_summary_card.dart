import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huda/core/services/android_prayer_notification_state_service.dart';
import 'package:huda/core/services/linux_prayer_notification_gateway.dart';
import 'package:huda/core/services/mac_prayer_bridge.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alerts.dart';
import 'package:huda/core/services/prayer_audio_library.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/services/windows_prayer_taskbar_bridge.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_labels.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_widgets.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_attention_items.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';

/// The one prayer alert card on Prayer Times: how prayers alert, each
/// prayer at a glance, whether alerts are set, and Stop while one plays.
/// A tap opens the settings sheet.
class PrayerAlertSummaryCard extends StatefulWidget {
  const PrayerAlertSummaryCard({
    super.key,
    required this.onOpen,
    this.status,
    this.controller,
    this.library,
  });

  final void Function([String? prayer]) onOpen;

  /// Coverage and schedule problems ([buildPrayerAlertStatus]).
  final PrayerAlertStatus? status;
  final PrayerAlertController<Object?>? controller;
  final PrayerAudioLibrary? library;

  @override
  State<PrayerAlertSummaryCard> createState() => _PrayerAlertSummaryCardState();
}

class _PrayerAlertSummaryCardState extends State<PrayerAlertSummaryCard> {
  late final controller = widget.controller ?? PrayerAlerts.shared;
  late final library = widget.library ?? PrayerAudioLibrary.shared;

  @override
  void initState() {
    super.initState();
    unawaited(controller.refresh());
    if (library.catalog == null) unawaited(library.load());
  }

  @override
  Widget build(BuildContext context) {
    final live = PrayerLiveSession.listenable;
    return ListenableBuilder(
      listenable: Listenable.merge([controller, library, ?live]),
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = PrayerPalette.of(context);
    final theme = Theme.of(context);
    final settings = controller.settings;
    final locale = Localizations.localeOf(context).languageCode;
    final status = widget.status;
    final enabled = settings?.enabled ?? false;
    final mixed =
        settings != null &&
        settings.prayers.values.any((prayer) => prayer.custom);
    final reciter = settings == null || !settings.usesAudio
        ? null
        : library.reciter(settings.reciterId)?.name(locale);
    final summary = settings == null
        ? null
        : !enabled
        ? l10n.prayerAlertSummaryOff
        : [
            l10n.alertStyleSummary(
              settings.style,
              controller.capabilities,
              opening: settings.openingOnly,
            ),
            ?reciter,
            if (mixed) l10n.prayerAlertSummaryMixed,
          ].join(' · ');
    final session = PrayerLiveSession.current();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: palette.cardDecoration(radius: 22),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: const ValueKey('prayer-alert-summary'),
            borderRadius: BorderRadius.circular(22),
            onTap: () => widget.onOpen(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      PrayerAlertIconBadge(
                        icon: settings == null || !enabled
                            ? Icons.notifications_off_outlined
                            : prayerAlertStyleIcon(settings.style),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.prayerAlertTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: palette.ink,
                              ),
                            ),
                            if (summary != null)
                              Text(
                                summary,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: palette.muted,
                                  height: 1.35,
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 18,
                        child: PrayerSaveStatus(controller: controller),
                      ),
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        color: palette.faint,
                      ),
                    ],
                  ),
                  if (settings != null && enabled) ...[
                    const SizedBox(height: 14),
                    _PrayerStrip(
                      settings: settings,
                      capabilities: controller.capabilities,
                      onOpen: widget.onOpen,
                    ),
                  ],
                  if (session != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (session.stopAudio != null)
                          FilledButton.icon(
                            key: const ValueKey('prayer-alert-stop'),
                            onPressed: session.stopAudio,
                            icon: const Icon(Icons.stop_rounded),
                            label: Text(l10n.prayerAlertStopAdhan),
                          ),
                        if (session.endFocus != null)
                          OutlinedButton(
                            onPressed: session.endFocus,
                            child: Text(l10n.prayerAlertEndFocus),
                          ),
                      ],
                    ),
                  ],
                  if (status != null) ...[
                    const SizedBox(height: 12),
                    Divider(height: 1, color: palette.divider),
                    const SizedBox(height: 12),
                    _StatusLine(status: status),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Each prayer's style at a glance; a tap opens that prayer.
class _PrayerStrip extends StatelessWidget {
  const _PrayerStrip({
    required this.settings,
    required this.onOpen,
    this.capabilities,
  });

  final PrayerAlertSettings settings;
  final PrayerAlertCapabilities? capabilities;
  final void Function([String? prayer]) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = PrayerPalette.of(context);
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final entry in settings.prayers.entries)
          Expanded(
            child: Semantics(
              button: true,
              label:
                  '${l10n.prayerName(entry.key)}: '
                  '${l10n.alertStyleSummary(entry.value.style, capabilities, opening: entry.value.openingOnly)}',
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onOpen(entry.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      Icon(
                        prayerAlertStyleIcon(entry.value.style),
                        size: 20,
                        color: entry.value.style == PrayerAlertStyle.off
                            ? palette.faint
                            : entry.value.custom
                            ? palette.primary
                            : palette.muted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.prayerName(entry.key),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: entry.value.style == PrayerAlertStyle.off
                              ? palette.faint
                              : palette.ink,
                          fontWeight: entry.value.custom
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.status});

  final PrayerAlertStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    final accent = switch (status.tone) {
      PrayerAlertTone.ready => palette.success,
      PrayerAlertTone.info => palette.primary,
      PrayerAlertTone.warning => palette.warning,
      PrayerAlertTone.error => palette.error,
    };
    final action = status.action;
    return Semantics(
      container: true,
      liveRegion: status.tone != PrayerAlertTone.ready,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(
            dimension: 20,
            child: status.busy
                ? CircularProgressIndicator(strokeWidth: 2, color: accent)
                : Icon(status.icon, size: 20, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (status.highlight != null)
                  Text(
                    status.highlight!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  status.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.muted,
                    height: 1.4,
                  ),
                ),
                if (action != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: FilledButton.tonalIcon(
                      onPressed: action.onPressed,
                      icon: Icon(action.icon, size: 18),
                      label: Text(action.label),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent.withValues(alpha: 0.14),
                        foregroundColor: accent,
                        visualDensity: VisualDensity.compact,
                      ),
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

/// An adhan or Focus that is playing now, with how to stop it.
class PrayerLiveSession {
  const PrayerLiveSession({this.stopAudio, this.endFocus});

  final VoidCallback? stopAudio;
  final VoidCallback? endFocus;

  static Listenable? get listenable {
    if (PlatformUtils.isAndroid &&
        getIt.isRegistered<AndroidPrayerNotificationStateService>()) {
      return getIt<AndroidPrayerNotificationStateService>();
    }
    if (PlatformUtils.isMacOS) return MacPrayerBridge.status;
    if (PlatformUtils.isWindows) return WindowsPrayerTaskbarBridge.status;
    if (PlatformUtils.isLinux) return LinuxPrayerNotificationGateway.status;
    return null;
  }

  static PrayerLiveSession? current() {
    if (PlatformUtils.isAndroid &&
        getIt.isRegistered<AndroidPrayerNotificationStateService>()) {
      final state = getIt<AndroidPrayerNotificationStateService>();
      return state.snapshot?.session == null
          ? null
          : PrayerLiveSession(stopAudio: () => unawaited(state.stop()));
    }
    if (PlatformUtils.isMacOS) {
      final status = MacPrayerBridge.status.value;
      final audio = status.audioSession, focus = status.focusSession;
      if (audio == null && (focus == null || !status.focusCanDismiss)) {
        return null;
      }
      return PrayerLiveSession(
        stopAudio: audio == null
            ? null
            : () => unawaited(
                MacPrayerBridge.command('stopAudio', sessionId: audio),
              ),
        endFocus: focus == null || !status.focusCanDismiss
            ? null
            : () => unawaited(
                MacPrayerBridge.command('dismissFocus', sessionId: focus),
              ),
      );
    }
    if (PlatformUtils.isWindows) {
      final status = WindowsPrayerTaskbarBridge.status.value;
      final audio = status.prayerAudioPlaying
          ? status.prayerAudioSessionId
          : null;
      final focus = status.prayerFocusActive && status.prayerFocusCanDismiss
          ? status.prayerSessionId
          : null;
      if (audio == null && focus == null) return null;
      return PrayerLiveSession(
        stopAudio: audio == null
            ? null
            : () => unawaited(
                WindowsPrayerTaskbarBridge.experienceCommand(
                  'stopAdhan',
                  sessionId: audio,
                ),
              ),
        endFocus: focus == null
            ? null
            : () => unawaited(
                WindowsPrayerTaskbarBridge.experienceCommand(
                  'dismissFocus',
                  sessionId: focus,
                ),
              ),
      );
    }
    if (PlatformUtils.isLinux) {
      final status = LinuxPrayerNotificationGateway.status.value;
      final audio = status.audioSession;
      final focus = status.focusCanDismiss ? status.focusSession : null;
      if (audio == null && focus == null) return null;
      return PrayerLiveSession(
        stopAudio: audio == null
            ? null
            : () => unawaited(
                LinuxPrayerNotificationGateway.command(
                  'stopAudio',
                  sessionId: audio,
                ),
              ),
        endFocus: focus == null
            ? null
            : () => unawaited(
                LinuxPrayerNotificationGateway.command(
                  'dismissFocus',
                  sessionId: focus,
                ),
              ),
      );
    }
    return null;
  }
}
