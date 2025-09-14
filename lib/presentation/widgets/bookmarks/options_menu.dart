import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';

class OptionsMenu extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onClearAll;

  const OptionsMenu({
    super.key,
    required this.onRefresh,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.refresh),
            title: Text(
              AppLocalizations.of(context)!.refresh,
              style: const TextStyle(fontFamily: 'Amiri'),
            ),
            onTap: onRefresh,
          ),
          ListTile(
            leading: const Icon(Icons.clear_all, color: Colors.red),
            title: Text(
              AppLocalizations.of(context)!.clearAllBookmarks,
              style: const TextStyle(
                color: Colors.red,
                fontFamily: 'Amiri',
              ),
            ),
            onTap: onClearAll,
          ),
        ],
      ),
    );
  }
}

