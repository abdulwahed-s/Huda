import 'package:flutter/material.dart';
import 'package:huda/core/layout/fold.dart';

/// Tabletop (a half-open horizontal fold): nothing may cross the band, so
/// what to look at goes in the top half and the scrolling content in the
/// bottom half, each with its own `MediaQuery` (its size, the insets of its
/// own edges, no display features). See `design/RESPONSIVE.md`, "Tabletop
/// posture". Generalized from Athkar's tabletop (changed in `hadith`).
class TabletopSplit extends StatelessWidget {
  const TabletopSplit({super.key, required this.top, required this.bottom});

  final Widget top;
  final Widget bottom;

  /// Whether the window is in tabletop posture.
  static bool applies(BuildContext context) => FoldInfo.of(context).isTabletop;

  @override
  Widget build(BuildContext context) {
    final fold = FoldInfo.of(context);
    final media = MediaQuery.of(context);
    final width = media.size.width;
    MediaQueryData half(double height, {required bool upper}) => media.copyWith(
      size: Size(width, height),
      padding: upper
          ? media.padding.copyWith(bottom: 0)
          : media.padding.copyWith(top: 0),
      viewPadding: upper
          ? media.viewPadding.copyWith(bottom: 0)
          : media.viewPadding.copyWith(top: 0),
      displayFeatures: const [],
    );
    // A page behind both halves (text styles, ink) and in the band.
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          SizedBox(
            height: fold.start,
            child: MediaQuery(data: half(fold.start, upper: true), child: top),
          ),
          SizedBox(height: fold.end - fold.start),
          Expanded(
            child: MediaQuery(
              data: half(media.size.height - fold.end, upper: false),
              child: bottom,
            ),
          ),
        ],
      ),
    );
  }
}
