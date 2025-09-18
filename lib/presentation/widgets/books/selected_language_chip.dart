import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class SelectedLanguageChip extends StatelessWidget {
  final String language;
  final VoidCallback onClear;

  const SelectedLanguageChip({
    super.key,
    required this.language,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Chip(
              label: Text(
                '${AppLocalizations.of(context)!.filtered}: ${language.toUpperCase()}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12.sp,
                ),
              ),
              backgroundColor: context.primaryColor,
              deleteIcon: const Icon(Icons.close, color: Colors.white, size: 18),
              onDeleted: onClear,
            ),
          ],
        ),
      ),
    );
  }
}