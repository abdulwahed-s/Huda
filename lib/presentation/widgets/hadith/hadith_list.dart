import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/data/models/hadith_books_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/hadith/hadith_book_card.dart';
import 'package:huda/presentation/widgets/hadith/header_banner.dart';

class HadithList extends StatelessWidget {
  final HadithBooksModel hadithBooks;
  final bool isDark;
  final BuildContext context;

  const HadithList({
    super.key,
    required this.hadithBooks,
    required this.isDark,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final currentLanguageCode =
        context.read<LocalizationCubit>().state.locale.languageCode;
    int ind = currentLanguageCode == "ar" ? 1 : 0;
    return Column(
      children: [
        HeaderBanner(isDark: isDark),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0.w),
            child: ListView.builder(
              itemCount: hadithBooks.data!.length,
              itemBuilder: (context, index) {
                final book = hadithBooks.data![index];
                return HadithBookCard(
                  book: book,
                  isDark: isDark,
                  context: context,
                  onTap: book.totalAvailableHadith == 0
                      ? _showComingSoonSnackBar
                      : () {
                          Navigator.pushNamed(
                            context,
                            AppRoute.hadithChapters,
                            arguments: {
                              'bookName': book.name!,
                              'fullBookName': book.collection![ind].title!,
                            },
                          );
                        },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showComingSoonSnackBar() {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            color: Colors.white,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.comingSoon,
              style: TextStyle(
                fontSize: 16.sp,
                fontFamily: 'Amiri',
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
      backgroundColor: const Color(0xFF2D3748),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(16.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      elevation: 8,
      action: SnackBarAction(
        label: AppLocalizations.of(context)!.ok,
        textColor: const Color(0xFF63B3ED),
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
      dismissDirection: DismissDirection.horizontal,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
