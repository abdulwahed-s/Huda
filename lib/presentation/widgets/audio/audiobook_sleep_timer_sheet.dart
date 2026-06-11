import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class AudiobookSleepTimerSheet extends StatelessWidget {
  final AudiobookPlayerCubit cubit;

  const AudiobookSleepTimerSheet({super.key, required this.cubit});

  static const List<int> _minutes = [5, 15, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? context.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            l10n.sleepTimer,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Amiri',
              color: isDark ? context.darkText : context.lightText,
            ),
          ),
          SizedBox(height: 16.h),
          ValueListenableBuilder<Duration?>(
            valueListenable: cubit.sleepRemaining,
            builder: (context, remaining, _) {
              
              final selectedMinutes = cubit.initialSleepDuration?.inMinutes;
              final eocActive = remaining != null && remaining.isNegative;

              return GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10.h,
                crossAxisSpacing: 10.w,
                childAspectRatio: 1.25,
                children: [
                  ..._minutes.map((m) => _buildTimeCard(
                        context,
                        isDark,
                        icon: Icons.timer_rounded,
                        label: l10n.sleepTimerMinutes(m),
                        isActive: selectedMinutes == m,
                        onTap: () {
                          cubit.startSleepTimer(Duration(minutes: m));
                          Navigator.pop(context);
                        },
                      )),
                  _buildTimeCard(
                    context,
                    isDark,
                    icon: Icons.menu_book_rounded,
                    label: l10n.endOfChapter,
                    isActive: eocActive,
                    onTap: () {
                      cubit.startEndOfChapterTimer();
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 12.h),
          Divider(
            height: 1,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          ),
          SizedBox(height: 4.h),
          _buildCancelRow(context, isDark),
        ],
      ),
    );
  }

  Widget _buildTimeCard(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final primaryColor = context.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isActive
              ? primaryColor.withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isActive ? primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 24.sp,
                    color: isActive
                        ? primaryColor
                        : (isDark
                            ? context.darkText.withValues(alpha: 0.65)
                            : context.lightText.withValues(alpha: 0.55)),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive
                          ? primaryColor
                          : (isDark ? context.darkText : context.lightText),
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Positioned(
                top: 6.h,
                right: 6.w,
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 13.sp,
                  color: primaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelRow(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          cubit.cancelSleepTimer();
          Navigator.pop(context);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
          child: Row(
            children: [
              Icon(Icons.timer_off_rounded,
                  size: 22.sp, color: Colors.red.shade400),
              SizedBox(width: 16.w),
              Text(
                l10n.cancel,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
