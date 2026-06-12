import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:huda/data/models/reciter_model.dart';
import 'package:huda/presentation/widgets/reciters/moshaf_tile.dart';

class ReciterCard extends StatelessWidget {
  final Reciter reciter;
  final List suwar;
  final bool isDark;
  final ThemeData theme;
  final bool isOffline;
  final AnimationController listAnimController;
  final int itemIndex;

  const ReciterCard({
    super.key,
    required this.reciter,
    required this.suwar,
    required this.isDark,
    required this.theme,
    required this.isOffline,
    required this.listAnimController,
    required this.itemIndex,
  });

  @override
  Widget build(BuildContext context) {
    final name = reciter.name.toString();
    final initial = name.isNotEmpty ? name[0] : '?';

    final Animation<double> entranceAnim = itemIndex < 14
        ? CurvedAnimation(
            parent: listAnimController,
            curve: Interval(
              (itemIndex * 0.055).clamp(0.0, 0.7),
              ((itemIndex * 0.055) + 0.3).clamp(0.1, 1.0),
              curve: Curves.easeOutCubic,
            ),
          )
        : const AlwaysStoppedAnimation(1.0);

    return AnimatedBuilder(
      animation: entranceAnim,
      builder: (context, child) => Opacity(
        opacity: entranceAnim.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - entranceAnim.value)),
          child: child,
        ),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : theme.colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46.r,
                    height: 46.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          Color.lerp(theme.colorScheme.primary,
                              theme.colorScheme.secondary, 0.6)!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 3.h),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.library_music_rounded,
                              size: 11.sp,
                              color: theme.colorScheme.outline,
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              '${reciter.moshaf.length}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (reciter.moshaf.isNotEmpty) ...[
                SizedBox(height: 10.h),
                Divider(
                  height: 1,
                  thickness: 1,
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                SizedBox(height: 6.h),
                ...reciter.moshaf.map((moshaf) => MoshafTile(
                      reciter: reciter,
                      moshaf: moshaf,
                      suwar: suwar,
                      isDark: isDark,
                      theme: theme,
                      isOffline: isOffline,
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
