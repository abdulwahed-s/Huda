import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/data/models/reciter_model.dart';
import 'package:huda/presentation/widgets/reciter_surahs/reciter_header_background.dart';

class ReciterSliverAppBar extends StatelessWidget {
  final Reciter reciter;
  final Moshaf moshaf;
  final int surahCount;
  final ThemeData theme;
  final bool isCollapsed;

  const ReciterSliverAppBar({
    super.key,
    required this.reciter,
    required this.moshaf,
    required this.surahCount,
    required this.theme,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 190.h,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      title: isCollapsed
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reciter.name.toString(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  moshaf.name.toString(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [StretchMode.zoomBackground],
        background: ReciterHeaderBackground(
          reciter: reciter,
          moshaf: moshaf,
          surahCount: surahCount,
          theme: theme,
        ),
      ),
    );
  }
}
