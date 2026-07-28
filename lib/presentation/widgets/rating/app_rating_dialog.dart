import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/presentation/widgets/rating/star_rating_input.dart';
import 'package:huda/cubit/rating/rating_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';

class AppRatingDialog extends StatefulWidget {
  final bool showDismissActions;

  const AppRatingDialog({super.key, this.showDismissActions = true});

  @override
  State<AppRatingDialog> createState() => _AppRatingDialogState();
}

class _AppRatingDialogState extends State<AppRatingDialog>
    with TickerProviderStateMixin {
  double _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _showFeedbackField = false;
  late AnimationController _animationController;
  late AnimationController _starAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _starScaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _starAnimationController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _starScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _starAnimationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _starAnimationController.dispose();
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onRatingChanged(double rating) {
    setState(() {
      _rating = rating;
      _showFeedbackField = rating < 4;
    });

    HapticFeedback.selectionClick();

    _starAnimationController.forward(from: 0).then((_) {
      if (mounted) _starAnimationController.reverse();
    });
  }

  void _submitRating() {
    if (_rating == 0) {
      HapticFeedback.selectionClick();
      HudaSnackBar.warning(
        context,
        message: AppLocalizations.of(context)!.pleaseSelectRating,
      );
      return;
    }

    if (_showFeedbackField && _feedbackController.text.trim().isEmpty) {
      HapticFeedback.selectionClick();
      HudaSnackBar.warning(
        context,
        message: AppLocalizations.of(context)!.provideFeedback,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final email = _emailController.text.trim();
    context.read<RatingCubit>().handleRating(
          _rating.toInt(),
          comment: _feedbackController.text.trim(),
          contactEmail: email.isNotEmpty ? email : null,
        );
  }

  void _dismiss() {
    HapticFeedback.lightImpact();
    context.read<RatingCubit>().callLater();
    Navigator.of(context).pop();
  }

  void _neverAskAgain() {
    HapticFeedback.lightImpact();
    context.read<RatingCubit>().callNever();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<RatingCubit, RatingState>(
      listener: (context, state) {
        if (state is RatingSubmitted) {
          HapticFeedback.heavyImpact();
          Navigator.of(context).pop();

          String message = _rating >= 4
              ? AppLocalizations.of(context)!.thankYouRedirect
              : AppLocalizations.of(context)!.thankYouFeedback;

          HudaSnackBar.success(
            context,
            message: message,
          );
        } else if (state is RatingFailure) {
          HapticFeedback.heavyImpact();
          HudaSnackBar.error(
            context,
            message: state.message,
          );
        }
      },
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AlertDialog(
            backgroundColor: isDark ? context.darkCardBackground : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            contentPadding: EdgeInsets.all(24.w),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.primaryColor,
                            context.accentColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 30.sp,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      AppLocalizations.of(context)!.rateAppTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? context.darkText : const Color(0xFF1E293B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      AppLocalizations.of(context)!.rateExperienceQuestion,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.grey.shade400
                            : const Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ScaleTransition(
                        scale: _starScaleAnimation,
                        child: StarRatingInput(
                          initialRating: _rating,
                          minRating: 1,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 40.sp,
                          spacing: 8.w,
                          color: context.primaryColor,
                          unratedColor: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                          onRatingUpdate: _onRatingChanged,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SizeTransition(
                          sizeFactor: animation,
                          alignment: Alignment.topCenter,
                          child: child,
                        ),
                      ),
                      child: _showFeedbackField
                          ? Container(
                              key: const ValueKey('feedback'),
                              width: double.infinity,
                              padding: EdgeInsets.only(top: 8.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.helpUsImprove,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? context.darkText
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  TextField(
                                    controller: _feedbackController,
                                    maxLines: 2,
                                    maxLength: 200,
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(context)!
                                          .feedbackHint,
                                      hintStyle: TextStyle(
                                        color: isDark
                                            ? Colors.grey.shade500
                                            : Colors.grey.shade600,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                        borderSide: BorderSide(
                                          color: context.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? Colors.grey.shade900
                                          : Colors.grey.shade50,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 8.h,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: isDark
                                          ? context.darkText
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(context)!
                                          .emailOptional,
                                      hintStyle: TextStyle(
                                        color: isDark
                                            ? Colors.grey.shade500
                                            : Colors.grey.shade600,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.mail_outline_rounded,
                                        color: isDark
                                            ? Colors.grey.shade500
                                            : Colors.grey.shade600,
                                        size: 18.sp,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                        borderSide: BorderSide(
                                          color: context.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? Colors.grey.shade900
                                          : Colors.grey.shade50,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 8.h,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: isDark
                                          ? context.darkText
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(
                              key: ValueKey('empty'),
                              width: double.infinity,
                            ),
                    ),
                    SizedBox(height: 24.h),
                    BlocBuilder<RatingCubit, RatingState>(
                      builder: (context, state) {
                        final isLoading = state is RatingSubmitting;

                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 48.h,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _submitRating,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  elevation: 2,
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        width: 20.w,
                                        height: 20.w,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        AppLocalizations.of(context)!
                                            .rateButton,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            if (widget.showDismissActions) ...[
                              SizedBox(height: 12.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: isLoading ? null : _dismiss,
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .maybeLater,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton(
                                      onPressed:
                                          isLoading ? null : _neverAskAgain,
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .dontAskAgain,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              SizedBox(height: 12.h),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  child: Text(
                                    AppLocalizations.of(context)!.cancel,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
