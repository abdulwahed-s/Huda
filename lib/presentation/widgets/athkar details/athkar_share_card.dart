import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/athkar/athkar_identity.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/share/share_image_frame.dart';

/// Athkar's share image, night in both themes (the card is an image), on
/// the chrome with a faint girih field: the chapter at the top, then a
/// pointed arch as a soft panel with the rosette sun half risen on its
/// horizon, the dhikr under it, a petal divider before the translation,
/// and the repetition medallion on the threshold. Hisn al-Muslim and
/// Huda's mark sign it at the foot. Its frame, pattern and composition are
/// Athkar's own; only the capture pipeline is shared.
///
/// Width: [BrandedShareFrame.width]. As tall as the dhikr needs at a size
/// that reads, never shorter than a square: the text keeps its size and the
/// card grows (owner rounds 4 and 5: a fixed square shrank a long dhikr out
/// of reading, and a second, story size added nothing).
class AthkarShareCard extends StatelessWidget {
  const AthkarShareCard({
    super.key,
    required this.title,
    required this.arabicText,
    this.translatedText,
    required this.repeatCount,
  });

  /// The chapter's name, at the top.
  final String title;
  final String arabicText;

  /// Null or empty hides the translation and its divider.
  final String? translatedText;
  final int repeatCount;

  static const double width = BrandedShareFrame.width;

  /// The card's height over its width, estimated: the share sheet scrolls
  /// the preview of a card taller than 9:16.
  static double cardRatio({required String arabic, String? translation}) {
    final t = translation?.trim() ?? '';
    final fit = AthkarCardFit.card(arabic: arabic, translation: t);
    final text = _Text(
      arabic,
      t,
    ).height(AthkarCardFit._cardRoom.width, fit.arabic, fit.translation);
    final content = fit.sun / 2 + 4 + 1.5 + fit.gap + text;
    // The card's chrome around the arch's text room, at a square.
    const chrome = width - 172;
    return math.max(width, chrome + content) / width;
  }

  static const _medallion = 64.0;

  @override
  // Share images are captured in an overlay with no Material above them.
  // The card is an image: the reader's text size doesn't apply to it.
  Widget build(BuildContext context) => MediaQuery.withNoTextScaling(
    child: Material(
      type: MaterialType.transparency,
      child: Builder(builder: _card),
    ),
  );

  String get _translation => translatedText?.trim() ?? '';

  Widget _field(BuildContext context) {
    final tokens = context.tokens;
    return Positioned.fill(
      child: Ornament(
        painter: StarFieldPainter(
          style: OrnamentStyle.of(context, onChrome: true).copyWith(
            color: tokens.gilt.withValues(alpha: 0.1),
            stroke: tokens.stroke.hairline,
            render: OrnamentRender.line,
          ),
          module: 40,
        ),
      ),
    );
  }

  Widget _eyebrow(BuildContext context) => Text(
    AppLocalizations.of(context)!.athkar.toUpperCase(),
    textAlign: TextAlign.center,
    style: context.type.eyebrow.copyWith(color: context.tokens.gilt),
  );

  Widget _title(BuildContext context, {int maxLines = 2}) => Text(
    title,
    key: const ValueKey('athkar_share_title'),
    textAlign: TextAlign.center,
    textDirection: shareTextDirection(title),
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(color: context.tokens.onChrome),
  );

  Widget _medallionOn(Widget arch) => Stack(
    clipBehavior: Clip.none,
    children: [
      arch,
      Positioned(
        left: 0,
        right: 0,
        bottom: -_medallion / 2,
        child: Center(child: _RepetitionMedallion(times: repeatCount)),
      ),
    ],
  );

