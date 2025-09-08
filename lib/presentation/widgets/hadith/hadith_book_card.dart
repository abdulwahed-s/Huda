import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/hadith/book_icon.dart';
import 'package:huda/presentation/widgets/hadith/forward_button.dart';

class HadithBookCard extends StatelessWidget {
  final dynamic book;
  final bool isDark;
  final VoidCallback onTap;
  final BuildContext context;

  const HadithBookCard({super.key, 
    required this.book,
    required this.isDark,
    required this.onTap,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.0),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            padding: EdgeInsets.all(20.0.w),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.15),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const BookIcon(),
                SizedBox(width: 16.0.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _bookName(book.bookName!),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18.sp,
                          fontFamily: 'Amiri',
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.black87,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 4.0.h),
                      Text(
                        '${AppLocalizations.of(context)!.contains} ${book.hadithsCount} ${AppLocalizations.of(context)!.hadith}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: 'Amiri',
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.grey[600],
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const ForwardButton(),
              ],
            ),
          ),
        ),
      ),
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
}


