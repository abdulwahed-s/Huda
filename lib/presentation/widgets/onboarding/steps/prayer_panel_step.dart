import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/linux_prayer_tray_bridge.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_frame.dart';
import 'package:huda/presentation/widgets/prayer_times/linux_prayer_panel_setup.dart';

/// Linux on GNOME: what the top-bar prayer panel is, and its one-command
/// setup. Huda notices by itself when the panel connects. Skipped, it stays
/// available from Prayer Times.
class PrayerPanelStep extends StatefulWidget {
  const PrayerPanelStep({super.key, this.controller});

  /// Tests pass a controller with fake status and clipboard sources.
  final LinuxPrayerPanelSetupController? controller;

  @override
  State<PrayerPanelStep> createState() => _PrayerPanelStepState();
}

class _PrayerPanelStepState extends State<PrayerPanelStep> {
  late final LinuxPrayerPanelSetupController _setup =
      widget.controller ?? LinuxPrayerPanelSetupController();
  bool _turnedOn = false;

  @override
  void initState() {
    super.initState();
    _setup.addListener(_onChange);
    _turnOnWhenReady();
  }

  void _onChange() {
    _turnOnWhenReady();
    if (mounted) setState(() {});
  }

  /// The panel connected: make sure Huda shows it (it's on by default).
  void _turnOnWhenReady() {
    if (_setup.ready && !_turnedOn) {
      _turnedOn = true;
      final preferences = LinuxPrayerTrayBridge.preferences.value;
      if (!preferences.enabled) {
        unawaited(
          LinuxPrayerTrayBridge.setPreferences(
            preferences.copyWith(enabled: true),
          ).catchError((Object error) {
            debugPrint('Onboarding: prayer panel not turned on: $error');
          }),
        );
      }
    }
  }

  @override
  void dispose() {
    _setup.removeListener(_onChange);
    if (widget.controller == null) _setup.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onboarding = context.read<OnboardingCubit>();
    final phase = _setup.phase;
    final settled =
        phase == LinuxPrayerPanelPhase.ready ||
        phase == LinuxPrayerPanelPhase.incompatible ||
        _setup.copied;
    return OnboardingStepFrame(
      message: l10n.linuxPanelIntro,
      primary: settled
          ? OnboardingAction(
              l10n.continueButton,
              key: const ValueKey('onboarding-panel-continue'),
              advances: true,
              onPressed: () => onboarding.next(
                phase == LinuxPrayerPanelPhase.incompatible
                    ? StepOutcome.skipped
                    : StepOutcome.done,
              ),
            )
          : OnboardingAction(
              l10n.linuxPrayerTrayCopyCommand,
              key: const ValueKey('onboarding-panel-copy'),
              icon: Icons.copy_rounded,
              onPressed: phase == LinuxPrayerPanelPhase.loading
                  ? null
                  : _setup.copy,
            ),
      quiet: phase == LinuxPrayerPanelPhase.ready
          ? null
          : OnboardingAction(
              l10n.setupSkipStep,
              icon: onboardingSkipIcon,
              onPressed: onboarding.skip,
            ),
      children: [
        LinuxPrayerPanelSetupView(controller: _setup, showCopyButton: false),
      ],
    );
  }
}
