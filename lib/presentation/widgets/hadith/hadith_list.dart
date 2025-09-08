import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/hadith/hadith_book_card.dart';
import 'package:huda/presentation/widgets/hadith/header_banner.dart';

class HadithList extends StatelessWidget {
  final dynamic hadithBooks;
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
    return Column(
      children: [
        HeaderBanner(isDark: isDark),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0.w),
            child: ListView.builder(
              itemCount: hadithBooks.books!.length,
              itemBuilder: (context, index) {
                final book = hadithBooks.books![index];
                return HadithBookCard(
                  book: book,
                  isDark: isDark,
                  context: context,
                  onTap: int.parse(book.hadithsCount!) == 0
                      ? _showComingSoonSnackBar
                      : () {
                          Navigator.pushNamed(
                            context,
                            AppRoute.hadithChapters,
                            arguments: {
                              'bookSlug': book.bookSlug!.toString(),
                              'bookName': _bookName(book.bookName!),
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

  String _bookName(String bookName) {
    switch (bookName) {
      case "Sahih Bukhari":
        return AppLocalizations.of(context)!.bukhari;
      case "Sahih Muslim":
        return AppLocalizations.of(context)!.muslim;
      case "Jami' Al-Tirmidhi":
        return AppLocalizations.of(context)!.tirmidhi;
      case "Sunan Abu Dawood":
        return AppLocalizations.of(context)!.dawood;
      case "Sunan Ibn-e-Majah":
        return AppLocalizations.of(context)!.majah;
      case "Sunan An-Nasa`i":
        return AppLocalizations.of(context)!.nasa;
      case "Mishkat Al-Masabih":
        return AppLocalizations.of(context)!.masabih;
      case "Musnad Ahmad":
        return AppLocalizations.of(context)!.ahmad;
      case "Al-Silsila Sahiha":
        return AppLocalizations.of(context)!.sahiha;
      default:
        return bookName;
    }
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
