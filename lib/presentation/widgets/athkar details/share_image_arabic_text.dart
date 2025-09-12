import 'package:flutter/material.dart';

class ShareImageArabicText extends StatelessWidget {
  final String arabicText;
  final bool isDark;
  final ColorScheme colorScheme;

  const ShareImageArabicText({
    super.key,
    required this.arabicText,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        arabicText,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          height: 2.2,
          color: isDark ? const Color(0xFF1A1A2E) : colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }
}
