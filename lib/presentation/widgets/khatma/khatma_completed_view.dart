import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/khatma/khatma_card.dart';
import 'package:huda/presentation/widgets/khatma/khatma_gradient_button.dart';
import 'package:huda/presentation/widgets/khatma/khatma_icon_list_tile.dart';
import 'package:huda/presentation/widgets/khatma/khatma_reminder_section.dart';
import 'package:huda/presentation/widgets/khatma/khatma_top_title.dart';

class KhatmaCompletedView extends StatelessWidget {
  final TextDirection textDirection;
  final bool reminderEnabled;
  final String formattedReminderTime;
  final VoidCallback onRepeat;
  final VoidCallback onStartNew;
  final VoidCallback onAllWirds;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleReminder;
  final VoidCallback onPickReminderTime;

  const KhatmaCompletedView({
    super.key,
    required this.textDirection,
    required this.reminderEnabled,
    required this.formattedReminderTime,
    required this.onRepeat,
    required this.onStartNew,
    required this.onAllWirds,
    required this.onDelete,
    required this.onToggleReminder,
    required this.onPickReminderTime,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.primaryColor;
    final l10n = AppLocalizations.of(context)!;

    return Directionality(
      textDirection: textDirection,
      child: ListView(
        padding: EdgeInsets.only(
          top: 6.h,
          bottom: 24.h + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          KhatmaTopTitle(
            title: l10n.khatmaLegendKhatma,
            textDirection: textDirection,
          ),
          SizedBox(height: 12.h),
          const _CelebrationCard(),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: KhatmaGradientButton(
              label: l10n.khatmaRepeat,
              icon: Icons.autorenew_rounded,
              onPressed: onRepeat,
              accent: accent,
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
              onPressed: onStartNew,
              icon: Icon(Icons.add_circle_outline_rounded, size: 20.sp),
              label: Text(
                l10n.khatmaStartNew,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.sp),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          KhatmaReminderSection(
            reminderEnabled: reminderEnabled,
            formattedTime: formattedReminderTime,
            textDirection: textDirection,
            onToggleReminder: onToggleReminder,
            onPickTime: onPickReminderTime,
          ),
          SizedBox(height: 12.h),
          KhatmaCard(
            child: Column(
              children: [
                KhatmaIconListTile(
                  icon: Icons.format_list_numbered_rounded,
                  iconColor: Colors.indigo,
                  title: l10n.khatmaAllWirds,
                  subtitle: l10n.khatmaViewAllWirds,
                  textDirection: textDirection,
                  onTap: onAllWirds,
                ),
                Divider(height: 1, indent: 62.w),
                KhatmaIconListTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: Colors.red,
                  title: l10n.khatmaDeleteTitle,
                  subtitle: l10n.khatmaDeleteSubtitle,
                  textDirection: textDirection,
                  titleColor: Colors.red,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationCard extends StatelessWidget {
  const _CelebrationCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const gold = Color(0xFFFFB300);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: gold.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: EdgeInsets.all(22.r),
        child: Column(
          children: [
            Icon(Icons.emoji_events_rounded, size: 52.sp, color: Colors.white),
            SizedBox(height: 10.h),
            Text(
              l10n.khatmaCongrats,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              l10n.khatmaCompletedMsg,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
