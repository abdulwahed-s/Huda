import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/books/pagination_button.dart';

class PaginationButtons extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isDark;
  final ValueChanged<int> onPageChanged;

  const PaginationButtons({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.isDark,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // First and Previous buttons group
        Row(
          children: [
            PaginationButton(
              context: context,
              label: AppLocalizations.of(context)!.first,
              icon: Icons.keyboard_double_arrow_left_rounded,
              isEnabled: currentPage > 1,
              onPressed: () => onPageChanged(1),
              isDark: isDark,
              isCompact: currentPage > 3,
            ),
            SizedBox(width: 8.w),
            PaginationButton(
              context: context,
              label: AppLocalizations.of(context)!.prev,
              icon: Icons.chevron_left_rounded,
              isEnabled: currentPage > 1,
              onPressed: () => onPageChanged(currentPage - 1),
              isDark: isDark,
            ),
          ],
        ),
        SizedBox(width: 16.w),
        // Next and Last buttons group
        Row(
          children: [
            PaginationButton(
              context: context,
              label: AppLocalizations.of(context)!.next,
              icon: Icons.chevron_right_rounded,
              isEnabled: currentPage < totalPages,
              onPressed: () => onPageChanged(currentPage + 1),
              isDark: isDark,
            ),
            SizedBox(width: 8.w),
            PaginationButton(
              context: context,
              label: AppLocalizations.of(context)!.last,
              icon: Icons.keyboard_double_arrow_right_rounded,
              isEnabled: currentPage < totalPages,
              onPressed: () => onPageChanged(totalPages),
              isDark: isDark,
              isCompact: totalPages - currentPage > 2,
            ),
          ],
        ),
      ],
    );
  }
}