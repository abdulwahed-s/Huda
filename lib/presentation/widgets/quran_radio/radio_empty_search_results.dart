import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RadioEmptySearchResults extends StatelessWidget {
  final String message;

  const RadioEmptySearchResults({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 56.sp, color: theme.colorScheme.outline),
          SizedBox(height: 12.h),
          Text(
            message,
            style: TextStyle(
                fontSize: 15.sp, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
