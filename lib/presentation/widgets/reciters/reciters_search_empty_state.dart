import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:huda/l10n/app_localizations.dart';

class RecitersSearchEmptyState extends StatelessWidget {
  const RecitersSearchEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 52.sp, color: theme.colorScheme.outline),
          SizedBox(height: 12.h),
          Text(
            l10n.noResultsFound,
            style: TextStyle(fontSize: 16.sp, color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
