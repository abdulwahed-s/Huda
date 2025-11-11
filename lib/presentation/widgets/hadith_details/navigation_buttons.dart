import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/hadith_details/hadith_details_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/hadith_details/navigation_button.dart';

class NavigationButtons extends StatelessWidget {
  final int currentPage;
  final int lastPage;
  final bool isDark;
  final String chapterNumber;
  final String bookName;

  const NavigationButtons({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.isDark,
    required this.chapterNumber,
    required this.bookName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: NavigationButton(
            icon: Icons.arrow_back_ios,
            label: AppLocalizations.of(context)!.back,
            isEnabled: currentPage != 1,
            onPressed: () {
              context
                  .read<HadithDetailsCubit>()
                  .fetchHadithDetails(chapterNumber, bookName, currentPage - 1);
            },
            isDark: isDark,
          ),
        ),
        SizedBox(width: 16.0.w),
        Expanded(
          child: NavigationButton(
            icon: Icons.arrow_forward_ios,
            label: AppLocalizations.of(context)!.next,
            isEnabled: currentPage != lastPage,
            onPressed: () {
              context
                  .read<HadithDetailsCubit>()
                  .fetchHadithDetails(chapterNumber, bookName, currentPage + 1);
            },
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}
