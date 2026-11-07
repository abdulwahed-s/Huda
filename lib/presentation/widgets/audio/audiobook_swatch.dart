import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/audio/audiobooks_identity.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

/// A recording as a woven swatch: its cloth (shade and border from
/// [seed]), the plait across it and a fringe at the foot.
///
/// With [chapters], the plait is the recording: an eye per chapter, those
/// heard filled, the [current] one ringed and filling by [fraction] (the
/// part of it played). [weaveIn] weaves the ribbon in once as the swatch
/// first appears; when [current] changes, the ribbon weaves forward (the
/// window slides one eye along). Without [chapters] the plait is
/// decorative (library tiles). Reduce motion: woven and in place.
class AudiobookSwatch extends StatefulWidget {
  const AudiobookSwatch({
    super.key,
    required this.seed,
    this.chapters,
    this.current,
    this.fraction = 0,
    this.weaveIn = false,
    this.semanticLabel,
  });

  /// Width over height, fringe included.
  static const double aspect = 1.32;

  final int seed;
  final int? chapters;
  final int? current;
  final double fraction;
  final bool weaveIn;

  /// Read out instead of "Chapter n of m"; decorative when null and there
  /// are no [chapters].
  final String? semanticLabel;

  @override
  State<AudiobookSwatch> createState() => _AudiobookSwatchState();
}

class _AudiobookSwatchState extends State<AudiobookSwatch>
    with TickerProviderStateMixin {
  late final AnimationController _weave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    value: widget.weaveIn ? 0 : 1,
  );
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: 1,
  );
  double _from = 0;
  late double _to = (widget.current ?? 0).toDouble();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.weaveIn) return;
    final motion = context.tokens.motion;
    if (motion.of(context, motion.long) == Duration.zero) {
      _weave.value = 1;
    } else {
      _weave.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(AudiobookSwatch old) {
    super.didUpdateWidget(old);
    final current = widget.current;
    if (current != null && current != old.current) {
      final motion = context.tokens.motion;
      _from = _shown;
      _to = current.toDouble();
      if (motion.of(context, motion.long) == Duration.zero) {
        _slide.value = 1;
      } else {
        _slide.forward(from: 0);
      }
    }
  }

  double get _shown =>
      _from +
      (_to - _from) * Curves.easeInOutCubic.transform(_slide.value.clamp(0, 1));

  @override
  void dispose() {
    _weave.dispose();
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context)!;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final cloth = audiobookCloth(context, widget.seed);
    final style = OrnamentStyle(
      color: tokens.gilt,
      render: OrnamentRender.luminous,
      stroke: tokens.stroke.fine,
    );
    final chapters = widget.chapters;
    final label =
        widget.semanticLabel ??
        (chapters != null && chapters > 0 && widget.current != null
            ? l10n.chapterProgress(widget.current! + 1, chapters)
            : null);
    final eyesHint = 5 + widget.seed.abs() % 3;
    final total = chapters ?? eyesHint;
    final art = AspectRatio(
      aspectRatio: AudiobookSwatch.aspect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: AudiobookClothPainter(
                cloth: cloth,
                thread: tokens.gilt,
                variant: widget.seed ~/ 4,
                radius: tokens.radius.md,
              ),
            ),
          ),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([_weave, _slide]),
              builder: (context, _) {
                final current = _shown;
                return CustomPaint(
                  painter: _BandPainter(
                    windowFor: (length) => chapters == null
                        ? RibbonWindow(eyes: eyesHint, start: 0)
                        : RibbonWindow.fit(
                            length: length,
                            chapters: total,
                            current: current,
                            minEye: math.max(24.0, length / 10),
                          ),
                    style: style,
                    chapters: total,
                    heard: chapters == null
                        ? 0
                        : current + widget.fraction.clamp(0.0, 1.0),
                    current: chapters == null ? null : widget.current,
                    weave: Curves.easeInOutCubic.transform(_weave.value),
                    fill: tokens.gilt,
                    ring: tokens.onChrome,
                    decorative: chapters == null,
                    rtl: rtl,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
    if (label == null) return ExcludeSemantics(child: art);
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(child: art),
    );
  }
}

/// Paints the ribbon in the swatch's ribbon band.
class _BandPainter extends CustomPainter {
  _BandPainter({
    required this.windowFor,
    required this.style,
    required this.chapters,
    required this.heard,
    required this.current,
    required this.weave,
    required this.fill,
    required this.ring,
    required this.decorative,
    required this.rtl,
  });

  final RibbonWindow Function(double length) windowFor;
  final OrnamentStyle style;
  final int chapters;
  final double heard;
  final int? current;
  final double weave;
  final Color fill;
  final Color ring;
  final bool decorative;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final (top, bottom) = AudiobookClothPainter.ribbonBand;
    final band = Size(size.width, size.height * (bottom - top));
    final window = windowFor(size.width);
    canvas.save();
    canvas.translate(0, size.height * top);
    AudiobookRibbonPainter(
      style: style,
      window: window,
      chapters: chapters,
      heard: heard,
      current: current,
      weave: weave,
      fill: fill,
      ring: ring,
      fadeEnds: decorative || chapters > window.eyes - 2,
      rtl: rtl,
    ).paint(canvas, band);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BandPainter old) =>
      old.heard != heard ||
      old.current != current ||
      old.weave != weave ||
      old.chapters != chapters ||
      old.style != style ||
      old.fill != fill ||
      old.ring != ring ||
      old.rtl != rtl;
}

/// A swatch-shaped skeleton for the library while it loads.
class AudiobookSwatchSkeleton extends StatelessWidget {
  const AudiobookSwatchSkeleton({super.key, this.announce = false});

  final bool announce;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final theme = Theme.of(context);
    return HudaSkeleton(
      announce: announce,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AspectRatio(
            aspectRatio: AudiobookSwatch.aspect,
            child: HudaSkeletonBlock(height: double.infinity),
          ),
          SizedBox(height: space.sm),
          HudaSkeletonLines(lines: 2, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}
