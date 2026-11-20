import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/athkar/athkar_identity.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/share/share_image_frame.dart';

class AthkarShareCard extends StatelessWidget {
  const AthkarShareCard({
    super.key,
    required this.title,
    required this.arabicText,
    this.translatedText,
    required this.repeatCount,
  });

  final String title;
  final String arabicText;

  final String? translatedText;
  final int repeatCount;

  static const double width = BrandedShareFrame.width;

  static double cardRatio({required String arabic, String? translation}) {
    final t = translation?.trim() ?? '';
    final fit = AthkarCardFit.card(arabic: arabic, translation: t);
    final text = _Text(
      arabic,
      t,
    ).height(AthkarCardFit._cardRoom.width, fit.arabic, fit.translation);
    final content = fit.sun / 2 + 4 + 1.5 + fit.gap + text;
    const chrome = width - 172;
    return math.max(width, chrome + content) / width;
  }

  static const _medallion = 64.0;

  @override
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

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.color, required this.logo});

  final Color color;

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

class _GiltLogo extends StatelessWidget {
  const _GiltLogo({required this.color, required this.height});

  final Color color;

  final double height;

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

@immutable
class AthkarCardFit {
  const AthkarCardFit._({
    required this.arabic,
    required this.translation,
    required this.sun,
    required this.gap,
  });

  factory AthkarCardFit.card({
    required String arabic,
    required String translation,
  }) {
    const gap = 18.0;
    final text = _Text(arabic, translation);
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

  final double sun;

  final double gap;

  static const _cardRoom = Size(308, 172);
}

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
