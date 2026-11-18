import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_frame.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_identity.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_steps.dart';

/// A step's stage on the chrome: its art (the receding arcade on the
/// welcome and the summary, the step's doorway and emblem otherwise), the
/// step's number and its question. With room, the art stands large over a
/// centered question; with little room, the stage folds into a band: the
/// question at the start, a small doorway at the end.
class OnboardingStage extends StatelessWidget {
  const OnboardingStage({
    super.key,
    required this.step,
    this.artOnly = false,
    this.band = false,
  });

  final OnboardingStep step;

  /// Always the band (short screens), whatever room the step leaves.
  final bool band;

  /// Only the art, large and centered: the stage in its own pane, where
  /// the question heads the step on the page instead
  /// ([OnboardingStepHeading]).
  final bool artOnly;

  /// The height from which the art stands over the question, for a text
  /// scale (clamped like chrome titles).
  static double tallFrom(double scale) => 72 + 140 * scale;

  @override
  Widget build(BuildContext context) {
    final night = context.tokens.night();
    return Theme(
      data: night,
      child: Builder(builder: _build),
    );
  }

  Widget _build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final textTheme = Theme.of(context).textTheme;
    final media = MediaQuery.of(context);
    final state = context.watch<OnboardingCubit>().state;
    final choices = state.steps.where((step) => step.isChoice).toList();
    final number = choices.indexOf(step) + 1;
    // While changing a step from the summary, the eyebrow names what's
    // being changed rather than counting from the start again.
    final eyebrow = state.reviewing
        ? step.label(l10n)
        : step.isChoice
        ? l10n.prayerSetupStepLabel(number, choices.length)
        : null;
    final subtitle = step == OnboardingStep.welcome
        ? l10n.setupWelcomeMessage
        : null;
    final scale = (media.textScaler.scale(16) / 16).clamp(1.0, 1.6);

    Widget art() => switch (step) {
      OnboardingStep.welcome => OnboardingArcade(
        count: state.total,
        lit: 1,
        entrance: true,
        logo: true,
      ),
      OnboardingStep.summary => OnboardingArcade(
        count: state.total,
        lit: state.total,
        flood: state.finishing,
      ),
      _ => OnboardingDoorway(step: step),
    };

    // During a language change the words fade under the veil; the art
    // (symmetric, so the mirror can't be seen) stays.
    final veil =
        context.getInheritedWidgetOfExactType<OnboardingScope>()?.veil ??
        kAlwaysCompleteAnimation;
    Widget words(Widget child) => FadeTransition(opacity: veil, child: child);

    Widget title(TextStyle? style, TextAlign align) =>
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.6,
          child: Semantics(
            header: true,
            child: Text(
              step.title(l10n),
              textAlign: align,
              style: style?.copyWith(color: tokens.onChrome),
            ),
          ),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        var height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : constraints.minHeight;
        final width = constraints.maxWidth;
        final gutter = space.gutter(media.size.width);
        final start = gutter + media.padding.left;
        final end = gutter + media.padding.right;
        final wide = width >= 600;
        if (artOnly) {
          final side = (height * 0.66).clamp(96.0, 640.0);
          return Padding(
            padding: EdgeInsets.fromLTRB(start, space.lg, end, space.xxl),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: side,
                  maxWidth: side * 0.8,
                ),
                child: AspectRatio(
                  aspectRatio: 0.8,
                  child: ExcludeSemantics(child: art()),
                ),
              ),
            ),
          );
        }
        if (!band) {
          height = math.max(height, tallFrom(scale));
          final maxArt = wide ? 440.0 : 300.0;
          return SizedBox(
            height: height,
            child: Padding(
              padding: EdgeInsets.fromLTRB(start, space.xs, end, space.xl),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: maxArt,
                          maxWidth: maxArt * 0.8,
                        ),
                        child: AspectRatio(
                          aspectRatio: 0.8,
                          child: ExcludeSemantics(child: art()),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: space.md),
                  words(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (eyebrow != null) ...[
                          Text(
                            eyebrow.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: context.type.eyebrow.copyWith(
                              color: tokens.gilt,
                            ),
                          ),
                          SizedBox(height: space.xs),
                        ],
                        title(
                          wide
                              ? textTheme.headlineMedium
                              : textTheme.headlineSmall,
                          TextAlign.center,
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: space.xs),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              color: tokens.onChromeMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        // Short screens: a band, the question at the start and a small
        // receding arcade at the end, lit to here. Slimmer still on short
        // landscape windows (the closed iPhone Duo on its side).
        final slim = media.size.height < 480;
        // The arcade grows into a tall band rather than leaving bare chrome
        // above the question; at large text on short screens the band is
        // the words alone, so the step keeps the room.
        final artHeight = slim
            ? 58.0
            : (height - space.xs - space.lg).clamp(88.0, 180.0);
        final showArt = !(scale >= 1.5 && media.size.height < 760);
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                start,
                slim ? 0 : space.xs,
                end,
                slim ? space.md : space.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: words(
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (eyebrow != null) ...[
                            Text(
                              eyebrow.toUpperCase(),
                              style: context.type.eyebrow.copyWith(
                                color: tokens.gilt,
                              ),
                            ),
                            SizedBox(height: space.xxs),
                          ],
                          title(
                            slim
                                ? textTheme.titleLarge
                                : textTheme.headlineSmall,
                            TextAlign.start,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showArt) ...[
                    SizedBox(width: space.md),
                    SizedBox(
                      width: artHeight * 0.8,
                      height: artHeight,
                      child: ExcludeSemantics(
                        child: switch (step) {
                          OnboardingStep.welcome ||
                          OnboardingStep.summary => art(),
                          _ => OnboardingArcade(
                            count: state.total,
                            lit: state.index + 1,
                          ),
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The step's number and question on the page, heading the step where the
/// stage has its own pane (wide windows, tabletop). Large, so the step
/// reads as one composed block beside the art.
class OnboardingStepHeading extends StatelessWidget {
  const OnboardingStepHeading({super.key, required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final state = context.watch<OnboardingCubit>().state;
    final choices = state.steps.where((step) => step.isChoice).toList();
    final number = choices.indexOf(step) + 1;
    final size = MediaQuery.sizeOf(context);
    final wide = size.height >= 600;
    final large = size.width >= 700 && size.height >= 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (step.isChoice || state.reviewing) ...[
          Text(
            (state.reviewing
                    ? step.label(l10n)
                    : l10n.prayerSetupStepLabel(number, choices.length))
                .toUpperCase(),
            style: context.type.eyebrow.copyWith(
              color: theme.colorScheme.tertiary,
            ),
          ),
          SizedBox(height: space.xs),
        ],
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.6,
          child: Semantics(
            header: true,
            child: Text(
              step.title(l10n),
              style: large
                  ? theme.textTheme.displaySmall
                  : wide
                  ? theme.textTheme.headlineLarge
                  // Short landscape windows: a smaller heading leaves the
                  // step its room.
                  : size.height < 480
                  ? theme.textTheme.titleLarge
                  : theme.textTheme.headlineSmall,
            ),
          ),
        ),
        if (step == OnboardingStep.welcome) ...[
          SizedBox(height: space.xs),
          Text(
            l10n.setupWelcomeMessage,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        SizedBox(height: space.xl),
      ],
    );
  }
}
