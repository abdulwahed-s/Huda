import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/error/error_cubit.dart';

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
  final FocusNode _focusNode = FocusNode();

  void _submitFeedback() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 20.sp),
              SizedBox(width: 8.w),
              Text('Please enter a message before sending',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily: "Amiri",
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          margin: EdgeInsets.all(16.w),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    context.read<ErrorCubit>().submitFeedback(message);
    _messageController.clear();
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _messageController.dispose();
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(state.message,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: "Amiri",
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
              margin: EdgeInsets.all(16.w),
            ),
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
                              color: context.primaryColor.withValues(alpha: 0.1),
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
                            'Help us improve',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: context.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 18.sp,
                              fontFamily: "Amiri",
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'What were you doing when this error occurred? Your feedback helps us fix these issues faster.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: widget.subtitleColor,
                          fontSize: 14.sp,
                          fontFamily: "Amiri",
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
                            fontFamily: "Amiri",
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: 'I was trying to...',
                            hintStyle: TextStyle(
                              fontSize: 14.sp,
                              color: widget.subtitleColor,
                              fontFamily: "Amiri",
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
                              fontFamily: "Amiri",
                            ),
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
                            shadowColor: context.primaryColor
                                .withValues(alpha: 0.3),
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
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      'Sending...',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: "Amiri",
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
                                      'Send Feedback',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: "Amiri",
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
                              'Thank you!',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w700,
                                fontSize: 16.sp,
                                fontFamily: "Amiri",
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Your feedback has been sent. We\'ll use it to improve the app.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.green.shade700,
                                fontSize: 14.sp,
                                fontFamily: "Amiri",
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