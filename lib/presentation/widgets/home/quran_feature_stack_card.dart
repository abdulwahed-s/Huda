import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/core/utils/responsive_utils.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/continue_reading_card.dart';

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
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedScale(
        scale: _expanded ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: _buildStackLayers(
          context,
          child: _buildFrontCard(context),
        ),
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
      final baseColor =
          widget.isDarkMode ? const Color(0xFF1E2230) : const Color(0xFFF8FAFF);
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
    final iconSize =
        context.responsive(mobile: 32.sp, tablet: 50.sp, desktop: 64.sp);
    final paddingSize =
        context.responsive(mobile: 12.w, tablet: 20.w, desktop: 24.w);
    final fontSize =
        context.responsive(mobile: 12.sp, tablet: 16.sp, desktop: 20.sp);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
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
              : (widget.isDarkMode ? Colors.white : Colors.black)
                  .withValues(alpha: 0.06),
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
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  flex: 0,
                  child: Container(
                    padding: EdgeInsets.all(paddingSize),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: context.primaryColor.withValues(alpha: 0.12),
                      ),
                    ),
                    child: SvgPicture(
                      const AssetBytesLoader('assets/images/qurancard.svg.vec'),
                      width: iconSize,
                      height: iconSize,
                      colorFilter: ColorFilter.mode(
                        widget.isDarkMode
                            ? context.primaryLightColor
                            : context.primaryColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Flexible(
                  child: AutoSizeText(
                    widget.stackLabel,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    minFontSize: 8,
                    maxFontSize: 24,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: widget.isDarkMode
                          ? Colors.white
                          : Colors.black.withValues(alpha: 0.85),
                      fontFamily: "Amiri",
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuranExpandedSubGrid extends StatefulWidget {
  final bool isDarkMode;
  final String quranLabel, audioLabel, radioLabel, bookmarkLabel;
  final VoidCallback onQuranTap, onAudioTap, onRadioTap, onBookmarkTap;
  final Function(Map<String, dynamic>)? openLastReadSurah;

  const QuranExpandedSubGrid({
    super.key,
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
  });

  @override
  State<QuranExpandedSubGrid> createState() => _QuranExpandedSubGridState();
}

class _QuranExpandedSubGridState extends State<QuranExpandedSubGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _scaleAnims;
  late final List<Animation<double>> _opacityAnims;

  List<_QuranSubItem> get _items => [
        _QuranSubItem(
            title: widget.quranLabel,
            svgAsset: 'assets/images/quranicon.svg.vec',
            onTap: widget.onQuranTap),
        _QuranSubItem(
            title: widget.audioLabel,
            icon: Icons.headphones,
            onTap: widget.onAudioTap),
        _QuranSubItem(
            title: widget.radioLabel,
            icon: Icons.radio,
            onTap: widget.onRadioTap),
        _QuranSubItem(
            title: widget.bookmarkLabel,
            icon: Icons.bookmark,
            onTap: widget.onBookmarkTap),
      ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _scaleAnims = [];
    _opacityAnims = [];
    for (int i = 0; i < 5; i++) {
      final s = (i * 50 / 550).clamp(0.0, 1.0);
      _scaleAnims.add(Tween(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve: Interval(s, 1.0, curve: Curves.easeOutBack)),
      ));
      _opacityAnims.add(Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve:
                Interval(s, (s + 0.5).clamp(0.0, 1.0), curve: Curves.easeOut)),
      ));
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final iconSize =
        context.responsive(mobile: 32.sp, tablet: 50.sp, desktop: 64.sp);
    final pad = context.responsive(mobile: 12.w, tablet: 20.w, desktop: 24.w);
    final fs = context.responsive(mobile: 12.sp, tablet: 16.sp, desktop: 20.sp);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: _scaleAnims[0].value,
            child: Opacity(
              opacity: _opacityAnims[0].value.clamp(0.0, 1.0),
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, homeState) {
                  final HomeLoaded? loaded =
                      homeState is HomeLoaded ? homeState : null;
                  final bool hasLastRead =
                      loaded?.hasLastReadPosition ?? false;
                  final VoidCallback? onTap =
                      hasLastRead && widget.openLastReadSurah != null
                          ? () => widget
                              .openLastReadSurah!(loaded!.lastReadSummary!)
                          : null;

                  return ContinueReadingCard(
                    hasLastRead: hasLastRead,
                    onTap: onTap,
                    continueText:
                        AppLocalizations.of(context)!.continueHome,
                    noActivityText:
                        AppLocalizations.of(context)!.noRecentActivityHome,
                    resumeText:
                        AppLocalizations.of(context)!.resumeReading,
                    noActivityDescription: AppLocalizations.of(context)!
                        .noRecentActivityDescription,
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(children: [
            Expanded(child: _animCard(context, items[0], 1, iconSize, pad, fs)),
            SizedBox(width: 16.w),
            Expanded(child: _animCard(context, items[1], 2, iconSize, pad, fs)),
          ]),
          SizedBox(height: 16.h),
          Row(children: [
            Expanded(child: _animCard(context, items[2], 3, iconSize, pad, fs)),
            SizedBox(width: 16.w),
            Expanded(child: _animCard(context, items[3], 4, iconSize, pad, fs)),
          ]),
        ],
      ),
    );
  }

  Widget _animCard(BuildContext ctx, _QuranSubItem item, int i, double iconSz,
      double pad, double fs) {
    return Transform.scale(
      scale: _scaleAnims[i].value,
      child: Opacity(
        opacity: _opacityAnims[i].value.clamp(0.0, 1.0),
        child: _card(ctx, item, iconSz, pad, fs),
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
          color: (widget.isDarkMode ? Colors.white : Colors.black)
              .withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      );

  Widget _card(BuildContext context, _QuranSubItem item, double iconSz,
      double pad, double fs) {
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
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(pad),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: context.primaryColor.withValues(alpha: 0.12)),
                  ),
                  child: item.svgAsset != null
                      ? SvgPicture(AssetBytesLoader(item.svgAsset!),
                          width: iconSz,
                          height: iconSz,
                          colorFilter: ColorFilter.mode(
                              widget.isDarkMode
                                  ? context.primaryLightColor
                                  : context.primaryColor,
                              BlendMode.srcIn))
                      : Icon(item.icon,
                          size: iconSz,
                          color: widget.isDarkMode
                              ? context.primaryLightColor
                              : context.primaryColor),
                ),
                SizedBox(height: 12.h),
                AutoSizeText(item.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    minFontSize: 8,
                    maxFontSize: 24,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: fs,
                        fontWeight: FontWeight.w600,
                        color: widget.isDarkMode
                            ? Colors.white
                            : Colors.black.withValues(alpha: 0.85),
                        fontFamily: "Amiri",
                        height: 1.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
