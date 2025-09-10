import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class ErrorDetailsCard extends StatefulWidget {
  final String errorMessage;
  final bool isDark;
  final Color borderColor;
  final Color shadowColor;
  final Color errorCodeBg;
  final Color errorCodeText;
  final Color textColor;
  
  const ErrorDetailsCard({
    required this.errorMessage,
    required this.isDark,
    required this.borderColor,
    required this.shadowColor,
    required this.errorCodeBg,
    required this.errorCodeText,
    required this.textColor,
    super.key,
  });

  @override
  State<ErrorDetailsCard> createState() => _ErrorDetailsCardState();
}

class _ErrorDetailsCardState extends State<ErrorDetailsCard> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? context.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: widget.borderColor, width: 1.5),
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
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _showDetails = !_showDetails);
            },
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.code_rounded,
                        color: context.primaryColor,
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Technical Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: widget.textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 17.sp,
                          fontFamily: "Amiri",
                        ),
                      ),
                    ],
                  ),
                  AnimatedRotation(
                    turns: _showDetails ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: context.primaryColor,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showDetails ? null : 0,
            child: _showDetails
                ? Column(
                    children: [
                      Divider(height: 1.h, color: widget.borderColor),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20.w),
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: widget.errorCodeBg,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: widget.borderColor,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.bug_report_rounded,
                                    color: widget.errorCodeText,
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Error Stack Trace',
                                    style: TextStyle(
                                      fontFamily: "Amiri",
                                      color: widget.errorCodeText,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Container(
                                constraints: BoxConstraints(maxHeight: 200.h),
                                child: SingleChildScrollView(
                                  child: SelectableText(
                                    widget.errorMessage,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontFamily: "monospace",
                                      color: widget.errorCodeText,
                                      fontSize: 11.sp,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ],
      ),
    );
  }
}