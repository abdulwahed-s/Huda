import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/classic_feature_card_metrics.dart';
import 'package:huda/presentation/widgets/home/continue_activity_dock.dart';

class _QuranSubItem {
  final String title;
  final String? svgAsset;
  final IconData? icon;
  final VoidCallback onTap;

  const _QuranSubItem({
    required this.title,
    this.svgAsset,
    this.icon,
    required this.onTap,
  });
}

class QuranFeatureStackCard extends StatefulWidget {
  final bool isDarkMode;
  final int index;
  final String stackLabel;
  final String quranLabel;
  final String audioLabel;
  final String radioLabel;
  final String bookmarkLabel;
  final VoidCallback onQuranTap;
  final VoidCallback onAudioTap;
  final VoidCallback onRadioTap;
  final VoidCallback onBookmarkTap;
  final ValueChanged<bool>? onExpandChanged;
  final Function(dynamic)? openLastReciterAudio;
  final Function(dynamic)? openLastRadioStation;

  const QuranFeatureStackCard({
    super.key,
    required this.isDarkMode,
    required this.index,
    required this.stackLabel,
    required this.quranLabel,
    required this.audioLabel,
    required this.radioLabel,
    required this.bookmarkLabel,
    required this.onQuranTap,
    required this.onAudioTap,
    required this.onRadioTap,
    required this.onBookmarkTap,
    this.onExpandChanged,
    this.openLastReciterAudio,
    this.openLastRadioStation,
  });

  @override
  State<QuranFeatureStackCard> createState() => _QuranFeatureStackCardState();
}

