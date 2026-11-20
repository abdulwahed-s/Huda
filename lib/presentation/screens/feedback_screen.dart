import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/rating/rating_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/feedback/feedback_form_card.dart';
import 'package:huda/presentation/widgets/feedback/feedback_privacy_card.dart';
import 'package:huda/presentation/widgets/settings/settings_layout.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _feedbackFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final GlobalKey _feedbackFieldKey = GlobalKey();

  FeedbackCategory _category = FeedbackCategory.general;
  bool _showFeedbackError = false;

  @override
  void initState() {
    super.initState();
    _feedbackController.addListener(_clearResolvedValidationError);
  }

  @override
  void dispose() {
    _feedbackController
      ..removeListener(_clearResolvedValidationError)
      ..dispose();
    _emailController.dispose();
    _feedbackFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _clearResolvedValidationError() {
    if (_showFeedbackError && _feedbackController.text.trim().isNotEmpty) {
      setState(() => _showFeedbackError = false);
    }
  }

  void _submitFeedback() {
    if (context.read<RatingCubit>().state is FeedbackSubmitting) return;

    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      setState(() => _showFeedbackError = true);
      _feedbackFocusNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final fieldContext = _feedbackFieldKey.currentContext;
        if (!mounted || fieldContext == null) return;
        final tokens = context.tokens;
        Scrollable.ensureVisible(
          fieldContext,
          alignment: 0.45,
          duration: tokens.motion.of(context, tokens.motion.medium),
          curve: tokens.motion.standard,
        );
      });
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    TextInput.finishAutofillContext();

    final email = _emailController.text.trim();
    context.read<RatingCubit>().submitFeedback(
      feedback,
      category: _category,
      contactEmail: email.isNotEmpty ? email : null,
    );
  }

  void _selectCategory(FeedbackCategory category) {
    if (_category == category) return;
    HudaHaptics.selection(context);
    setState(() => _category = category);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);

    return BlocConsumer<RatingCubit, RatingState>(
      listener: (context, state) {
        if (state is FeedbackSubmitted) {
          HudaHaptics.light(context);
          showHudaToast(context, message: l10n.feedbackSuccessMessage);
          Navigator.of(context).pop(true);
        } else if (state is FeedbackFailure) {
          showHudaToast(
            context,
            message: l10n.unexpectedError,
            kind: HudaToastKind.failed,
            actionLabel: l10n.retry,
            onAction: _submitFeedback,
          );
        }
      },
      builder: (context, state) {
        final sending = state is FeedbackSubmitting;
        final width = MediaQuery.sizeOf(context).width;
        final twoColumns = SettingsColumns.showsTwo(context, width);
        final send = _SendButton(sending: sending, onSend: _submitFeedback);

        final page = SettingsColumns(
          maxWidth: 960,
          start: [
            if (twoColumns) ...[
              HudaReveal(
                child: Text(
                  l10n.feedbackHeroSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: space.xl),
            ],
            HudaReveal(
              index: 1,
              child: FeedbackKindChoice(
                selected: _category,
                enabled: !sending,
                onChanged: _selectCategory,
              ),
            ),
          ],
          end: [
            HudaReveal(
              index: 2,
              child: FeedbackFields(
                feedbackFieldKey: _feedbackFieldKey,
                feedbackController: _feedbackController,
                emailController: _emailController,
                feedbackFocusNode: _feedbackFocusNode,
                emailFocusNode: _emailFocusNode,
                category: _category,
                onSubmitted: _submitFeedback,
                errorText: _showFeedbackError
                    ? l10n.feedbackEmptyWarning
                    : null,
                enabled: !sending,
              ),
            ),
            SizedBox(height: space.lg),
            const HudaReveal(index: 3, child: FeedbackPrivacyNote()),
            if (twoColumns) ...[SizedBox(height: space.xl), send],
          ],
        );

        return PopScope(
          canPop: !sending,
          child: HudaScaffold(
            title: l10n.feedbackAppBarTitle,
            leading: BackButton(
              onPressed: sending
                  ? null
                  : () => Navigator.of(context).maybePop(),
            ),
            body: HudaRevealScope(
              child: twoColumns
                  ? page
                  : Column(
                      children: [
                        Expanded(
                          child: MediaQuery.removePadding(
                            context: context,
                            removeBottom: true,
                            child: page,
                          ),
                        ),
                        _SendBar(child: send),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _SendBar extends StatelessWidget {
  const _SendBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final scheme = Theme.of(context).colorScheme;
    final insets = MediaQuery.paddingOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          space.gutter(MediaQuery.sizeOf(context).width) + insets.left,
          space.sm,
          space.gutter(MediaQuery.sizeOf(context).width) + insets.right,
          space.sm + context.bottomInset,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.sending, required this.onSend});

  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final onLit = Theme.of(context).filledButtonTheme.style?.foregroundColor
        ?.resolve(const {});
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 52,
        minWidth: double.infinity,
      ),
      child: FilledButton(
        key: const ValueKey('feedback-submit-button'),
        onPressed: sending ? () {} : onSend,
        child: AnimatedSwitcher(
          duration: tokens.motion.of(context, tokens.motion.short),
          child: Row(
            key: ValueKey(sending),
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sending)
                HudaLampSpinner(size: 20, color: onLit)
              else
                const Icon(Icons.send_rounded, size: 20),
              SizedBox(width: tokens.space.xs),
              Flexible(
                child: Text(
                  sending ? l10n.feedbackSending : l10n.feedbackSendButton,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
