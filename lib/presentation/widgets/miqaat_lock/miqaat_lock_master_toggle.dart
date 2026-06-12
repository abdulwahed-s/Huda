import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';

import 'miqaat_lock_shared_components.dart';

class MasterToggleSection extends StatelessWidget {
  final bool isEnabled;
  final bool isLocked;
  final ValueChanged<bool> onToggle;

  const MasterToggleSection({
    super.key,
    required this.isEnabled,
    required this.isLocked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final activeColor = const Color(0xFF00C9A7);

    return SharedCard(
      theme: theme,
      isDark: isDark,
      accentColor: isEnabled ? activeColor : null,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: isEnabled
                    ? activeColor.withValues(alpha: 0.15)
                    : theme.hintColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  isEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                  key: ValueKey(isEnabled),
                  color: isEnabled ? activeColor : theme.hintColor,
                  size: 28.sp,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.enableMiqaatLock,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isEnabled ? activeColor : theme.hintColor,
                      fontWeight:
                          isEnabled ? FontWeight.w600 : FontWeight.normal,
                    ),
                    child: Text(
                      isEnabled ? l10n.active : l10n.miqaatLockDescription,
                      style: const TextStyle(),
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 1.1,
              child: Switch.adaptive(
                value: isEnabled,
                onChanged: isLocked ? null : onToggle,
                activeTrackColor: activeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
