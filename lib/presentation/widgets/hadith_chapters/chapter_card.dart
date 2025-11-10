import 'package:flutter/material.dart';
import 'package:huda/data/models/book_chapters_model.dart';
import 'package:huda/presentation/widgets/hadith_chapters/chapter_number_indicator.dart';
import 'package:huda/presentation/widgets/hadith_chapters/forward_arrow_icon.dart';

class ChapterCard extends StatelessWidget {
  final Data chapter;
  final bool isDark;
  final String currentLanguageCode;
  final VoidCallback onTap;

  const ChapterCard({
    super.key,
    required this.chapter,
    required this.isDark,
    required this.currentLanguageCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Ink(
            padding: const EdgeInsets.all(20.0),
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
                ChapterNumberIndicator(
                  chapterNumber: chapter.bookNumber!,
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    currentLanguageCode == "ar"
                        ? chapter.book![1].name!
                        : chapter.book![0].name!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.87)
                          : Colors.black87,
                      fontFamily: "Amiri",
                      height: 1.4,
                    ),
                    textAlign: currentLanguageCode == "ar" ||
                            currentLanguageCode == "ur"
                        ? TextAlign.right
                        : TextAlign.left,
                  ),
                ),
                ForwardArrowIcon(isDark: isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
