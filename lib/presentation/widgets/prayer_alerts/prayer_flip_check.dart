import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huda/core/services/android_prayer_notification_state_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';

/// Android: checks that this phone recognizes a flip, without playing the
/// adhan. Hold the phone, turn it face down, and see "Flip detected".
class PrayerFlipCheck extends StatefulWidget {
  const PrayerFlipCheck({super.key});

  @override
  State<PrayerFlipCheck> createState() => _PrayerFlipCheckState();
}

enum _Step { idle, waiting, armed, detected, missed, unavailable }

class _PrayerFlipCheckState extends State<PrayerFlipCheck> {
  AndroidPrayerNotificationStateService? get _service =>
      getIt.isRegistered<AndroidPrayerNotificationStateService>()
      ? getIt<AndroidPrayerNotificationStateService>()
      : null;
  StreamSubscription<Map<String, Object?>>? _events;
  _Step _step = _Step.idle;

  Future<void> _start() async {
    final service = _service;
    if (service == null) return;
    await _events?.cancel();
    _events = service.events
        .where((event) => event['type'] == 'flipProbe')
        .listen((event) {
          if (!mounted) return;
          setState(() {
            _step = switch (event['state']) {
              'armed' => _Step.armed,
              'detected' => _Step.detected,
              'stopped' => _Step.missed,
              _ => _Step.waiting,
            };
          });
        });
    setState(() => _step = _Step.waiting);
    try {
      if (!await service.platform.host.startFlipProbe() && mounted) {
        setState(() => _step = _Step.unavailable);
      }
    } catch (_) {
      if (mounted) setState(() => _step = _Step.unavailable);
    }
  }

  @override
  void dispose() {
    unawaited(_events?.cancel());
    if (_step == _Step.waiting || _step == _Step.armed) {
      unawaited(_service?.platform.host.stopFlipProbe());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = PrayerPalette.of(context);
    final theme = Theme.of(context);
    final (String? text, IconData icon, Color color) = switch (_step) {
      _Step.idle => (null, Icons.screen_rotation_alt_rounded, palette.muted),
      _Step.waiting => (
        l10n.prayerAlertFlipHold,
        Icons.stay_current_portrait_rounded,
        palette.primary,
      ),
      _Step.armed => (
        l10n.prayerAlertFlipNow,
        Icons.screen_rotation_alt_rounded,
        palette.primary,
      ),
      _Step.detected => (
        l10n.prayerAlertFlipDetected,
        Icons.check_circle_rounded,
        palette.success,
      ),
      _Step.missed => (
        l10n.prayerAlertFlipMissed,
        Icons.info_outline_rounded,
        palette.warning,
      ),
      _Step.unavailable => (
        l10n.prayerAlertFlipUnavailable,
        Icons.info_outline_rounded,
        palette.warning,
      ),
    };
    final busy = _step == _Step.waiting || _step == _Step.armed;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 12, 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                text ?? l10n.prayerAlertToggleFlipHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: text == null ? palette.muted : palette.ink,
                  fontWeight: text == null ? null : FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (busy)
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_step != _Step.unavailable)
            TextButton(
              key: const ValueKey('prayer-alert-flip-try'),
              onPressed: _start,
              child: Text(l10n.prayerAlertFlipTry),
            ),
        ],
      ),
    );
  }
}
