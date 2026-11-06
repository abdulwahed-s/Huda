import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/quran_home/quran_identity.dart';
import 'package:huda/presentation/widgets/share/share_image_frame.dart';

/// Quran's share image: an illuminated page. A deep border band from the
/// owner's color theme carries a gilt interlace with a 12-lobed rosette at
/// each corner, around a vellum field; the surah's headpiece (its name in
/// the cartouche) opens it, the ayah ends in its rosette, the translation
/// and tafsir follow when chosen, and Huda's logo sits at the foot with
/// the reference. Not Athkar's night arch, not Hadith's ruled folio.
class QuranShareCard extends StatelessWidget {
  const QuranShareCard({
    super.key,
    required this.ayahText,
    required this.ayahNumber,
    this.surahNumber,
    this.quranFontFamily,
    this.translation,
    this.tafsir,
    this.reference,
  });

  final String ayahText;
  final int ayahNumber;

  /// Draws the surah's headpiece with its calligraphy.
  final int? surahNumber;
  final String? quranFontFamily;
  final String? translation;
  final String? tafsir;
  final String? reference;

  static const double width = BrandedShareFrame.width;
  static const _band = 22.0;
  static const _inset = 22.0;
  static const _arabic = 25.0;
  static const _body = 15.0;

  /// Height over width, estimated from the text's length (no
  /// measure-and-retry), so the sheet can scroll a tall preview.
  static double cardRatio({
    required String arabic,
    String translation = '',
    String tafsir = '',
  }) {
    const room = width - 2 * (_band + _inset);
    int lines(int chars, double em, double size) =>
        math.max(1, (chars * em * size * 1.08 / room).ceil());
    final letters = arabic.replaceAll(RegExp('[ً-ٰٟۖ-ۭ]'), '').length;
    var text = lines(letters, 0.37, _arabic) * _arabic * 2.1;
    for (final extra in [translation, tafsir]) {
      if (extra.isNotEmpty) {
        text += 36 + lines(extra.length, 0.45, _body) * _body * 1.55;
      }
    }
    const chrome = 280.0;
    return math.max(width, chrome + text) / width;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // The vellum is light in both themes; the band is the deep chrome.
    final vellum = Color.lerp(Colors.white, tokens.gilt, 0.08)!;
    final ink = Color.lerp(tokens.chrome, Colors.black, 0.35)!;
    final gold = HudaTokensGold.onPaper(scheme, tokens);
    final translation = this.translation?.trim();
    final tafsir = this.tafsir?.trim();
    final surahNumber = this.surahNumber;
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: tokens.chromeGradient),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _IlluminatedBandPainter(
                  gold: tokens.gilt,
                  band: _band,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(_band),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: vellum,
                  border: Border.all(color: gold, width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _inset,
                    _inset,
                    _inset,
                    18,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (surahNumber != null)
                        SizedBox(
                          height: 62,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size = Size(constraints.maxWidth, 62);
                              final cartouche =
                                  QuranHeadpiecePainter.cartoucheRect(size);
                              return Stack(
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: QuranHeadpiecePainter(
                                        color: gold,
                                        panel: vellum,
                                        stroke: 1.3,
                                      ),
                                    ),
                                  ),
                                  Positioned.fromRect(
                                    rect: cartouche.deflate(
                                      cartouche.height * 0.1,
                                    ),
                                    child: FittedBox(
                                      child: Text(
                                        'surah${surahNumber.toString().padLeft(3, '0')}',
                                        textDirection: TextDirection.rtl,
                                        style: context.type.surahTitle.copyWith(
                                          color: ink,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 18),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '$ayahText '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: QuranAyahRosette(
                                number: ayahNumber,
                                size: 30,
                                color: gold,
                                background: vellum,
                                mushafDigits: true,
                              ),
                            ),
                          ],
                        ),
                        key: const ValueKey('quran_share_ayah'),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: context.type.ayah.copyWith(
                          fontFamily: quranFontFamily,
                          fontSize: _arabic,
                          height: 2.1,
                          color: ink,
                        ),
                      ),
                      for (final extra in [translation, tafsir])
                        if (extra != null && extra.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _Divider(color: gold),
                          const SizedBox(height: 14),
                          Text(
                            extra,
                            textAlign: TextAlign.center,
                            textDirection: shareTextDirection(extra),
                            style: text.bodyLarge?.copyWith(
                              fontSize: _body,
                              color: ink.withValues(alpha: 0.86),
                            ),
                          ),
                        ],
                      const SizedBox(height: 20),
                      _Foot(reference: reference, ink: ink, gold: gold),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card's gold on vellum: the scheme's gilt tone for light pages.
abstract final class HudaTokensGold {
  static Color onPaper(ColorScheme scheme, HudaTokens tokens) =>
      scheme.brightness == Brightness.light
      ? scheme.tertiary
      : Color.lerp(tokens.gilt, Colors.black, 0.35)!;
}

/// A small 12-lobed rosette between two fading rules.
class _Divider extends StatelessWidget {
  const _Divider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget rule(bool fadeStart) => Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: fadeStart
                ? [color.withValues(alpha: 0), color]
                : [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
    return Row(
      children: [
        rule(true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CustomPaint(
            size: const Size.square(12),
            painter: QuranRosettePainter(
              color: color,
              fill: color.withValues(alpha: 0.2),
              stroke: 1,
            ),
          ),
        ),
        rule(false),
      ],
    );
  }
}

/// The reference and Huda's mark at the foot of the page.
class _Foot extends StatelessWidget {
  const _Foot({required this.reference, required this.ink, required this.gold});

  final String? reference;
  final Color ink;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final reference = this.reference;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: reference == null
              ? const SizedBox.shrink()
              : Text(
                  reference,
                  textDirection: shareTextDirection(reference),
                  style: text.labelLarge?.copyWith(color: ink),
                ),
        ),
        Column(
          key: const ValueKey('quran_share_logo'),
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 16,
              child: OverflowBox(
                maxWidth: 38,
                maxHeight: 38,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(gold, BlendMode.srcIn),
                  child: Image.asset(
                    BrandedShareFrame.logoAsset,
                    width: 38,
                    height: 38,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text('Huda', style: text.labelSmall?.copyWith(color: gold)),
          ],
        ),
      ],
    );
  }
}

