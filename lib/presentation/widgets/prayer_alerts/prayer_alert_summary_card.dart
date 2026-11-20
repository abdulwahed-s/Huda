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
import 'package:huda/presentation/widgets/prayer_times/prayer_attention_strip.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

class PrayerAlertSummaryCard extends StatefulWidget {
  const PrayerAlertSummaryCard({
    super.key,
    required this.onOpen,
    this.status,
    this.controller,
    this.library,
  });

  final void Function([String? prayer]) onOpen;

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

    final tokens = context.tokens;
    final space = tokens.space;
    return Card(
      child: InkWell(
        key: const ValueKey('prayer-alert-summary'),
        onTap: () => widget.onOpen(),
        child: Padding(
          padding: EdgeInsets.all(space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  HudaIconMark(
                    settings == null || !enabled
                        ? Icons.notifications_off_outlined
                        : prayerAlertStyleIcon(settings.style),
                  ),
                  SizedBox(width: space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.prayerAlertTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: palette.ink,
                          ),
                        ),
                        if (summary != null)
                          Text(
                            summary,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: palette.muted,
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
                    Icons.chevron_right_rounded,
                    color: palette.faint,
                  ),
                ],
              ),
              if (session != null) ...[
                SizedBox(height: space.sm),
                Wrap(
                  spacing: space.xs,
                  runSpacing: space.xs,
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
                SizedBox(height: space.sm),
                const Divider(height: 1),
                SizedBox(height: space.sm),
                _StatusLine(status: status),
              ],
            ],
          ),
        ),
      ),
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
          if (status.tone == PrayerAlertTone.ready && !status.busy)
            SizedBox.square(
              dimension: 36,
              child: Icon(status.icon, size: 22, color: accent),
            )
          else
            PrayerNoticeLamp(
              size: 36,
              busy: status.busy,
              tone: switch (status.tone) {
                PrayerAlertTone.error => PrayerAttentionTone.error,
                PrayerAlertTone.warning => PrayerAttentionTone.warning,
                _ => PrayerAttentionTone.info,
              },
            ),
          SizedBox(width: context.tokens.space.sm),
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
                    child: OutlinedButton.icon(
                      onPressed: action.onPressed,
                      icon: Icon(action.icon, size: 18),
                      label: Text(action.label),
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
