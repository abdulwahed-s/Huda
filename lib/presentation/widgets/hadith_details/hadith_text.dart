import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_html/flutter_html.dart';

class HadithText extends StatelessWidget {
  final String text;
  final bool isDark;
  final String currentLanguageCode;

  const HadithText({
    super.key,
    required this.text,
    required this.isDark,
    required this.currentLanguageCode,
  });

  String _convertToHtml(String text) {
    String converted = text
        .replaceAll('[prematn]', '<span class="prematn">')
        .replaceAll('[/prematn]', '</span>')
        .replaceAll('[matn]', '<span class="matn">')
        .replaceAll('[/matn]', '</span>');

    converted = converted.replaceAllMapped(
      RegExp(r'\[narrator id="([^"]*)" tooltip="([^"]*)"\]'),
      (match) => '<span class="narrator" title="${match.group(2)}">',
    );
    converted = converted.replaceAll('[/narrator]', '</span>');

    return converted;
  }

  @override
  Widget build(BuildContext context) {
    return Html(
      data: _convertToHtml(text),
      style: {
        "*": Style(
          fontSize: FontSize(16.0.sp),
          fontFamily: "Amiri",
          lineHeight: LineHeight.number(1.6),
          color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
          textAlign:
              currentLanguageCode == "ar" ? TextAlign.right : TextAlign.left,
        ),
        ".matn": Style(
          fontWeight: FontWeight.bold,
        ),
        ".narrator": Style(
          color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
        ),
      },
    );
  }
}
