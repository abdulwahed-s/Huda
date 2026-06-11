import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';



class AudiobookTopBar extends StatelessWidget {
  final bool isDark;
  final bool isScrolled;

  const AudiobookTopBar({
    super.key,
    required this.isDark,
    this.isScrolled = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? context.darkText : context.lightText;

    Widget barContent = Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                size: 30.sp, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            AppLocalizations.of(context)!.audiobook,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
          SizedBox(width: 48.w),
        ],
      ),
    );

    if (isScrolled) {
      barContent = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white)
                  .withValues(alpha: 0.15),
              border: Border(
                bottom: BorderSide(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
            ),
            child: barContent,
          ),
        ),
      );
    }

    return barContent;
  }
}
