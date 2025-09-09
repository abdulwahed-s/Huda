import 'package:flutter/material.dart';
import 'package:huda/core/theme/theme_extension.dart';

class ChapterNumberIndicator extends StatelessWidget {
  final String chapterNumber;

  const ChapterNumberIndicator({
    super.key,
    required this.chapterNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          chapterNumber,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.primaryColor,
            fontFamily: "Amiri",
          ),
        ),
      ),
    );
  }
}
