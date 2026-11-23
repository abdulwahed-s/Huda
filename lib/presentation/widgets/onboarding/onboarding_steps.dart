import 'package:flutter/material.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/onboarding/steps/appearance_step.dart';
import 'package:huda/presentation/widgets/onboarding/steps/asr_step.dart';
import 'package:huda/presentation/widgets/onboarding/steps/focus_step.dart';
import 'package:huda/presentation/widgets/onboarding/steps/location_step.dart';
import 'package:huda/presentation/widgets/onboarding/steps/mushaf_step.dart';
import 'package:huda/presentation/widgets/onboarding/steps/permissions_step.dart';
import 'package:huda/presentation/widgets/onboarding/steps/prayer_alerts_step.dart';
import 'package:huda/presentation/widgets/onboarding/steps/prayer_panel_step.dart';
import 'package:huda/presentation/widgets/onboarding/steps/privacy_step.dart';
import 'package:huda/presentation/widgets/onboarding/steps/reliability_step.dart';
import 'package:huda/presentation/widgets/onboarding/steps/reminders_step.dart';
import 'package:huda/presentation/widgets/onboarding/steps/summary_step.dart';
import 'package:huda/presentation/widgets/onboarding/steps/welcome_language_step.dart';

extension OnboardingStepText on OnboardingStep {
  String title(AppLocalizations l10n) => switch (this) {
    OnboardingStep.welcome => l10n.setupWelcomeTitle,
    OnboardingStep.appearance => l10n.setupLookTitle,
    OnboardingStep.focus => l10n.setupFocusTitle,
    OnboardingStep.permissions => l10n.setupPermissionsTitle,
    OnboardingStep.location => l10n.setupTimesTitle,
    OnboardingStep.asr => l10n.setupCalcTitle,
    OnboardingStep.alerts => l10n.setupAdhanTitle,
    OnboardingStep.prayerPanel => l10n.linuxPrayerTrayTitle,
    OnboardingStep.reliability => l10n.setupReliableTitle,
    OnboardingStep.mushaf => l10n.setupMushafTitle,
    OnboardingStep.reminders => l10n.setupRemindersTitle,
    OnboardingStep.privacy => l10n.crashReportingConsentTitle,
    OnboardingStep.summary => l10n.setupSummaryTitle,
  };

  String label(AppLocalizations l10n) => switch (this) {
    OnboardingStep.welcome => l10n.language,
    OnboardingStep.appearance => l10n.theme,
    OnboardingStep.focus => l10n.homeTheme,
    OnboardingStep.permissions => l10n.setupPermissionsLabel,
    OnboardingStep.location => l10n.prayerSetupLocationTitle,
    OnboardingStep.asr => l10n.setupCalcLabel,
    OnboardingStep.alerts => l10n.prayerSetupAlertsTitle,
    OnboardingStep.prayerPanel => l10n.linuxPrayerTrayTitle,
    OnboardingStep.reliability => l10n.prayerSetupReliableTitle,
    OnboardingStep.mushaf => l10n.settingsReadingMode,
    OnboardingStep.reminders => l10n.setupRemindersTitle,
    OnboardingStep.privacy => l10n.crashReportingSettingsTitle,
    OnboardingStep.summary => l10n.setupSummaryTitle,
  };

  IconData get icon => switch (this) {
    OnboardingStep.welcome => Icons.translate_rounded,
    OnboardingStep.appearance => Icons.palette_outlined,
    OnboardingStep.focus => Icons.home_outlined,
    OnboardingStep.permissions => Icons.admin_panel_settings_outlined,
    OnboardingStep.location => Icons.location_on_outlined,
    OnboardingStep.asr => Icons.wb_twilight_rounded,
    OnboardingStep.alerts => Icons.notifications_active_outlined,
    OnboardingStep.prayerPanel => Icons.web_asset_rounded,
    OnboardingStep.reliability => Icons.verified_outlined,
    OnboardingStep.mushaf => Icons.auto_stories_outlined,
    OnboardingStep.reminders => Icons.alarm_rounded,
    OnboardingStep.privacy => Icons.bug_report_outlined,
    OnboardingStep.summary => Icons.check_rounded,
  };

  Widget build() => switch (this) {
    OnboardingStep.welcome => const WelcomeLanguageStep(),
    OnboardingStep.appearance => const AppearanceStep(),
    OnboardingStep.focus => const FocusStep(),
    OnboardingStep.permissions => const PermissionsStep(),
    OnboardingStep.location => const LocationStep(),
    OnboardingStep.asr => const AsrStep(),
    OnboardingStep.alerts => const PrayerAlertsStep(),
    OnboardingStep.prayerPanel => const PrayerPanelStep(),
    OnboardingStep.reliability => const ReliabilityStep(),
    OnboardingStep.mushaf => const MushafStep(),
    OnboardingStep.reminders => const RemindersStep(),
    OnboardingStep.privacy => const PrivacyStep(),
    OnboardingStep.summary => const SummaryStep(),
  };
}