  /// As tall as its content, at least a square: sized by one intrinsic
  /// pass, so the text is never scaled.
  Widget _card(BuildContext context) {
    final tokens = context.tokens;
    final gilt = OrnamentStyle.of(context, onChrome: true);
    final fit = AthkarCardFit.card(
      arabic: arabicText,
      translation: _translation,
    );
    final arch = _medallionOn(
      CustomPaint(
        painter: _ArchPanelPainter(
          fill: tokens.onChrome.withValues(alpha: 0.05),
          style: gilt,
          head: 0.27,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 28, 30, _medallion / 2 + 12),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The sun, half risen over the horizon.
                SizedBox(
                  height: fit.sun / 2 + 4,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      maxHeight: fit.sun,
                      child: SizedBox.square(
                        dimension: fit.sun,
                        child: Ornament(painter: AthkarSunPainter(style: gilt)),
                      ),
                    ),
                  ),
                ),
                Container(height: tokens.stroke.fine, color: tokens.gilt),
                SizedBox(height: fit.gap),
                _DhikrText(
                  arabic: arabicText,
                  translation: _translation,
                  fit: fit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: width),
      child: IntrinsicHeight(
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: tokens.chromeGradient),
          child: Stack(
            children: [
              _field(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 22, 26, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _eyebrow(context),
                    const SizedBox(height: 6),
                    _title(context),
                    const SizedBox(height: 12),
                    Expanded(child: arch),
                    const SizedBox(height: _medallion / 2 + 8),
                    _Attribution(
                      source: AppLocalizations.of(context)!.athkarSource,
                      color: tokens.onChromeMuted,
                      mark: tokens.gilt,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dhikr, then a petal divider and the translation, at [fit]'s sizes.
class _DhikrText extends StatelessWidget {
  const _DhikrText({
    required this.arabic,
    required this.translation,
    required this.fit,
  });

  final String arabic;
  final String translation;
  final AthkarCardFit fit;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          arabic,
          key: const ValueKey('athkar_share_arabic'),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: context.type.dhikr.copyWith(
            fontSize: fit.arabic,
            color: tokens.onChrome,
          ),
        ),
        if (translation.isNotEmpty) ...[
          const SizedBox(height: 14),
          _PetalDivider(color: tokens.gilt),
          const SizedBox(height: 12),
          Text(
            translation,
            textAlign: TextAlign.center,
            textDirection: shareTextDirection(translation),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: fit.translation,
              color: tokens.onChromeMuted,
              height: 1.55,
            ),
          ),
        ],
      ],
    );
  }
}

/// A pointed arch as a soft panel: filled faintly, with a double gilt
/// outline and a threshold line along its foot. Its head is [head] of its
/// width (at most 38% of its height), so a tall arch keeps its proportion.
class _ArchPanelPainter extends CustomPainter {
  const _ArchPanelPainter({
    required this.fill,
    required this.style,
    required this.head,
  });

  final Color fill;
  final OrnamentStyle style;
  final double head;

  @override
  void paint(Canvas canvas, Size size) {
    final s = style.stroke;
    final outer = Rect.fromLTRB(s, s, size.width - s, size.height - s);
    final inner = outer.deflate(7);
    double spring(Rect r) =>
        1 - math.min(r.width * head, r.height * 0.38) / r.height;
    final body = OrnamentGeometry.pointedArch(outer, springRatio: spring(outer))
      ..close();
    canvas.drawPath(body, Paint()..color = fill);
    style.draw(
      canvas,
      OrnamentGeometry.pointedArch(outer, springRatio: spring(outer)),
      closed: false,
    );
    style.draw(
      canvas,
      OrnamentGeometry.pointedArch(inner, springRatio: spring(inner)),
      closed: false,
    );
    style.draw(
      canvas,
      Path()
        ..moveTo(outer.left, outer.bottom)
        ..lineTo(outer.right, outer.bottom),
      closed: false,
    );
  }

  @override
  bool shouldRepaint(_ArchPanelPainter old) =>
      old.fill != fill || old.style != style || old.head != head;
}

/// Two hairlines with a small 8-petal rosette between them.
class _PetalDivider extends StatelessWidget {
  const _PetalDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1, color: color.withValues(alpha: 0.45)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox.square(
              dimension: 16,
              child: Ornament(
                painter: RosettePainter(
                  style: OrnamentStyle(
                    color: color,
                    render: OrnamentRender.line,
                    stroke: 1,
                  ),
                  count: athkarPetals,
                  rings: 0,
                ),
              ),
            ),
          ),
          line,
        ],
      ),
    );
  }
}

/// "×N" in a 12-point star on the arch's threshold.
class _RepetitionMedallion extends StatelessWidget {
  const _RepetitionMedallion({required this.times});

  final int times;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox.square(
      dimension: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.chrome,
              ),
            ),
          ),
          Positioned.fill(
            child: Ornament(
              painter: _StarMedallionPainter(
                style: OrnamentStyle(
                  color: tokens.gilt,
                  render: OrnamentRender.line,
                  stroke: tokens.stroke.fine,
                ),
              ),
            ),
          ),
          Text(
            '×${math.max(1, times)}',
            key: const ValueKey('athkar_share_repeat'),
            textDirection: TextDirection.ltr,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: tokens.onChrome),
          ),
        ],
      ),
    );
  }
}

class _StarMedallionPainter extends CustomPainter {
  const _StarMedallionPainter({required this.style});

  final OrnamentStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    style.draw(
      canvas,
      OrnamentGeometry.star(c, r - 1, points: 12, innerRatio: 0.86),
    );
    style.draw(
      canvas,
      Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.72)),
    );
  }

  @override
  bool shouldRepaint(_StarMedallionPainter old) => old.style != style;
}

