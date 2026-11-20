import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alerts.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_labels.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_sheet.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_widgets.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';

class PrayerAlertTestTile extends StatefulWidget {
  const PrayerAlertTestTile({
    super.key,
    required this.initialPrayer,
    this.fixedPrayer = false,
  });

  final String initialPrayer;

  final bool fixedPrayer;

  @override
  State<PrayerAlertTestTile> createState() => _PrayerAlertTestTileState();
}

class _PrayerAlertTestTileState extends State<PrayerAlertTestTile> {
  static const _delay = 10;
  late String _prayer = widget.initialPrayer;
  Timer? _countdown;
  int _remaining = 0;
  bool _sending = false;
  PrayerTestOutcome? _outcome;
  PrayerAlertController<Object?>? _controller;

  bool get _delayed => PlatformUtils.isDesktop;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = PrayerAlertScope.of(context).controller;
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdown?.cancel();
    setState(() => _remaining = _delay);
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _remaining--);
      if (_remaining <= 0) timer.cancel();
    });
  }

  Future<void> _send() async {
    final controller = _controller!;
    final l10n = AppLocalizations.of(context)!;
    final name = l10n.prayerName(_prayer);
    setState(() {
      _sending = true;
      _outcome = null;
    });
    await controller.flush();
    final settings = controller.current;
    if (settings == null || !mounted) return;
    _startCountdown();
    final outcome = await controller.platform.sendTest(
      _prayer,
      settings,
      title: l10n.notificationPrayerTimeTitle(name),
      body: l10n.notificationPrayerTimeBody(name),
    );
    if (!mounted) return;
    if (outcome != PrayerTestOutcome.scheduled) _countdown?.cancel();
    setState(() {
      _sending = false;
      _outcome = outcome;
      if (outcome != PrayerTestOutcome.scheduled) _remaining = 0;
    });
  }

  Future<void> _stop() async {
    _countdown?.cancel();
    setState(() {
      _remaining = 0;
      _sending = false;
      _outcome = null;
    });
    await _controller?.platform.stopTest();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = PrayerPalette.of(context);
    final theme = Theme.of(context);
    final waiting = _remaining > 0;
    final outcome = _outcome;
    final good = outcome == PrayerTestOutcome.scheduled;
    return PrayerAlertSection(
      title: l10n.prayerAlertSectionTest,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _delayed
                    ? l10n.prayerAlertTestHintDesktop
                    : l10n.prayerAlertTestHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.muted,
                  height: 1.4,
                ),
              ),
              if (!widget.fixedPrayer) ...[
                const SizedBox(height: 12),
                PrayerSegmented<String>(
                  key: const ValueKey('prayer-alert-test-prayer'),
                  options: prayerAlertPrayers,
                  selected: _prayer,
                  label: l10n.prayerName,
                  onSelected: (prayer) => setState(() => _prayer = prayer),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: waiting
                          ? Text(
                              l10n.prayerAlertTestWaiting(
                                prayerAlertNumber(context, _remaining),
                              ),
                              key: const ValueKey('waiting'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: palette.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : outcome == null
                          ? const SizedBox.shrink()
                          : Semantics(
                              liveRegion: true,
                              child: Row(
                                key: ValueKey(outcome),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    good
                                        ? Icons.check_circle_rounded
                                        : Icons.info_outline_rounded,
                                    size: 18,
                                    color: good
                                        ? palette.success
                                        : palette.warning,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      l10n.testOutcome(
                                        outcome,
                                        delayed: _delayed,
                                      ),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: palette.ink,
                                            height: 1.4,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (waiting)
                    TextButton(onPressed: _stop, child: Text(l10n.cancel))
                  else
                    FilledButton.icon(
                      key: const ValueKey('prayer-alert-test-send'),
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(l10n.prayerAlertTestSend),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
