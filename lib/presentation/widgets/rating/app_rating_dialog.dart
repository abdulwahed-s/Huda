import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/rating/rating_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/feedback/feedback_form_card.dart';
import 'package:huda/presentation/widgets/rating/star_rating_input.dart';

/// "Enjoying Huda?": five stars; under four, a short note and an optional
/// email open below them. Led by the lit lamp (an invitation). From Home
/// it offers "Maybe later" and "Don't ask again"; from Settings, Cancel.
class AppRatingDialog extends StatelessWidget {
  final bool showDismissActions;

  const AppRatingDialog({super.key, this.showDismissActions = true});

  @override
  Widget build(BuildContext context) {
    return _AppRatingDialog(showDismissActions: showDismissActions);
  }
}

class _AppRatingDialog extends StatefulWidget {
  const _AppRatingDialog({required this.showDismissActions});

  final bool showDismissActions;

  @override
  State<_AppRatingDialog> createState() => _AppRatingDialogState();
}

class _AppRatingDialogState extends State<_AppRatingDialog>
    with TickerProviderStateMixin {
  double _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _missingRating = false;
  bool _missingNote = false;
  bool _failed = false;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final AnimationController _starPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );

  bool get _wantsNote => _rating > 0 && _rating < 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tokens = context.tokens;
    _entrance.duration = tokens.motion.of(context, tokens.motion.medium);
    _starPulse.duration = tokens.motion.of(context, tokens.motion.short);
    if (!_entrance.isAnimating && _entrance.value == 0) {
      _entrance.duration == Duration.zero
          ? _entrance.value = 1
          : _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _starPulse.dispose();
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onRatingChanged(double rating) {
    if (rating != _rating) HudaHaptics.selection(context);
    setState(() {
      _rating = rating;
      _missingRating = false;
      _failed = false;
    });
    if (_starPulse.duration != Duration.zero) {
      _starPulse.forward(from: 0).then((_) {
        if (mounted) _starPulse.reverse();
      });
    }
  }

  void _submitRating() {
    if (_rating == 0) {
      setState(() => _missingRating = true);
      return;
    }
    if (_wantsNote && _feedbackController.text.trim().isEmpty) {
      setState(() => _missingNote = true);
      return;
    }
    setState(() => _failed = false);
    final email = _emailController.text.trim();
    context.read<RatingCubit>().handleRating(
      _rating.toInt(),
      comment: _feedbackController.text.trim(),
      contactEmail: email.isNotEmpty ? email : null,
    );
  }

  void _dismiss() {
    context.read<RatingCubit>().callLater();
    Navigator.of(context).pop();
  }

  void _neverAskAgain() {
    context.read<RatingCubit>().callNever();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final short = MediaQuery.sizeOf(context).height < 700;
    final curve = CurvedAnimation(
      parent: _entrance,
      curve: tokens.motion.emphasized,
    );

    return BlocListener<RatingCubit, RatingState>(
      listener: (context, state) {
        if (state is RatingSubmitted) {
          HudaHaptics.light(context);
          final message = _rating >= 4
              ? l10n.thankYouRedirect
              : l10n.thankYouFeedback;
          Navigator.of(context).pop();
          showHudaToast(context, message: message);
        } else if (state is RatingFailure) {
          setState(() => _failed = true);
        }
      },
      child: FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curve),
          child: Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              // The actions stay pinned; the stars and note scroll above
              // them on short screens.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        space.lg,
                        space.lg,
                        space.lg,
                        space.md,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Short windows (landscape phones) give the note
                          // the room: no lamp, a smaller title.
                          if (!short) ...[
                            const Center(
                              child: HudaLamp(
                                size: 56,
                                child: Icon(Icons.star_rounded),
                              ),
                            ),
                            SizedBox(height: space.md),
                          ],
                          Text(
                            l10n.rateAppTitle,
                            textAlign: TextAlign.center,
                            style: short
                                ? theme.textTheme.titleLarge
                                : theme.textTheme.headlineSmall,
                          ),
                          SizedBox(height: space.xs),
                          Text(
                            l10n.rateExperienceQuestion,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: short ? space.sm : space.lg),
                          Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 1,
                                  end: 1.08,
                                ).animate(_starPulse),
                                child: StarRatingInput(
                                  key: const ValueKey('rating-stars'),
                                  initialRating: _rating,
                                  minRating: 1,
                                  allowHalfRating: true,
                                  itemCount: 5,
                                  itemSize: 40,
                                  spacing: space.xs,
                                  color: scheme.primary,
                                  unratedColor: scheme.onSurfaceVariant,
                                  unratedIcon: Icons.star_outline_rounded,
                                  onRatingUpdate: _onRatingChanged,
                                ),
                              ),
                            ),
                          ),
                          HudaAnimatedSize(
                            alignment: Alignment.topCenter,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_missingRating)
                                  Padding(
                                    padding: EdgeInsets.only(top: space.xs),
                                    child: Text(
                                      l10n.pleaseSelectRating,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: scheme.error),
                                    ),
                                  ),
                                if (_wantsNote) ...[
                                  SizedBox(height: short ? space.sm : space.lg),
                                  TextField(
                                    key: const ValueKey('rating-note'),
                                    controller: _feedbackController,
                                    minLines: short ? 1 : 2,
                                    maxLines: 4,
                                    maxLength: 200,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    onChanged: (_) {
                                      if (_missingNote) {
                                        setState(() => _missingNote = false);
                                      }
                                    },
                                    decoration: feedbackFieldDecoration(
                                      context,
                                      label: l10n.helpUsImprove,
                                      hint: l10n.feedbackHint,
                                      error: _missingNote
                                          ? l10n.provideFeedback
                                          : null,
                                    ),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  SizedBox(height: space.xs),
                                  TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    decoration: feedbackFieldDecoration(
                                      context,
                                      label: l10n.emailOptional,
                                      prefixIcon: const Icon(
                                        Icons.alternate_email_rounded,
                                      ),
                                    ),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                                if (_failed)
                                  Padding(
                                    padding: EdgeInsets.only(top: space.md),
                                    child: HudaStatusBanner(
                                      status: HudaStatus.failed,
                                      message: l10n.unexpectedError,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      space.lg,
                      0,
                      space.lg,
                      space.md,
                    ),
                    child: BlocBuilder<RatingCubit, RatingState>(
                      builder: (context, state) {
                        final busy = state is RatingSubmitting;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: FilledButton(
                                key: const ValueKey('rating-submit'),
                                onPressed: busy ? () {} : _submitRating,
                                child: busy
                                    ? HudaLampSpinner(
                                        size: 20,
                                        color: theme
                                            .filledButtonTheme
                                            .style
                                            ?.foregroundColor
                                            ?.resolve(const {}),
                                      )
                                    : Text(l10n.rateButton),
                              ),
                            ),
                            SizedBox(height: space.xs),
                            if (widget.showDismissActions)
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: space.xs,
                                children: [
                                  TextButton(
                                    onPressed: busy ? null : _dismiss,
                                    child: Text(l10n.maybeLater),
                                  ),
                                  TextButton(
                                    onPressed: busy ? null : _neverAskAgain,
                                    child: Text(l10n.dontAskAgain),
                                  ),
                                ],
                              )
                            else
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: Text(l10n.cancel),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
