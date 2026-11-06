import 'package:flutter/material.dart';
import 'package:huda/core/layout/fold.dart';

/// A chapter's dhikr in rows of [columns], each row on one top line, so
/// the order on screen is the chapter's order: across from the reading
/// side, then down (owner round 2: a masonry broke the sequence). A row is
/// as tall as its tallest card.
///
/// Two columns split exactly at a vertical fold (flat or half open, so
/// nothing moves when the device bends), the gap on the crease. Assumes
/// it's centered in the window, as the reader's page is.
class AthkarDhikrColumns extends StatelessWidget {
  const AthkarDhikrColumns({
    super.key,
    required this.columns,
    required this.spacing,
    required this.children,
  });

  final int columns;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final fold = FoldInfo.of(context);
    final window = MediaQuery.sizeOf(context).width;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Column widths from left to right.
        final widths = <double>[];
        final gaps = <double>[];
        final offset = (window - width) / 2;
        final start = fold.start - offset;
        final end = fold.end - offset;
        if (columns == 2 &&
            fold.splitsHorizontally &&
            start > spacing &&
            end < width - spacing) {
          final left = start - spacing / 2;
          final right = width - end - spacing / 2;
          widths.addAll([left, right]);
          gaps.add(width - left - right);
        } else {
          final each = (width - spacing * (columns - 1)) / columns;
          widths.addAll(List.filled(columns, each));
          gaps.addAll(List.filled(columns - 1, spacing));
        }
        // Cells laid out left to right; in RTL the first is on the right.
        final rows = (children.length / columns).ceil();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var r = 0; r < rows; r++) ...[
              if (r > 0) SizedBox(height: spacing),
              Row(
                textDirection: TextDirection.ltr,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var slot = 0; slot < columns; slot++) ...[
                    if (slot > 0) SizedBox(width: gaps[slot - 1]),
                    SizedBox(
                      width: widths[slot],
                      child: () {
                        final i =
                            r * columns + (rtl ? columns - 1 - slot : slot);
                        return i < children.length
                            ? children[i]
                            : const SizedBox.shrink();
                      }(),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
