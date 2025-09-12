import 'package:flutter/material.dart';

class ShareImageTranslation extends StatelessWidget {
  final String translatedText;
  final bool isDark;
  final ColorScheme colorScheme;

  const ShareImageTranslation({
    super.key,
    required this.translatedText,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        translatedText,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          height: 1.8,
          color: isDark ? const Color(0xFF1A1A2E) : colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
