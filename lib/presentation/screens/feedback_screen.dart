import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/rating/rating_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/feedback/feedback_form_card.dart';
import 'package:huda/presentation/widgets/feedback/feedback_hero_card.dart';
import 'package:huda/presentation/widgets/feedback/feedback_privacy_card.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with TickerProviderStateMixin {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    _feedbackController.dispose();
    _emailController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      HapticFeedback.selectionClick();
      HudaSnackBar.warning(
        context,
        message: AppLocalizations.of(context)!.feedbackEmptyWarning,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final email = _emailController.text.trim();
    context.read<RatingCubit>().submitDetailedFeedback(
          feedback,
          contactEmail: email.isNotEmpty ? email : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final backgroundColor =
        isDark ? context.darkGradientStart : const Color(0xFFF8FAFC);
    final textColor = isDark ? context.darkText : const Color(0xFF1E293B);
    final subtitleColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: textColor,
            size: 24.sp,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.feedbackAppBarTitle,
          style: TextStyle(
            color: textColor,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: BlocConsumer<RatingCubit, RatingState>(
            listener: (context, state) {
              if (state is FeedbackSubmitted) {
                HapticFeedback.heavyImpact();
                Navigator.of(context).pop();
                HudaSnackBar.success(
                  context,
                  message: l10n.feedbackSuccessMessage,
                );
              } else if (state is FeedbackFailure) {
                HapticFeedback.heavyImpact();
                HudaSnackBar.error(
                  context,
                  message: state.message,
                );
              }
            },
            builder: (context, state) {
              final isSubmitting = state is FeedbackSubmitting;

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.all(20.w),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        SizedBox(height: 20.h),
                        FeedbackHeroCard(
                          slideAnimation: _slideAnimation,
                          theme: theme,
                          l10n: l10n,
                        ),
                        SizedBox(height: 28.h),
                        FeedbackFormCard(
                          slideAnimation: _slideAnimation,
                          feedbackController: _feedbackController,
                          emailController: _emailController,
                          focusNode: _focusNode,
                          isSubmitting: isSubmitting,
                          submitFeedback: _submitFeedback,
                          theme: theme,
                          l10n: l10n,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          borderColor: borderColor,
                          isDark: isDark,
                        ),
                        SizedBox(height: 28.h),
                        FeedbackPrivacyCard(
                          slideAnimation: _slideAnimation,
                          l10n: l10n,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                        SizedBox(height: 32.h),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
