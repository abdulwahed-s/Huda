import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

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
  bool _showDescriptionError = false;

  @override
  void dispose() {
    _textController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final description = _textController.text.trim();
    if (description.isEmpty) {
      setState(() {
        _showDescriptionError = true;
      });
      return;
    }

    final email = _emailController.text.trim();
    widget.onSubmit(
      description,
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
    final fillColor = isDark ? Colors.grey.shade900 : Colors.grey.shade50;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              ListView(
                controller: widget.scrollController,
                padding: EdgeInsets.fromLTRB(
                  16.w,
                  widget.scrollController != null ? 22.h : 14.h,
                  16.w,
                  8.h,
                ),
                children: [
                  Text(
                    AppLocalizations.of(context)!.whatHappened,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _textController,
                    minLines: 4,
                    maxLines: 6,
                    maxLength: 1000,
                    onChanged: (value) {
                      if (_showDescriptionError && value.trim().isNotEmpty) {
                        setState(() {
                          _showDescriptionError = false;
                        });
                      }
                    },
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.describeIssueHint,
                      hintStyle: TextStyle(
                        color: subtitleColor,
                      ),
                      errorText: _showDescriptionError
                          ? AppLocalizations.of(context)!.feedbackEmptyWarning
                          : null,
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
                      counterStyle: TextStyle(
                        color: subtitleColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.emailOptional,
                      hintStyle: TextStyle(
                        color: subtitleColor,
                      ),
                      prefixIcon: Icon(
                        Icons.mail_outline_rounded,
                        color: subtitleColor,
                        size: 20.sp,
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
                        horizontal: 16.w,
                        vertical: 16.h,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.scrollController != null)
                const FeedbackSheetDragHandle(),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 10.h),
            child: SizedBox(
              width: double.infinity,
              height: 44.h,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: Icon(Icons.send_rounded, size: 17.sp),
                label: Text(
                  AppLocalizations.of(context)!.feedbackSendButton,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
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
