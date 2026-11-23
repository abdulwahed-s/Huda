part of 'onboarding_cubit.dart';

/// The wizard's steps, in the order they run. Which ones show depends on
/// the platform, the flavor and what earlier steps answered (see
/// [OnboardingCubit]).
enum OnboardingStep {
  welcome,
  appearance,
  focus,
  permissions,
  location,
  asr,
  alerts,
  prayerPanel,
  reliability,
  mushaf,
  reminders,
  privacy,
  summary;

  /// Steps that make a choice and show on the summary.
  bool get isChoice => this != welcome && this != summary;

  /// Steps whose choice applies the moment it's made (the language, the
  /// look, each reminder), so leaving them keeps whatever is set.
  bool get appliesAtOnce =>
      this == welcome || this == appearance || this == reminders;
}

/// How a step ended. Skipping is never an error: the app asks again
/// later through its usual UI.
enum StepOutcome { pending, done, skipped }

@immutable
class OnboardingState {
  const OnboardingState({
    required this.steps,
    required this.current,
    this.outcomes = const {},
    this.direction = 1,
    this.finishing = false,
    this.reviewing = false,
  });

  /// The steps that show, in order.
  final List<OnboardingStep> steps;
  final OnboardingStep current;
  final Map<OnboardingStep, StepOutcome> outcomes;

  /// 1 after moving forward, -1 after moving back: which way the step
  /// pane slides.
  final int direction;

  /// Finishing: the keys are being written and Home opens next.
  final bool finishing;

  /// A step opened from the summary to change it: Continue, its skip and
  /// Back all return to the summary instead of walking through the steps
  /// after it.
  final bool reviewing;

  int get index => steps.indexOf(current);
  int get total => steps.length;
  bool get isFirst => index <= 0;

  /// Whether Back has somewhere to go (the summary, while reviewing).
  bool get canGoBack => !isFirst || reviewing;
  bool get isLast => index == steps.length - 1;

  StepOutcome outcomeOf(OnboardingStep step) =>
      outcomes[step] ?? StepOutcome.pending;

  OnboardingState copyWith({
    List<OnboardingStep>? steps,
    OnboardingStep? current,
    Map<OnboardingStep, StepOutcome>? outcomes,
    int? direction,
    bool? finishing,
    bool? reviewing,
  }) => OnboardingState(
    steps: steps ?? this.steps,
    current: current ?? this.current,
    outcomes: outcomes ?? this.outcomes,
    direction: direction ?? this.direction,
    finishing: finishing ?? this.finishing,
    reviewing: reviewing ?? this.reviewing,
  );
}
