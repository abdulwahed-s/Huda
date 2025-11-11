import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:html/parser.dart' as html_parser;

class HadithHeading extends StatelessWidget {
  final String heading;
  final bool isDark;

  const HadithHeading({
    super.key,
    required this.heading,
    required this.isDark,
  });

  String _cleanHeading(String input) {
    String cleaned = input;

    cleaned = cleaned
        .replaceAll('<br>', '\n')
        .replaceAll('</p>', '\n')
        .replaceAll('<p>', '\n');

    final document = html_parser.parse(cleaned);
    cleaned = document.body?.text ?? '';

    cleaned = cleaned.replaceAll(
      RegExp(r'\[/?[a-zA-Z0-9_\-]+(=[^\]]+)?\]'),
      '',
    );

    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final cleanedHeading = _cleanHeading(heading);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.0.h),
      padding: EdgeInsets.all(16.0.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor.withValues(alpha: 0.1),
            context.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Text(
        cleanedHeading,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18.0.sp,
          fontWeight: FontWeight.bold,
          fontFamily: "Amiri",
          color: context.primaryColor,
        ),
      ),
    );
  }
}
