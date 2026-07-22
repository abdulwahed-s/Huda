import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/home/quran_feature_stack_card.dart';
import 'feature_card.dart';

@immutable
class FeatureGridLayout {
  const FeatureGridLayout({
    required this.availableWidth,
    required this.columnCount,
    required this.horizontalGap,
    required this.verticalGap,
    required this.childAspectRatio,
  });

  factory FeatureGridLayout.resolve(
    BuildContext context,
    double availableWidth,
  ) {
    final fallbackWidth = MediaQuery.sizeOf(context).width;
    final width = availableWidth.isFinite && availableWidth > 0
        ? availableWidth
        : fallbackWidth;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final horizontalGap = 16.w;
    final verticalGap = 16.h;
    final childAspectRatio =
        (0.65 / (textScale * 0.8)).clamp(0.45, 0.75).toDouble();

    var columns = switch (width) {
      > 950 => 6,
      > 600 => 4,
      _ => 3,
    };
    final minimumCardWidth = switch (textScale) {
      >= 1.8 => 128.0,
      >= 1.35 => 96.0,
      _ => 72.0,
    };
    while (columns > 1 &&
        (width - horizontalGap * (columns - 1)) / columns < minimumCardWidth) {
      columns--;
    }

    return FeatureGridLayout(
      availableWidth: width,
      columnCount: columns,
      horizontalGap: horizontalGap,
      verticalGap: verticalGap,
      childAspectRatio: childAspectRatio,
    );
  }

  final double availableWidth;
  final int columnCount;
  final double horizontalGap;
  final double verticalGap;
  final double childAspectRatio;

  double get cardWidth =>
      (availableWidth - horizontalGap * (columnCount - 1)) / columnCount;

  double get cardHeight => cardWidth / childAspectRatio;

  Rect rectForSlot(int slot, TextDirection direction) {
    final row = slot ~/ columnCount;
    final logicalColumn = slot % columnCount;
    final physicalColumn = direction == TextDirection.ltr
        ? logicalColumn
        : columnCount - logicalColumn - 1;
    return Rect.fromLTWH(
      physicalColumn * (cardWidth + horizontalGap),
      row * (cardHeight + verticalGap),
      cardWidth,
      cardHeight,
    );
  }

  double heightForItemCount(int itemCount) {
    if (itemCount <= 0) return 0;
    final rows = (itemCount + columnCount - 1) ~/ columnCount;
    return rows * cardHeight + (rows - 1) * verticalGap;
  }
}

class FeatureGrid extends StatefulWidget {
  final bool isDarkMode;
  final List<FeatureItem> features;
  final QuranFeatureStackCard? quranStackCard;
  final int quranStackIndex;
  final Widget? trailingCard;
  final Function(Map<String, dynamic>)? openLastReadSurah;
  final Function(dynamic)? openLastReciterAudio;
  final Function(dynamic)? openLastRadioStation;

  const FeatureGrid({
    super.key,
    required this.isDarkMode,
    required this.features,
    this.quranStackCard,
    this.quranStackIndex = 0,
    this.trailingCard,
    this.openLastReadSurah,
    this.openLastReciterAudio,
    this.openLastRadioStation,
  });

  @override
  State<FeatureGrid> createState() => _FeatureGridState();
}

class _FeatureGridState extends State<FeatureGrid> {
  bool _quranExpanded = false;
  final _quranStackKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _buildWithLayout(
        context,
        FeatureGridLayout.resolve(context, constraints.maxWidth),
      ),
    );
  }

  Widget _buildWithLayout(
    BuildContext context,
    FeatureGridLayout layout,
  ) {
    final crossAxisCount = layout.columnCount;

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

    int? quranIndex;
    if (widget.quranStackCard != null) {
      final src = widget.quranStackCard!;
      final stack = QuranFeatureStackCard(
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
        openLastReciterAudio: widget.openLastReciterAudio,
        openLastRadioStation: widget.openLastRadioStation,
      );
      quranIndex = widget.quranStackIndex.clamp(0, featureCards.length);
      featureCards.insert(quranIndex, stack);
    }
    if (widget.trailingCard != null) {
      featureCards.add(widget.trailingCard!);
    }

    final rowEnd = quranIndex == null
        ? featureCards.length
        : (((quranIndex ~/ crossAxisCount) + 1) * crossAxisCount)
            .clamp(0, featureCards.length);
    final cardsBeforeExpansion = featureCards.take(rowEnd).toList();
    final cardsAfterExpansion = featureCards.skip(rowEnd).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGrid(
          cardsBeforeExpansion,
          layout,
        ),
        if (widget.quranStackCard != null)
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _quranExpanded
                ? Padding(
                    padding: EdgeInsets.only(top: 16.h),
                    child: QuranExpandedSubGrid(
                      isDarkMode: widget.isDarkMode,
                      quranLabel: widget.quranStackCard!.quranLabel,
                      audioLabel: widget.quranStackCard!.audioLabel,
                      radioLabel: widget.quranStackCard!.radioLabel,
                      bookmarkLabel: widget.quranStackCard!.bookmarkLabel,
                      onQuranTap: widget.quranStackCard!.onQuranTap,
                      onAudioTap: widget.quranStackCard!.onAudioTap,
                      onRadioTap: widget.quranStackCard!.onRadioTap,
                      onBookmarkTap: widget.quranStackCard!.onBookmarkTap,
                      openLastReadSurah: widget.openLastReadSurah,
                      openLastReciterAudio: widget.openLastReciterAudio,
                      openLastRadioStation: widget.openLastRadioStation,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        if (cardsAfterExpansion.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _buildGrid(
            cardsAfterExpansion,
            layout,
          ),
        ],
      ],
    );
  }

  Widget _buildGrid(
    List<Widget> cards,
    FeatureGridLayout layout,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      primary: false,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: layout.columnCount,
        crossAxisSpacing: layout.horizontalGap,
        mainAxisSpacing: layout.verticalGap,
        childAspectRatio: layout.childAspectRatio,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
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