class _QuranFeatureStackCardState extends State<QuranFeatureStackCard> {
  bool _expanded = false;

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() => _expanded = !_expanded);
    widget.onExpandChanged?.call(_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 540);
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedScale(
        scale: _expanded ? 0.975 : 1.0,
        duration: duration,
        curve: Curves.easeInOutCubic,
        child: _buildStackLayers(context, child: _buildFrontCard(context)),
      ),
    );
  }

  Widget _buildStackLayers(BuildContext context, {required Widget child}) {
    const rightShifts = [8.0, 5.0, 2.5];
    const bottomShifts = [3.0, 2.0, 1.0];
    const rotations = [0.032, 0.018, 0.008];
    const fanRight = 10.0;
    const fanBottom = 4.0;

    return Stack(
      key: const ValueKey('quran-kit-anchor'),
      clipBehavior: Clip.hardEdge,
      children: [
        for (int i = 0; i < 3; i++)
          Positioned(
            left: 0,
            top: 0,
            right: fanRight - rightShifts[i],
            bottom: fanBottom - bottomShifts[i],
            child: Transform(
              alignment: Alignment.bottomLeft,
              transform: Matrix4.identity()
                ..setTranslationRaw(rightShifts[i], bottomShifts[i], 0)
                ..rotateZ(rotations[i]),
              child: _buildCardShell(context, layerIndex: i),
            ),
          ),
        Positioned(
          left: 0,
          top: 0,
          right: fanRight,
          bottom: fanBottom,
          child: child,
        ),
      ],
    );
  }

  Widget _buildCardShell(BuildContext context, {int layerIndex = -1}) {
    final primary = context.primaryColor;

    final isBackCard = layerIndex >= 0;
    final List<Color> gradientColors;
    final double borderAlpha;

    if (!isBackCard) {
      gradientColors = widget.isDarkMode
          ? [const Color(0xFF2B2F3A), const Color(0xFF1E2230)]
          : [const Color(0xFFFFFFFF), const Color(0xFFF8FAFF)];
      borderAlpha = 0.12;
    } else {
      final fillAlpha = widget.isDarkMode
          ? 0.30 - layerIndex * 0.06
          : 0.22 - layerIndex * 0.05;
      final baseColor = widget.isDarkMode
          ? const Color(0xFF1E2230)
          : const Color(0xFFF8FAFF);
      gradientColors = [
        Color.lerp(baseColor, primary, fillAlpha + 0.04)!,
        Color.lerp(baseColor, primary, fillAlpha)!,
      ];
      borderAlpha = 0.35 - layerIndex * 0.06;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(
          color: primary.withValues(alpha: borderAlpha),
          width: isBackCard ? 1.2 : 1,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isBackCard ? 0.10 : 0.08),
            blurRadius: isBackCard ? 6 : 8,
            offset: const Offset(2, 3),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontCard(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 540);
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isDarkMode
              ? [const Color(0xFF2B2F3A), const Color(0xFF1E2230)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF8FAFF)],
        ),
        border: Border.all(
          color: _expanded
              ? context.primaryColor.withValues(alpha: 0.35)
              : (widget.isDarkMode ? Colors.white : Colors.black).withValues(
                  alpha: 0.06,
                ),
          width: _expanded ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: _expanded
                ? context.primaryColor.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: _expanded ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: _toggle,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final metrics = ClassicFeatureCardMetrics.resolve(constraints);
              return Padding(
                padding: EdgeInsets.all(metrics.outerPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      flex: 0,
                      child: Container(
                        padding: EdgeInsets.all(metrics.iconPadding),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: context.primaryColor.withValues(alpha: 0.12),
                          ),
                        ),
                        child: SvgPicture(
                          const AssetBytesLoader(
                            'assets/images/qurancard.svg.vec',
                          ),
                          width: metrics.iconSize,
                          height: metrics.iconSize,
                          colorFilter: ColorFilter.mode(
                            widget.isDarkMode
                                ? context.primaryLightColor
                                : context.primaryColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: metrics.contentGap),
                    Flexible(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              child: Text(
                                widget.stackLabel,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: metrics.fontSize,
                                  fontWeight: FontWeight.w600,
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black.withValues(alpha: 0.85),
                                  height: 1.2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class QuranExpandedSubGrid extends StatefulWidget {
  final Animation<double>? revealAnimation;
  final GlobalKey? revealAnchorKey;
  final bool isDarkMode;
  final String quranLabel, audioLabel, radioLabel, bookmarkLabel;
  final VoidCallback onQuranTap, onAudioTap, onRadioTap, onBookmarkTap;
  final Function(Map<String, dynamic>)? openLastReadSurah;
  final Function(dynamic)? openLastReciterAudio;
  final Function(dynamic)? openLastRadioStation;
  final bool showReadingContinuation;

  const QuranExpandedSubGrid({
    super.key,
    this.revealAnimation,
    this.revealAnchorKey,
    required this.isDarkMode,
    required this.quranLabel,
    required this.audioLabel,
    required this.radioLabel,
    required this.bookmarkLabel,
    required this.onQuranTap,
    required this.onAudioTap,
    required this.onRadioTap,
    required this.onBookmarkTap,
    this.openLastReadSurah,
    this.openLastReciterAudio,
    this.openLastRadioStation,
    this.showReadingContinuation = true,
  });

  @override
  State<QuranExpandedSubGrid> createState() => _QuranExpandedSubGridState();
}

class _QuranExpandedSubGridState extends State<QuranExpandedSubGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Animation<double> get _motion => widget.revealAnimation ?? _controller;

  List<_QuranSubItem> get _items => [
    _QuranSubItem(
      title: widget.quranLabel,
      svgAsset: 'assets/images/quranicon.svg.vec',
      onTap: widget.onQuranTap,
    ),
    _QuranSubItem(
      title: widget.audioLabel,
      icon: Icons.headphones,
      onTap: widget.onAudioTap,
    ),
    _QuranSubItem(
      title: widget.radioLabel,
      icon: Icons.radio,
      onTap: widget.onRadioTap,
    ),
    _QuranSubItem(
      title: widget.bookmarkLabel,
      icon: Icons.bookmark,
      onTap: widget.onBookmarkTap,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 540),
    );
    if (widget.revealAnimation == null) _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.revealAnimation == null &&
        MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final l10n = AppLocalizations.of(context)!;

    if (widget.revealAnchorKey != null) {
      return _buildLayout(context, items, l10n);
    }
    return AnimatedBuilder(
      animation: _motion,
      builder: (context, _) => _buildLayout(context, items, l10n),
    );
  }

  Widget _buildLayout(
    BuildContext context,
    List<_QuranSubItem> items,
    AppLocalizations l10n,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final useFourColumns = constraints.maxWidth >= 650 && textScale <= 1.4;
        final activity = _buildContinueRow(l10n);
        final tools = _buildToolGrid(
          items,
          columns: useFourColumns ? 4 : 2,
          textScale: textScale,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            activity,
            SizedBox(height: 16.h),
            tools,
          ],
        );
      },
    );
  }

  Widget _buildToolGrid(
    List<_QuranSubItem> items, {
    required int columns,
    required double textScale,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      primary: false,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        mainAxisExtent: textScale > 1.45 ? 164 : 142,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) =>
          _animCard(context, items[index], index + 1),
    );
  }

  Widget _buildContinueRow(AppLocalizations l10n) {
    return _animatedItem(
      0,
      BlocBuilder<HomeCubit, HomeState>(
        builder: (context, homeState) {
          final loaded = homeState is HomeLoaded ? homeState : null;
          final summary = loaded?.lastReadSummary;
          final audio = loaded?.lastQuranAudio;
          final station = loaded?.lastRadioStation;
          final hasReading =
              widget.showReadingContinuation &&
              loaded?.hasLastReadPosition == true &&
              summary != null;
          final hasListening =
              loaded?.hasLastQuranAudio == true && audio != null;
          final hasRadio =
              loaded?.hasLastRadioStation == true && station != null;
          final hasAnyActivity = hasReading || hasListening || hasRadio;

          return ContinueActivityDock(
            title: hasAnyActivity
                ? l10n.continueActivityPrompt
                : l10n.noRecentActivityHome,
            isDarkMode: widget.isDarkMode,
            items: [
              if (widget.showReadingContinuation)
                ContinueActivityDockItem(
                  label: l10n.continueHome,
                  icon: Icons.menu_book_rounded,
                  hasActivity: hasReading,
                  semanticHint: hasReading
                      ? l10n.resumeReading
                      : l10n.noRecentActivityDescription,
                  unavailableLabel: l10n.noProgress,
                  onTap: hasReading && widget.openLastReadSurah != null
                      ? () => widget.openLastReadSurah!(summary)
                      : null,
                ),
              ContinueActivityDockItem(
                label: l10n.continueListening,
                icon: Icons.headphones_rounded,
                hasActivity: hasListening,
                semanticHint: hasListening
                    ? l10n.resumeReciter(audio.reciterName)
                    : l10n.noReciterActivityDescription,
                unavailableLabel: l10n.noProgress,
                onTap: hasListening && widget.openLastReciterAudio != null
                    ? () => widget.openLastReciterAudio!(audio)
                    : null,
              ),
              ContinueActivityDockItem(
                label: l10n.continueRadio,
                icon: Icons.radio_rounded,
                hasActivity: hasRadio,
                semanticHint: hasRadio
                    ? station.stationName
                    : l10n.noRadioActivityDescription,
                unavailableLabel: l10n.noProgress,
                onTap: hasRadio && widget.openLastRadioStation != null
                    ? () => widget.openLastRadioStation!(station)
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _animCard(BuildContext ctx, _QuranSubItem item, int i) {
    return _animatedItem(i, _card(ctx, item));
  }

  Widget _animatedItem(int index, Widget child) {
    final start = 0.025 + index * 0.035;
    if (widget.revealAnchorKey != null) {
      return _QuranAnchoredReveal(
        anchorKey: widget.revealAnchorKey!,
        animation: _motion,
        start: start,
        depth: index,
        child: child,
      );
    }

    final localProgress = ((_motion.value - start) / (1 - start)).clamp(
      0.0,
      1.0,
    );
    final progress = Curves.easeOutCubic.transform(localProgress);
    return Transform.translate(
      offset: Offset(0, (1 - progress) * 10.h),
      child: Transform.scale(
        scale: 0.965 + progress * 0.035,
        child: Opacity(opacity: progress, child: child),
      ),
    );
  }

  BoxDecoration _deco(BuildContext context) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: widget.isDarkMode
          ? [const Color(0xFF2B2F3A), const Color(0xFF1E2230)]
          : [const Color(0xFFFFFFFF), const Color(0xFFF8FAFF)],
    ),
    border: Border.all(
      color: (widget.isDarkMode ? Colors.white : Colors.black).withValues(
        alpha: 0.06,
      ),
    ),
    borderRadius: BorderRadius.circular(16.r),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Widget _card(BuildContext context, _QuranSubItem item) {
    return Container(
      decoration: _deco(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            HapticFeedback.selectionClick();
            item.onTap();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final metrics = ClassicFeatureCardMetrics.resolve(constraints);
              return Padding(
                padding: EdgeInsets.all(metrics.outerPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(metrics.iconPadding),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: context.primaryColor.withValues(alpha: 0.12),
                        ),
                      ),
                      child: item.svgAsset != null
                          ? SvgPicture(
                              AssetBytesLoader(item.svgAsset!),
                              width: metrics.iconSize,
                              height: metrics.iconSize,
                              colorFilter: ColorFilter.mode(
                                widget.isDarkMode
                                    ? context.primaryLightColor
                                    : context.primaryColor,
                                BlendMode.srcIn,
                              ),
                            )
                          : Icon(
                              item.icon,
                              size: metrics.iconSize,
                              color: widget.isDarkMode
                                  ? context.primaryLightColor
                                  : context.primaryColor,
                            ),
                    ),
                    SizedBox(height: metrics.contentGap),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: metrics.fontSize,
                        fontWeight: FontWeight.w600,
                        color: widget.isDarkMode
                            ? Colors.white
                            : Colors.black.withValues(alpha: 0.85),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QuranAnchoredReveal extends StatefulWidget {
  const _QuranAnchoredReveal({
    required this.anchorKey,
    required this.animation,
    required this.start,
    required this.depth,
    required this.child,
  });

  final GlobalKey anchorKey;
  final Animation<double> animation;
  final double start;
  final int depth;
  final Widget child;

  @override
  State<_QuranAnchoredReveal> createState() => _QuranAnchoredRevealState();
}

class _QuranAnchoredRevealState extends State<_QuranAnchoredReveal> {
  final GlobalKey _destinationKey = GlobalKey();

  Offset _originOffset = Offset.zero;
  double _originScale = 0.9;
  bool _hasGeometry = false;
  bool _measurementScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleMeasurement();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleMeasurement();
  }

  @override
  void didUpdateWidget(covariant _QuranAnchoredReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.anchorKey != widget.anchorKey) {
      _hasGeometry = false;
      _scheduleMeasurement();
    }
  }

  void _scheduleMeasurement() {
    if (_measurementScheduled) return;
    _measurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementScheduled = false;
      if (!mounted) return;

      final anchor = widget.anchorKey.currentContext?.findRenderObject();
      final destination = _destinationKey.currentContext?.findRenderObject();
      if (anchor is! RenderBox ||
          destination is! RenderBox ||
          !anchor.hasSize ||
          !destination.hasSize) {
        _scheduleMeasurement();
        return;
      }

      final anchorCenter = anchor.localToGlobal(
        anchor.size.center(Offset.zero),
      );
      final destinationCenter = destination.localToGlobal(
        destination.size.center(Offset.zero),
      );
      final nextOffset = anchorCenter - destinationCenter;
      final nextScale = math
          .min(
            anchor.size.width / destination.size.width,
            anchor.size.height / destination.size.height,
          )
          .clamp(0.18, 0.92)
          .toDouble();

      if (_hasGeometry &&
          (nextOffset - _originOffset).distance < 0.5 &&
          (nextScale - _originScale).abs() < 0.005) {
        return;
      }
      setState(() {
        _originOffset = nextOffset;
        _originScale = nextScale;
        _hasGeometry = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleMeasurement();
    return SizedBox(
      key: _destinationKey,
      child: AnimatedBuilder(
        animation: widget.animation,
        child: widget.child,
        builder: (context, child) {
          final local =
              ((widget.animation.value - widget.start) / (1 - widget.start))
                  .clamp(0.0, 1.0);
          final progress = Curves.easeOutCubic.transform(local);
          final opacity = _hasGeometry
              ? Curves.easeOut.transform((local / 0.34).clamp(0.0, 1.0))
              : 0.0;
          final direction = Directionality.of(context) == TextDirection.ltr
              ? 1.0
              : -1.0;
          final depth = (widget.depth.clamp(0, 3) + 1).toDouble();
          final rotation = (1 - progress) * direction * depth * 0.008;

          return Transform.translate(
            offset: _originOffset * (1 - progress),
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: lerpDouble(_originScale, 1, progress)!,
                child: Opacity(
                  opacity: opacity,
                  child: SizedBox(
                    key: ValueKey('quran-kit-reveal-${widget.depth}'),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
