import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/error/error_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';

class FeedbackSection extends StatefulWidget {
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final Color borderColor;
  final Color shadowColor;
  final Color errorCodeBg;

  const FeedbackSection({
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.borderColor,
    required this.shadowColor,
    required this.errorCodeBg,
    super.key,
  });

  @override
  State<FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends State<FeedbackSection> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  void _submitFeedback() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      HapticFeedback.selectionClick();
      HudaSnackBar.warning(
        context,
        message: AppLocalizations.of(context)!.pleaseEnterMessage,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final email = _emailController.text.trim();
    context.read<ErrorCubit>().submitFeedback(
          message,
          contactEmail: email.isNotEmpty ? email : null,
        );
    _messageController.clear();
    _emailController.clear();
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<ErrorCubit, ErrorState>(
      listener: (context, state) {
        if (state is ErrorFailure) {
          HapticFeedback.heavyImpact();
          HudaSnackBar.error(
            context,
            message: state.message,
          );
        } else if (state is ErrorSubmitted) {
          HapticFeedback.lightImpact();
        }
      },
      builder: (context, state) {
        final isSubmitting = state is ErrorSubmitting;
        final isSubmitted = state is ErrorSubmitted;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: !isSubmitted
              ? Container(
                  key: const ValueKey('feedback'),
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: widget.cardColor,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: context.primaryLightColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.shadowColor,
                        blurRadius: 12.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color:
                                  context.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.feedback_rounded,
                              color: context.primaryColor,
                              size: 20.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            AppLocalizations.of(context)!.helpUsImproveTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: context.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 18.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        AppLocalizations.of(context)!.errorFeedbackPrompt,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: widget.subtitleColor,
                          fontSize: 14.sp,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: widget.shadowColor,
                              blurRadius: 4.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          maxLines: 4,
                          maxLength: 500,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: widget.textColor,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                AppLocalizations.of(context)!.errorFeedbackHint,
                            hintStyle: TextStyle(
                              fontSize: 14.sp,
                              color: widget.subtitleColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: widget.borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: widget.borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: context.primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: widget.errorCodeBg,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 16.h),
                            counterStyle: TextStyle(
                              fontSize: 12.sp,
                              color: widget.subtitleColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: widget.shadowColor,
                              blurRadius: 4.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: widget.textColor,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                AppLocalizations.of(context)!.emailOptional,
                            hintStyle: TextStyle(
                              fontSize: 14.sp,
                              color: widget.subtitleColor,
                            ),
                            prefixIcon: Icon(
                              Icons.mail_outline_rounded,
                              color: widget.subtitleColor,
                              size: 18.sp,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: widget.borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: widget.borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: context.primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: widget.errorCodeBg,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 14.h),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : _submitFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 4,
                            shadowColor:
                                context.primaryColor.withValues(alpha: 0.3),
                            disabledBackgroundColor: widget.subtitleColor,
                          ),
                          child: isSubmitting
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .feedbackSending,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send_rounded, size: 18.sp),
                                    SizedBox(width: 8.w),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .feedbackSendButton,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  key: const ValueKey('success'),
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade50,
                        Colors.green.shade100,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.green.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green.shade600,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.feedbackThankYou,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w700,
                                fontSize: 16.sp,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              AppLocalizations.of(context)!
                                  .feedbackThankYouMessage,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.green.shade700,
                                fontSize: 14.sp,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
