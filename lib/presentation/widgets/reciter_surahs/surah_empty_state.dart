import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';

class SurahEmptyState extends StatelessWidget {
  final ThemeData theme;
  final AppLocalizations l10n;

  const SurahEmptyState({
    super.key,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 52.sp,
              color: theme.colorScheme.outline,
            ),
            SizedBox(height: 12.h),
            Text(
              l10n.noResultsFound,
              style: TextStyle(
                fontSize: 16.sp,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
