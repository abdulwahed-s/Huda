import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/notification_delivery_check.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_frame.dart';

enum OnboardingReminder {
  athkar('sabahMasaa', Icons.wb_twilight_rounded),
  kahf('kahfFriday', Icons.menu_book_rounded),
  quran('quranReminder', Icons.auto_stories_outlined);

  const OnboardingReminder(this.key, this.icon);

  final String key;
  final IconData icon;

  String title(AppLocalizations l10n) => switch (this) {
    athkar => l10n.morningEveningAthkar,
    kahf => l10n.suratAlKahf,
    quran => l10n.quranReadingReminder,
  };

  String subtitle(AppLocalizations l10n) => switch (this) {
    athkar => l10n.dailyRemindersAthkar,
    kahf => l10n.weeklyReminderKahf,
    quran => l10n.dailyReminderQuran,
  };

  bool isOn(NotificationsState state) =>
      state is NotificationPreferencesLoaded &&
      switch (this) {
        athkar => state.sabahMasaa,
        kahf => state.kahfFriday,
        quran => state.quranReminder,
      };
}

class RemindersStep extends StatefulWidget {
  const RemindersStep({super.key});

  @override
  State<RemindersStep> createState() => _RemindersStepState();
}

class _RemindersStepState extends State<RemindersStep> {
  OnboardingReminder? _refused;
  final _refusedKey = GlobalKey();

  void _showRefused(OnboardingReminder reminder) {
    setState(() => _refused = reminder);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _refusedKey.currentContext;
      if (target != null && target.mounted) {
        Scrollable.ensureVisible(
          target,
          duration: context.tokens.motion.of(
            context,
            context.tokens.motion.medium,
          ),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final cubit = context.read<NotificationsCubit>();
    if (cubit.state is! NotificationPreferencesLoaded) {
      cubit.loadPreferences();
    }
  }

  Future<void> _toggle(OnboardingReminder reminder, bool on) async {
    HudaHaptics.selection(context);
    setState(() {
      _refused = null;
    });
    try {
      await context.read<NotificationsCubit>().togglePreference(
        reminder.key,
        on,
      );
    } on NotificationNotScheduledException {
      if (mounted) _showRefused(reminder);
    } catch (error) {
      debugPrint('Onboarding reminder failed: $error');
      if (mounted) _showRefused(reminder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onboarding = context.read<OnboardingCubit>();
    final state = context.watch<NotificationsCubit>().state;
    final loading = state is NotificationPreferencesLoaded
        ? state.loadingKeys
        : const <String>{};
    return OnboardingStepFrame(
      message: l10n.setupRemindersMessage,
      primary: OnboardingAction(
        l10n.continueButton,
        advances: true,
        onPressed: () => onboarding.next(),
      ),
      children: [
        HudaCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final reminder in OnboardingReminder.values) ...[
                if (reminder.index > 0) const Divider(height: 1),
                MergeSemantics(
                  child: HudaSettingsRow(
                    icon: reminder.icon,
                    title: reminder.title(l10n),
                    subtitle: reminder.subtitle(l10n),
                    trailing: Switch(
                      key: ValueKey('onboarding-reminder-${reminder.name}'),
                      value: reminder.isOn(state),
                      onChanged:
                          state is! NotificationPreferencesLoaded ||
                              loading.contains(reminder.key)
                          ? null
                          : (on) => _toggle(reminder, on),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        HudaStateSwitcher(
          stateKey: _refused?.name ?? 'fine',
          child: _refused == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: OnboardingNotice(
                    key: _refusedKey,
                    problem: true,
                    title: _refused!.title(l10n),
                    message: l10n.setupReminderFailed,
                  ),
                ),
        ),
      ],
    );
  }
}
