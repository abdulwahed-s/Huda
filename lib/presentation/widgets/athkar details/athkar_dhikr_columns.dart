import 'package:flutter/material.dart';
import 'package:huda/core/layout/fold.dart';

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
