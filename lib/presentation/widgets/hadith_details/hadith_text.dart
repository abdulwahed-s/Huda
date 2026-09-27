import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/utils/hadith_text_formatter.dart';

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

  @override
  Widget build(BuildContext context) {
    final isArabic = currentLanguageCode == 'ar';
    final baseStyle = TextStyle(
      fontSize: 16.0.sp,
      height: 1.6,
      color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
    );
    final narratorColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
    final quranColor = isDark ? Colors.green.shade300 : Colors.green.shade800;
    final formatted = HadithTextFormatter.format(text);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          for (final run in formatted.runs)
            TextSpan(
              text: run.text,
              style: baseStyle.copyWith(
                fontWeight: run.bold ? FontWeight.bold : null,
                fontStyle: run.italic ? FontStyle.italic : null,
                color: run.narrator
                    ? narratorColor
                    : run.quran
                    ? quranColor
                    : null,
              ),
            ),
        ],
      ),
      textAlign: isArabic ? TextAlign.right : TextAlign.left,
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
    );
  }
}
