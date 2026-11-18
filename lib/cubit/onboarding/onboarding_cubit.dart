import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/onboarding/onboarding_environment.dart';

part 'onboarding_state.dart';

/// The first-run setup wizard's position: which steps show, where the
/// person is and how each step ended. It holds no domain logic; each step
/// calls the app's own cubits and services, and writes the keys they read,
/// so nothing is asked twice. See `docs/onboarding_setup_redesign.md`.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({required this.environment})
    : super(
        OnboardingState(
          steps: _stepsFor(
            privacy: environment.isFoss,
            reliability: false,
            reminders: false,
          ),
          current: OnboardingStep.welcome,
        ),
      );

  final OnboardingEnvironment environment;

  static const completedKey = 'onboarding_completed';
  static const setupVersionKey = 'onboarding_setup_version';
  static const whatsNewKey = 'whats_new_last_seen_version';

  /// Bumped when a later release adds steps, so people who finished an
  /// older wizard could be shown only the new ones.
  static const setupVersion = 1;

  bool _reliability = false;
  bool _reminders = false;

  static List<OnboardingStep> _stepsFor({
    required bool privacy,
    required bool reliability,
    required bool reminders,
  }) => [
    for (final step in OnboardingStep.values)
      if ((step != OnboardingStep.privacy || privacy) &&
          (step != OnboardingStep.reliability || reliability) &&
          (step != OnboardingStep.reminders || reminders))
        step,
  ];

  /// Steps that depend on notification access: [reliability] when alerts
  /// still have something to fix on this platform, [reminders] when
  /// notifications are allowed. The step being shown and steps already
  /// answered never disappear, so going back finds them.
  void setAvailability({bool? reliability, bool? reminders}) {
    _reliability = reliability ?? _reliability;
    _reminders = reminders ?? _reminders;
    final keep = {
      state.current,
      for (final entry in state.outcomes.entries)
        if (entry.value != StepOutcome.pending) entry.key,
    };
    final steps = [
      for (final step in OnboardingStep.values)
        if (keep.contains(step) ||
            _stepsFor(
              privacy: environment.isFoss,
              reliability: _reliability,
              reminders: _reminders,
            ).contains(step))
          step,
    ];
    if (!listEquals(steps, state.steps)) emit(state.copyWith(steps: steps));
  }

  /// Ends the current step with [outcome] and moves to the next, or back
  /// to the summary when the step was opened from it. On the last step it
  /// does nothing: [finish] ends the wizard.
  void next([StepOutcome outcome = StepOutcome.done]) {
    if (state.finishing || state.isLast) return;
    final outcomes = {...state.outcomes, state.current: outcome};
    if (state.reviewing) {
      emit(
        state.copyWith(
          current: OnboardingStep.summary,
          outcomes: outcomes,
          direction: 1,
          reviewing: false,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        current: state.steps[state.index + 1],
        outcomes: outcomes,
        direction: 1,
      ),
    );
  }

  /// "Not now": moves on, and the app asks again later.
  void skip() => next(StepOutcome.skipped);

  /// The previous step, or the summary when the step was opened from it
  /// (its choice stays as it is). False on the first step (system Back
  /// leaves the app there, as before).
  bool back() {
    if (state.finishing) return false;
    if (state.reviewing) {
      // A step that applies at once already holds what was picked: the
      // summary says so. Others saved nothing and keep their outcome.
      final outcomes = state.current.appliesAtOnce
          ? {...state.outcomes, state.current: StepOutcome.done}
          : state.outcomes;
      emit(
        state.copyWith(
          current: OnboardingStep.summary,
          outcomes: outcomes,
          direction: 1,
          reviewing: false,
        ),
      );
      return true;
    }
    if (state.isFirst) return false;
    emit(
      state.copyWith(current: state.steps[state.index - 1], direction: -1),
    );
    return true;
  }

  /// Jumps to a step already passed. From the summary (any step, the
  /// language too) it opens that one step to change it, and the wizard
  /// returns to the summary after it ([OnboardingState.reviewing]).
  void goTo(OnboardingStep step) {
    if (state.finishing || !state.steps.contains(step)) return;
    final target = state.steps.indexOf(step);
    if (target == state.index) return;
    emit(
      state.copyWith(
        current: step,
        direction: target > state.index ? 1 : -1,
        reviewing:
            state.current == OnboardingStep.summary ? true : state.reviewing,
      ),
    );
  }

  /// Ends the wizard, from the summary or "Skip setup": steps not reached
  /// fall back to the app's usual prompts. Writes the keys bootstrap and
  /// "What's new" read; Home opens next.
  Future<void> finish() async {
    if (state.finishing) return;
    emit(state.copyWith(finishing: true));
    final cache = environment.cache;
    await cache.saveData(key: setupVersionKey, value: setupVersion);
    // New people shouldn't get a "What's new" dialog on their first Home.
    try {
      final version = await environment.appVersion();
      if (version.isNotEmpty) {
        await cache.saveData(key: whatsNewKey, value: version);
      }
    } catch (error) {
      debugPrint('Onboarding: no app version: $error');
    }
    await cache.saveData(key: completedKey, value: true);
  }
}
