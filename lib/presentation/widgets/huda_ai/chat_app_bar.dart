import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/theme/theme_extension.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;
  final AppLocalizations appLocalizations;

  const ChatAppBar({
    super.key,
    required this.isDark,
    required this.appLocalizations,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      iconTheme: IconThemeData(
        color: isDark ? context.darkText : context.lightText,
      ),
      elevation: 0,
      backgroundColor: isDark ? context.darkCardBackground : Colors.white,
      shadowColor: isDark ? Colors.black26 : Colors.grey.withValues(alpha: 0.1),
      surfaceTintColor: Colors.transparent,
      toolbarHeight: kIsWeb ? 65.h : 55.h,
      title: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: kIsWeb ? const EdgeInsets.all(12) : EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primaryColor.withValues(alpha: 0.15),
                  context.primaryColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: context.primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.auto_awesome,
              color: context.primaryColor,
              size: kIsWeb ? 32 : 26.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  appLocalizations.hudaAI,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Amiri',
                    color: isDark ? context.darkText : context.lightText,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  appLocalizations.islamicAssistant,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? context.darkText.withValues(alpha: 0.7)
                        : context.lightText.withValues(alpha: 0.6),
                    fontFamily: 'Amiri',
                    letterSpacing: 0.3,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(
          height: 1.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                context.primaryColor.withValues(alpha: 0.1),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kIsWeb ? 65.h : 55.h);
}
