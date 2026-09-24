import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/rating/rating_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/feedback/feedback_form_card.dart';
import 'package:huda/presentation/widgets/feedback/feedback_privacy_card.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';

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
      HapticFeedback.selectionClick();
      setState(() => _showFeedbackError = true);
      _feedbackFocusNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final fieldContext = _feedbackFieldKey.currentContext;
        if (!mounted || fieldContext == null) return;
        Scrollable.ensureVisible(
          fieldContext,
          alignment: 0.45,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      });
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    TextInput.finishAutofillContext();
    HapticFeedback.mediumImpact();

    final email = _emailController.text.trim();
    context.read<RatingCubit>().submitFeedback(
      feedback,
      category: _category,
      contactEmail: email.isNotEmpty ? email : null,
    );
  }

  void _selectCategory(FeedbackCategory category) {
    if (_category == category) return;
    HapticFeedback.selectionClick();
    setState(() => _category = category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final pageGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [
              context.darkGradientStart,
              Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.035),
                colorScheme.surface,
              ),
              colorScheme.surface,
            ]
          : [
              Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.075),
                const Color(0xFFF8FAFC),
              ),
              const Color(0xFFF8FAFC),
              colorScheme.surface,
            ],
      stops: const [0, 0.48, 1],
    );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: pageGradient),
      child: BlocConsumer<RatingCubit, RatingState>(
        listener: (context, state) {
          if (state is FeedbackSubmitted) {
            HapticFeedback.mediumImpact();
            HudaSnackBar.success(context, message: l10n.feedbackSuccessMessage);
            Navigator.of(context).pop(true);
          } else if (state is FeedbackFailure) {
            HapticFeedback.vibrate();
            HudaSnackBar.error(
              context,
              message: l10n.unexpectedError,
              action: HudaSnackBarAction(
                label: l10n.retry,
                onPressed: _submitFeedback,
              ),
              dismissible: true,
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state is FeedbackSubmitting;

          return PopScope(
            canPop: !isSubmitting,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                foregroundColor: colorScheme.onSurface,
                elevation: 0,
                scrolledUnderElevation: 0,
                systemOverlayStyle: isDark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark,
                leading: BackButton(
                  color: colorScheme.onSurface,
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).maybePop(),
                ),
                titleSpacing: 4,
                title: Text(
                  l10n.feedbackAppBarTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              body: SafeArea(
                top: false,
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding = constraints.maxWidth >= 700
                        ? 24.0
                        : 16.0;

                    return ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: EdgeInsetsDirectional.fromSTEB(
                        horizontalPadding,
                        8,
                        horizontalPadding,
                        28,
                      ),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _FeedbackHero(l10n: l10n),
                                SizedBox(height: 18.h),
                                FeedbackFormCard(
                                  feedbackFieldKey: _feedbackFieldKey,
                                  feedbackController: _feedbackController,
                                  emailController: _emailController,
                                  feedbackFocusNode: _feedbackFocusNode,
                                  emailFocusNode: _emailFocusNode,
                                  selectedCategory: _category,
                                  onCategoryChanged: _selectCategory,
                                  onFeedbackSubmitted: _submitFeedback,
                                  feedbackErrorText: _showFeedbackError
                                      ? l10n.feedbackEmptyWarning
                                      : null,
                                  isSubmitting: isSubmitting,
                                  l10n: l10n,
                                ),
                                SizedBox(height: 14.h),
                                FeedbackPrivacyCard(l10n: l10n),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              bottomNavigationBar: _FeedbackSubmitBar(
                isSubmitting: isSubmitting,
                l10n: l10n,
                onSubmit: _submitFeedback,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeedbackHero extends StatelessWidget {
  const _FeedbackHero({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Semantics(
      container: true,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [context.primaryDarkColor, context.primaryColor],
          ),
          borderRadius: BorderRadius.circular(26.r),
          boxShadow: [
            BoxShadow(
              color: context.primaryColor.withValues(alpha: 0.24),
              blurRadius: 24.r,
              offset: Offset(0, 10.h),
            ),
          ],
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -52,
              end: -36,
              child: _HeroOrb(
                size: 148,
                color: Colors.white.withValues(alpha: 0.075),
              ),
            ),
            PositionedDirectional(
              bottom: -66,
              start: 54,
              child: _HeroOrb(
                size: 118,
                color: Colors.white.withValues(alpha: 0.045),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(22.w),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stackContent =
                      constraints.maxWidth < 260 || textScale > 1.35;
                  final icon = Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Icon(
                      Icons.forum_rounded,
                      color: Colors.white,
                      size: 28.sp,
                    ),
                  );
                  final copy = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.feedbackHeroTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ),
                      SizedBox(height: 7.h),
                      Text(
                        l10n.feedbackHeroSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                      ),
                    ],
                  );

                  return stackContent
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            icon,
                            SizedBox(height: 16.h),
                            copy,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            icon,
                            SizedBox(width: 16.w),
                            Expanded(child: copy),
                          ],
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _FeedbackSubmitBar extends StatelessWidget {
  const _FeedbackSubmitBar({
    required this.isSubmitting,
    required this.l10n,
    required this.onSubmit,
  });

  final bool isSubmitting;
  final AppLocalizations l10n;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.97),
        border: Border(
          top: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.22 : 0.07,
            ),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                key: const ValueKey('feedback-submit-button'),
                onPressed: isSubmitting ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  disabledBackgroundColor: colorScheme.primary.withValues(
                    alpha: 0.62,
                  ),
                  disabledForegroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17.r),
                  ),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  child: isSubmitting
                      ? Row(
                          key: const ValueKey('feedback-submitting'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox.square(
                              dimension: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                l10n.feedbackSending,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          key: const ValueKey('feedback-ready'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.send_rounded, size: 20.sp),
                            const SizedBox(width: 9),
                            Flexible(
                              child: Text(
                                l10n.feedbackSendButton,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
