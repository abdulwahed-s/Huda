import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/rating/rating_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class AppRatingDialog extends StatefulWidget {
  const AppRatingDialog({super.key});

  @override
  State<AppRatingDialog> createState() => _AppRatingDialogState();
}

class _AppRatingDialogState extends State<AppRatingDialog>
    with TickerProviderStateMixin {
  double _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _showFeedbackField = false;
  late AnimationController _animationController;
  late AnimationController _starAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _starScaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _starAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _starScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _starAnimationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _starAnimationController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _onRatingChanged(double rating) {
    setState(() {
      _rating = rating;
      _showFeedbackField = rating < 3.5;
    });

    HapticFeedback.selectionClick();

    _starAnimationController.forward().then((_) {
      _starAnimationController.reverse();
    });
  }

  void _submitRating() {
    if (_rating == 0) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                AppLocalizations.of(context)!.pleaseSelectRating,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: "Amiri",
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
      return;
    }

    if (_showFeedbackField && _feedbackController.text.trim().isEmpty) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                AppLocalizations.of(context)!.provideFeedback,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: "Amiri",
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    context.read<RatingCubit>().handleRating(
          _rating.toInt(),
          comment: _feedbackController.text.trim(),
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

          String message = _rating >= 3.5
              ? AppLocalizations.of(context)!.thankYouRedirect
              : AppLocalizations.of(context)!.thankYouFeedback;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: "Amiri",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: context.accentColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              margin: EdgeInsets.all(16.w),
            ),
          );
        } else if (state is RatingFailure) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      state.message,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: "Amiri",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          );
        }
      },
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
                      fontFamily: "Amiri",
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
                      fontFamily: "Amiri",
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ScaleTransition(
                      scale: _starScaleAnimation,
                      child: RatingBar.builder(
                        initialRating: _rating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 40.sp,
                        itemPadding: EdgeInsets.symmetric(horizontal: 4.w),
                        itemBuilder: (context, index) => Icon(
                          Icons.star,
                          color: context.primaryColor,
                        ),
                        unratedColor: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                        onRatingUpdate: _onRatingChanged,
                        glow: true,
                        glowColor: context.primaryColor.withValues(alpha: 0.3),
                        glowRadius: 2,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _showFeedbackField
                        ? Container(
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
                                    fontFamily: "Amiri",
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
                                      fontFamily: "Amiri",
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? Colors.grey.shade700
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
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
                                    fontFamily: "Amiri",
                                    color: isDark
                                        ? context.darkText
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
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
                                      AppLocalizations.of(context)!.rateButton,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: "Amiri",
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: isLoading ? null : _dismiss,
                                  child: Text(
                                    AppLocalizations.of(context)!.maybeLater,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                      fontFamily: "Amiri",
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: isLoading ? null : _neverAskAgain,
                                  child: Text(
                                    AppLocalizations.of(context)!.dontAskAgain,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                      fontFamily: "Amiri",
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
