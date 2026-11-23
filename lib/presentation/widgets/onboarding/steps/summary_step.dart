import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/linux_prayer_tray_bridge.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_frame.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_steps.dart';
import 'package:huda/presentation/widgets/onboarding/steps/focus_step.dart';
import 'package:huda/presentation/widgets/onboarding/steps/location_step.dart';
import 'package:huda/presentation/widgets/onboarding/steps/reminders_step.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_time_adjustment_bottom_sheet.dart'
    show prayerMethodLabel;
import 'package:huda/presentation/widgets/surah/quran_mushaf_page_view.dart';

class SummaryStep extends StatelessWidget {
  const SummaryStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scope = OnboardingScope.of(context);
    final state = context.watch<OnboardingCubit>().state;
    final steps = [
      OnboardingStep.welcome,
      ...state.steps.where((step) => step.isChoice),
    ];
    return OnboardingStepFrame(
      message: l10n.setupSummaryMessage,
      primary: OnboardingAction(
        l10n.setupStart,
        key: const ValueKey('onboarding-start'),
        busyLabel: state.finishing ? l10n.setupStart : null,
        onPressed: scope.finish,
      ),
      children: [
        HudaCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _SummaryRow(
                  step: steps[i],
                  outcome: steps[i] == OnboardingStep.welcome
                      ? StepOutcome.done
                      : state.outcomeOf(steps[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.step, required this.outcome});

  final OnboardingStep step;
  final StepOutcome outcome;

  String? _detail(BuildContext context, AppLocalizations l10n) {
    final scope = OnboardingScope.of(context);
    switch (step) {
      case OnboardingStep.appearance:
        final theme = context.watch<ThemeCubit>().state;
        final mode = switch (theme.themeMode) {
          ThemeMode.light => l10n.setupThemeLight,
          ThemeMode.dark => l10n.setupThemeDark,
          ThemeMode.system => l10n.setupThemeSystem,
        };
        return '$mode · ${AppColors.getThemeName(theme.colorTheme, context)}';
      case OnboardingStep.focus:
        return FocusStep.titleOf(
          l10n,
          scope.environment.homePreferences.load().selectedTheme,
        );
      case OnboardingStep.permissions:
        final location = context.watch<PrayerTimesCubit>().state;
        String status(bool allowed) => allowed
            ? l10n.setupPermissionAllowed
            : l10n.setupPermissionNotAllowed;
        return '${l10n.location}: ${status(location is PrayerTimesLoaded)} · '
            '${l10n.notifications}: '
            '${status(scope.access.access?.notificationsEnabled ?? false)}';
      case OnboardingStep.location:
        final prayer = context.watch<PrayerTimesCubit>().state;
        return prayer is PrayerTimesLoaded ? onboardingPlaceName(prayer) : null;
      case OnboardingStep.asr:
        final prayer = context.read<PrayerTimesCubit>();
        final school = prayer.madhabToken == 'hanafi'
            ? l10n.prayerMadhabHanafi
            : l10n.setupAsrStandard;
        return '${prayerMethodLabel(l10n, prayer.calculationMethodToken)} · '
            '$school';
      case OnboardingStep.alerts:
        return (scope.access.access?.notificationsEnabled ?? false)
            ? l10n.prayerSetupAlertsOn
            : l10n.setupAlertsOff;
      case OnboardingStep.prayerPanel:
        // Done means the command ran; GNOME on Wayland loads a new
        // extension only at the next login.
        return LinuxPrayerTrayBridge.status.value.extensionState == 'enabled'
            ? l10n.linuxPrayerTrayAvailable
            : l10n.linuxPanelAfterLogin;
      case OnboardingStep.reliability:
        return l10n.prayerSetupReliableOn;
      case OnboardingStep.mushaf:
        return QuranReadingMode.fromStorageValue(
          scope.environment.cache.getData(key: QuranReadingMode.key) as String?,
        ).localizedLabel(context);
      case OnboardingStep.reminders:
        final reminders = context.watch<NotificationsCubit>().state;
        return l10n.setupRemindersOn(
          OnboardingReminder.values.where((r) => r.isOn(reminders)).length,
        );
      case OnboardingStep.welcome:
        final code = context
            .watch<LocalizationCubit>()
            .state
            .locale
            .languageCode;
        return LocalizationCubit.languageNames[code] ?? code;
      case OnboardingStep.privacy:
      case OnboardingStep.summary:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final done = outcome == StepOutcome.done;
    final meta = done
        ? (_detail(context, l10n) ?? l10n.done)
        : l10n.setupSkippedLater;
    final partial =
        done &&
        step == OnboardingStep.permissions &&
        !(context.watch<PrayerTimesCubit>().state is PrayerTimesLoaded &&
            (OnboardingScope.of(context).access.access?.notificationsEnabled ??
                false));
    final mark = done && !partial
        ? HudaLamp(
            size: 36,
            child: Icon(Icons.check_rounded, size: 18, color: tokens.gilt),
          )
        : Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scheme.outline),
            ),
            child: Icon(
              Icons.remove_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          );
    return HudaContentRow(
      key: ValueKey('onboarding-summary-${step.name}'),
      leading: mark,
      title: step.label(l10n),
      meta: meta,
      onTap: () => context.read<OnboardingCubit>().goTo(step),
    );
  }
}
