import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/theme/theme_extension.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;
  final AppLocalizations appLocalizations;
  final VoidCallback onHistory;
  final VoidCallback onNewChat;

  const ChatAppBar({
    super.key,
    required this.isDark,
    required this.appLocalizations,
    required this.onHistory,
    required this.onNewChat,
  });

  @override
  Widget build(BuildContext context) {
    final showNewChatLabel = MediaQuery.sizeOf(context).width >= 700;

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
                    letterSpacing: 0.3,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _AppBarAction(
          tooltip: appLocalizations.aiHistory,
          onPressed: onHistory,
          icon: Icons.history_rounded,
          isDark: isDark,
        ),
        SizedBox(width: 8.w),
        _AppBarAction(
          tooltip: appLocalizations.newChat,
          label: showNewChatLabel ? appLocalizations.newChat : null,
          onPressed: onNewChat,
          icon: Icons.add_rounded,
          isDark: isDark,
          isPrimary: true,
        ),
        SizedBox(width: 12.w),
      ],
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

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    required this.isDark,
    this.label,
    this.isPrimary = false,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final bool isDark;
  final String? label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isPrimary
        ? Colors.white
        : (isDark ? context.darkText : context.lightText);
    final backgroundColor = isPrimary
        ? context.primaryColor
        : context.primaryColor.withValues(alpha: isDark ? 0.16 : 0.07);
    final borderColor = isPrimary
        ? context.primaryColor
        : context.primaryColor.withValues(alpha: isDark ? 0.28 : 0.14);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13.r),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: label == null ? 10.w : 14.w,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 21.sp, color: foregroundColor),
                  if (label != null) ...[
                    SizedBox(width: 7.w),
                    Text(
                      label!,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
