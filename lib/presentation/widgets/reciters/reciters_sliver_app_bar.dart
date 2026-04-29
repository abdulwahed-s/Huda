import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/reciters/reciters_header_background.dart';

class RecitersSliverAppBar extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  final bool isCollapsed;
  final int reciterCount;

  const RecitersSliverAppBar({
    super.key,
    required this.l10n,
    required this.theme,
    required this.isCollapsed,
    required this.reciterCount,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160.h,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      title: isCollapsed
          ? Text(
              l10n.quranAudio,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimary,
              ),
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [StretchMode.zoomBackground],
        background: RecitersHeaderBackground(
          theme: theme,
          l10n: l10n,
          reciterCount: reciterCount,
        ),
      ),
    );
  }
}