/// The source on the leading side, Huda's mark on the trailing, their
/// feet on one line.
class _Attribution extends StatelessWidget {
  const _Attribution({
    required this.source,
    required this.color,
    required this.mark,
  });

  final String source;
  final Color color;
  final Color mark;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Text(
          source,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(width: 12),
      _BrandMark(color: mark, logo: 22),
    ],
  );
}

/// Huda's logo above its name (owner round 4).
class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.color, required this.logo});

  final Color color;

  /// The logo's height.
  final double logo;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _GiltLogo(color: color, height: logo),
      SizedBox(height: logo / 5),
      Text(
        'Huda',
        key: const ValueKey('athkar_share_attribution'),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          height: 1,
        ),
      ),
    ],
  );
}

/// Huda's logo in gilt, lit from above like the lamps, with a faint glow
/// of its own shape behind it so it sits in the night rather than on it
/// (owner round 3: the logo, not a stand-in mark, and not plain white).
class _GiltLogo extends StatelessWidget {
  const _GiltLogo({required this.color, required this.height});

  final Color color;

  /// The glyph's height; the asset's padding is cropped away.
  final double height;

  // The glyph's box inside the 1024 square asset.
  static const _glyphWidth = 830 / 1024;
  static const _glyphHeight = 448 / 1024;

  @override
  Widget build(BuildContext context) {
    final side = height / _glyphHeight;
    final light = Color.lerp(color, Colors.white, 0.45)!;
    Widget glyph() => ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [light, color, Color.lerp(color, Colors.black, 0.12)!],
        stops: const [0.3, 0.55, 0.72],
      ).createShader(bounds),
      child: Image.asset(
        BrandedShareFrame.logoAsset,
        width: side,
        height: side,
        filterQuality: FilterQuality.medium,
      ),
    );
    return SizedBox(
      key: const ValueKey('athkar_share_logo'),
      width: side * _glyphWidth,
      height: height,
      child: OverflowBox(
        maxWidth: side,
        maxHeight: side,
        child: Stack(
          children: [
            // The glow: the glyph itself, blurred and faint.
            Opacity(
              opacity: 0.55,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: glyph(),
              ),
            ),
            glyph(),
          ],
        ),
      ),
    );
  }
}

/// The sizes on a card, from how many lines the text takes in its room
/// at each size (arithmetic on character counts, not a measure-and-retry
/// text widget).
@immutable
class AthkarCardFit {
  const AthkarCardFit._({
    required this.arabic,
    required this.translation,
    required this.sun,
    required this.gap,
  });

  /// On the card: the largest size that keeps it square, and never below
  /// 22 for the Arabic, where the card grows instead (owner round 4).
  factory AthkarCardFit.card({
    required String arabic,
    required String translation,
  }) {
    const gap = 18.0;
    final text = _Text(arabic, translation);
    // A smaller sun keeps a medium dhikr square; a long one grows the
    // card, so it keeps the whole sun.
    for (final (sun, from, to) in [(76.0, 34.0, 30.0), (52.0, 29.5, 22.0)]) {
      for (var size = from; size >= to; size -= 0.5) {
        final t = (size * 0.55).clamp(13.0, 16.0);
        final fixed = sun / 2 + 4 + 1.5 + gap;
        if (fixed + text.height(_cardRoom.width, size, t) <= _cardRoom.height) {
          return AthkarCardFit._(
            arabic: size,
            translation: t,
            sun: sun,
            gap: gap,
          );
        }
      }
    }
    return const AthkarCardFit._(
      arabic: 22,
      translation: 13,
      sun: 76,
      gap: gap,
    );
  }

  final double arabic;
  final double translation;

  /// The sun, half risen above the dhikr.
  final double sun;

  /// Between the horizon and the dhikr.
  final double gap;

  // The card's arch text room at a square (from the layout).
  static const _cardRoom = Size(308, 172);
}

/// A dhikr's height at a size, from its line count. Widths per character
/// and line heights measured with the bundled fonts (Amiri at 1.9, the
/// translation at 1.55), with a margin for line ends.
class _Text {
  _Text(String arabic, this.translation)
    : letters = arabic.replaceAll(_harakat, '').length;

  final int letters;
  final String translation;

  static final _harakat = RegExp('[\u064B-\u065F\u0670\u06D6-\u06ED]');

  static int _lines(int chars, double em, double size, double width) =>
      math.max(1, (chars * em * size * 1.08 / width).ceil());

  double height(double width, double arabic, double translation) {
    var h = _lines(letters, 0.37, arabic, width) * arabic * 1.9;
    if (this.translation.isNotEmpty) {
      h +=
          42 +
          _lines(this.translation.length, 0.45, translation, width) *
              translation *
              1.55;
    }
    return h;
  }
}
