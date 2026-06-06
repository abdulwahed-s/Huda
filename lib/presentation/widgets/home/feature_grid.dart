import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/utils/responsive_utils.dart';
import 'package:huda/presentation/widgets/home/quran_feature_stack_card.dart';
import 'feature_card.dart';

class FeatureGrid extends StatefulWidget {
  final bool isDarkMode;
  final List<FeatureItem> features;
  final QuranFeatureStackCard? quranStackCard;
  final Function(Map<String, dynamic>)? openLastReadSurah;

  const FeatureGrid({
    super.key,
    required this.isDarkMode,
    required this.features,
    this.quranStackCard,
    this.openLastReadSurah,
  });

  @override
  State<FeatureGrid> createState() => _FeatureGridState();
}

class _FeatureGridState extends State<FeatureGrid> {
  bool _quranExpanded = false;
  final _quranStackKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = context.responsive(mobile: 3, tablet: 4, desktop: 6);
    final textScaleFactor = MediaQuery.of(context).textScaler.scale(1.0);
    final adjustedAspectRatio =
        (0.65 / (textScaleFactor * 0.8)).clamp(0.45, 0.75);

    final List<Widget> featureCards = [];
    for (int i = 0; i < widget.features.length; i++) {
      final feature = widget.features[i];
      featureCards.add(
        FeatureCard(
          title: feature.title,
          svgAsset: feature.svgAsset,
          icon: feature.icon,
          onTap: () => feature.onTap(),
          isDarkMode: widget.isDarkMode,
          index: i + (widget.quranStackCard != null ? 1 : 0),
        ),
      );
    }

    final availableWidth = MediaQuery.sizeOf(context).width - 40.w;
    final totalSpacing = 16.w * (crossAxisCount - 1);
    final cellWidth = (availableWidth - totalSpacing) / crossAxisCount;
    final cellHeight = cellWidth / adjustedAspectRatio;

    final List<Widget> columnChildren = [];

    if (widget.quranStackCard != null) {
      final src = widget.quranStackCard!;

      final firstRowFeatureCount = crossAxisCount - 1;
      final firstRowItems = <Widget>[
        SizedBox(
          width: cellWidth,
          height: cellHeight,
          child: QuranFeatureStackCard(
            key: _quranStackKey,
            isDarkMode: src.isDarkMode,
            index: src.index,
            stackLabel: src.stackLabel,
            quranLabel: src.quranLabel,
            audioLabel: src.audioLabel,
            radioLabel: src.radioLabel,
            bookmarkLabel: src.bookmarkLabel,
            onQuranTap: src.onQuranTap,
            onAudioTap: src.onAudioTap,
            onRadioTap: src.onRadioTap,
            onBookmarkTap: src.onBookmarkTap,
            onExpandChanged: (expanded) =>
                setState(() => _quranExpanded = expanded),
          ),
        ),
      ];

      for (int i = 0;
          i < firstRowFeatureCount && i < featureCards.length;
          i++) {
        firstRowItems.add(SizedBox(
            width: cellWidth, height: cellHeight, child: featureCards[i]));
      }

      columnChildren.add(_buildNormalRow(
          firstRowItems, crossAxisCount, cellWidth, cellHeight));

      columnChildren.add(
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          child: _quranExpanded
              ? Padding(
                  padding: EdgeInsets.only(top: 16.h),
                  child: QuranExpandedSubGrid(
                    isDarkMode: widget.isDarkMode,
                    quranLabel: src.quranLabel,
                    audioLabel: src.audioLabel,
                    radioLabel: src.radioLabel,
                    bookmarkLabel: src.bookmarkLabel,
                    onQuranTap: src.onQuranTap,
                    onAudioTap: src.onAudioTap,
                    onRadioTap: src.onRadioTap,
                    onBookmarkTap: src.onBookmarkTap,
                    openLastReadSurah: widget.openLastReadSurah,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      );

      final remaining = featureCards.skip(firstRowFeatureCount).toList();
      _addNormalRows(
          columnChildren, remaining, crossAxisCount, cellWidth, cellHeight);
    } else {
      _addNormalRows(
          columnChildren, featureCards, crossAxisCount, cellWidth, cellHeight);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: columnChildren,
    );
  }

  void _addNormalRows(List<Widget> out, List<Widget> items, int cols,
      double cellW, double cellH) {
    for (int i = 0; i < items.length; i += cols) {
      final end = (i + cols).clamp(0, items.length);
      final rowItems = items
          .sublist(i, end)
          .map((w) => SizedBox(width: cellW, height: cellH, child: w))
          .toList();
      out.add(SizedBox(height: 16.h));
      out.add(_buildNormalRow(rowItems, cols, cellW, cellH));
    }
  }

  Widget _buildNormalRow(
      List<Widget> items, int cols, double cellW, double cellH) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: 16.w),
          items[i],
        ],
        for (int i = items.length; i < cols; i++) ...[
          SizedBox(width: 16.w),
          SizedBox(width: cellW, height: cellH),
        ],
      ],
    );
  }
}

class FeatureItem {
  final String title;
  final String? svgAsset;
  final IconData? icon;
  final VoidCallback onTap;

  FeatureItem({
    required this.title,
    this.svgAsset,
    this.icon,
    required this.onTap,
  });
}
