import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/khatma/khatma_card.dart';
import 'package:huda/presentation/widgets/khatma/khatma_section_label.dart';

class KhatmaReminderSection extends StatelessWidget {
  final bool reminderEnabled;
  final String formattedTime;
  final TextDirection textDirection;
  final Widget? notificationRequirements;
  final ValueChanged<bool> onToggleReminder;
  final VoidCallback onPickTime;

  const KhatmaReminderSection({
    super.key,
    required this.reminderEnabled,
    required this.formattedTime,
    required this.textDirection,
    this.notificationRequirements,
    required this.onToggleReminder,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.primaryColor;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KhatmaSectionLabel(text: l10n.khatmaDailyReminderSection),
        if (notificationRequirements != null) ...[
          SizedBox(height: 8.h),
          notificationRequirements!,
        ],
        KhatmaCard(
          child: ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            leading: Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child:
                  Icon(Icons.notifications_rounded, color: accent, size: 20.sp),
            ),
            title: Text(
              l10n.khatmaDailyWirdTitle,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.sp),
            ),
            subtitle: GestureDetector(
              onTap: onPickTime,
              child: Text(
                formattedTime,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : Colors.black45,
                ),
                textDirection: textDirection,
              ),
            ),
            trailing: Switch(
              value: reminderEnabled,
              onChanged: onToggleReminder,
              activeThumbColor: accent,
            ),
          ),
        ),
      ],
    );
  }
}