/// The illuminated border band: a gilt double rule along each edge, an
/// interlace running between them, and a 12-lobed rosette in each corner.
class _IlluminatedBandPainter extends CustomPainter {
  const _IlluminatedBandPainter({required this.gold, required this.band});

  final Color gold;
  final double band;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = gold.withValues(alpha: 0.85);
    final outer = (Offset.zero & size).deflate(4);
    final inner = (Offset.zero & size).deflate(band - 3);
    canvas.drawRect(outer, line);
    canvas.drawRect(inner, line);
    final style = OrnamentStyle(
      color: gold.withValues(alpha: 0.7),
      render: OrnamentRender.line,
      stroke: 0.9,
    );
    final mid = band / 2 + 0.5;
    final strip = band - 12;
    void run(Offset from, double length, double angle) {
      canvas.save();
      canvas.translate(from.dx, from.dy);
      canvas.rotate(angle);
      ArabesqueBorderPainter(
        style: style,
        module: 18,
      ).paint(canvas, Size(length, strip));
      canvas.restore();
    }

    final h = size.height;
    final w = size.width;
    final corner = band + 4;
    run(Offset(corner, mid - strip / 2), w - corner * 2, 0);
    run(Offset(corner, h - mid - strip / 2), w - corner * 2, 0);
    run(Offset(mid + strip / 2, corner), h - corner * 2, math.pi / 2);
    run(Offset(w - mid + strip / 2, corner), h - corner * 2, math.pi / 2);
    for (final c in [
      Offset(mid, mid),
      Offset(w - mid, mid),
      Offset(mid, h - mid),
      Offset(w - mid, h - mid),
    ]) {
      final r = band / 2 - 2;
      canvas.drawPath(
        QuranGeometry.lobedCircle(c, r),
        Paint()..color = gold.withValues(alpha: 0.25),
      );
      canvas.drawPath(QuranGeometry.lobedCircle(c, r), line);
      canvas.drawCircle(c, r * 0.3, Paint()..color = gold);
    }
  }

  @override
  bool shouldRepaint(_IlluminatedBandPainter old) =>
      old.gold != gold || old.band != band;
}
