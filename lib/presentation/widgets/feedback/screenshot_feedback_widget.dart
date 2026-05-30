import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class ScreenshotFeedbackWidget extends StatefulWidget {
  final OnSubmit onSubmit;
  final ScrollController? scrollController;

  const ScreenshotFeedbackWidget({
    super.key,
    required this.onSubmit,
    this.scrollController,
  });

  @override
  State<ScreenshotFeedbackWidget> createState() =>
      _ScreenshotFeedbackWidgetState();
}

class _ScreenshotFeedbackWidgetState extends State<ScreenshotFeedbackWidget> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    widget.onSubmit(
      _textController.text,
      extras: email.isNotEmpty ? {'email': email} : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final fillColor =
        isDark ? Colors.grey.shade900 : Colors.grey.shade50;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: EdgeInsets.all(16.w),
            children: [
              Text(
                'What happened?',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Amiri',
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _textController,
                maxLines: 5,
                maxLength: 1000,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: textColor,
                  fontFamily: 'Amiri',
                ),
                decoration: InputDecoration(
                  hintText: 'Describe the issue or feedback...',
                  hintStyle: TextStyle(
                    color: subtitleColor,
                    fontFamily: 'Amiri',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide:
                        BorderSide(color: context.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: fillColor,
                  counterStyle:
                      TextStyle(color: subtitleColor, fontFamily: 'Amiri'),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: textColor,
                  fontFamily: 'Amiri',
                ),
                decoration: InputDecoration(
                  hintText: 'Email (optional — for a reply)',
                  hintStyle: TextStyle(
                    color: subtitleColor,
                    fontFamily: 'Amiri',
                  ),
                  prefixIcon: Icon(
                    Icons.mail_outline_rounded,
                    color: subtitleColor,
                    size: 18.sp,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide:
                        BorderSide(color: context.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: fillColor,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 14.h),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
            child: SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: Icon(Icons.send_rounded, size: 18.sp),
                label: Text(
                  'Send Feedback',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Amiri',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
