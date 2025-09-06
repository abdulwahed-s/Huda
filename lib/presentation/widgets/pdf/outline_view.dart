import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:pdfrx/pdfrx.dart';

class OutlineView extends StatelessWidget {
  const OutlineView({
    required this.outline,
    required this.controller,
    super.key,
  });

  final List<PdfOutlineNode>? outline;
  final PdfViewerController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final list = _getOutlineList(outline, 0).toList();

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt_outlined,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noTableOfContents,
              style: TextStyle(
                fontSize: 16.sp,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => controller.goToDest(item.node.dest),
              child: Container(
                padding: EdgeInsets.only(
                  left: item.level * 16.0 + 12,
                  top: 12,
                  bottom: 12,
                  right: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (item.level > 0)
                      Icon(
                        Icons.subdirectory_arrow_right,
                        size: 16,
                        color: colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    if (item.level > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.node.title,
                        style: TextStyle(
                          fontSize: item.level == 0 ? 15.sp : 14.sp,
                          fontWeight: item.level == 0
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: item.level == 0
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Iterable<({PdfOutlineNode node, int level})> _getOutlineList(
      List<PdfOutlineNode>? outline, int level) sync* {
    if (outline == null) return;
    for (var node in outline) {
      yield (node: node, level: level);
      yield* _getOutlineList(node.children, level + 1);
    }
  }
}