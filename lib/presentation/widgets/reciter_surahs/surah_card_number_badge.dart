import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SurahCardNumberBadge extends StatelessWidget {
  final String surahNum;
  final bool isPlaying;
  final ThemeData theme;

  const SurahCardNumberBadge({
    super.key,
    required this.surahNum,
    required this.isPlaying,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: 44.r,
      height: 44.r,
      decoration: BoxDecoration(
        gradient: isPlaying
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  Color.lerp(theme.colorScheme.primary,
                      theme.colorScheme.secondary, 0.5)!,
                ],
              )
            : null,
        color: isPlaying ? null : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Text(
          surahNum,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: isPlaying
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
