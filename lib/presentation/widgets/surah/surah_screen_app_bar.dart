import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class SurahScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String surahName;
  final int surahNumber;
  final String? englishName;
  final VoidCallback onBack;
  final VoidCallback onMenu;

  const SurahScreenAppBar({
    super.key,
    required this.surahName,
    required this.surahNumber,
    required this.onBack,
    required this.onMenu,
    this.englishName,
  });

  @override
  Size get preferredSize => Size.fromHeight(90.h);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  context.darkGradientStart,
                  context.darkGradientMid,
                  context.darkGradientEnd,
                ]
              : [
                  context.primaryColor,
                  context.primaryVariantColor,
                  context.primaryLightColor,
                ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          child: Row(
            children: [
              _CircleIconButton(
                icon: Icons.arrow_back_ios_new,
                onPressed: onBack,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      surahName,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1.h),
                            blurRadius: 2.r,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!
                                .surahNumberBadge(surahNumber),
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 5.w),
                        if (englishName != null)
                          Flexible(
                            child: Text(
                              englishName!,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.white70,
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              _CircleIconButton(
                icon: Icons.menu_rounded,
                onPressed: onMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: Colors.white,
          size: 16.sp,
        ),
      ),
    );
  }
}
