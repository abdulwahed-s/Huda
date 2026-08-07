import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/pdf/huda_pdf_search_controller.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    required this.match,
    required this.onTap,
    required this.height,
    required this.isCurrent,
    super.key,
  });

  final HudaPdfSearchHit match;
  final VoidCallback onTap;
  final double height;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontSize: 13.sp,
      color: colorScheme.onSurface,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrent
            ? colorScheme.primary.withValues(alpha: 0.5)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.2),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            height: height,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: match.before, style: style),
                  TextSpan(
                    text: match.match,
                    style: style.copyWith(
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: match.after, style: style),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
