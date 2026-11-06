import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_theme.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/hadith_text_formatter.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/hadith/hadith_identity.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_text.dart';
import 'package:huda/presentation/widgets/share/share_image_frame.dart';

/// Hadith's share image: a manuscript folio on paper, in both themes (the
/// card is an image, and paper is Hadith's material; Athkar's is night).
/// A gilt jadwal frames the page; at its head the collection and the bab
/// as a rubric in ink, the chain of narrators as linked nodes; then the
/// matn and, if chosen, the translation; at its foot an ink seal with the
/// collection's Arabic name and the hadith's number, tilted as if pressed
/// by hand, the grade, and Huda's mark. Only the capture pipeline is
/// shared.
///
/// Width: [width]. As tall as the hadith needs, never shorter than a
/// square: the text keeps its size and the card grows (as Athkar's).
class HadithShareCard extends StatelessWidget {
  const HadithShareCard({
    super.key,
    required this.collection,
    this.collectionArabic,
    required this.number,
    this.rubric,
    required this.arabic,
    this.translation = const [],
    this.narrators = 0,
    this.grade,
    this.gradedBy,
    this.quietArabic = false,
  });

  /// The collection in the app's language.
  final String collection;

  /// Its Arabic name, for the seal.
  final String? collectionArabic;
  final String number;

  /// The bab, or the book's name.
  final String? rubric;
  final List<HadithTextRun> arabic;

  /// Empty leaves the translation out.
  final List<HadithTextRun> translation;
  final int narrators;
  final String? grade;
  final String? gradedBy;

  /// The Arabic is a chain the source doesn't mark: set it at the chain's
  /// quieter size, as the reader does for non-Arabic readers.
  final bool quietArabic;

  static const double width = BrandedShareFrame.width;

  /// The card's height over its width, estimated from the text's length
  /// (character counts, not a measure-and-retry text widget): the share
  /// sheet scrolls the preview of a card taller than 9:16.
  static double cardRatio({required String arabic, String translation = ''}) {
    const room = width - 2 * (_margin + _inset);
    int lines(int chars, double em, double size) =>
        math.max(1, (chars * em * size * 1.08 / room).ceil());
    final letters = arabic.replaceAll(_harakat, '').length;
    var text = arabic.isEmpty
        ? 0.0
        : lines(letters, 0.37, _arabic) * _arabic * 2;
    if (translation.isNotEmpty) {
      text +=
          40 +
          lines(translation.length, 0.45, _translation) * _translation * 1.55;
    }
    const chrome = 300.0;
    return math.max(width, chrome + text) / width;
  }

  static final _harakat = RegExp('[ً-ٰٟۖ-ۭ]');
  static const _margin = 16.0;
  static const _inset = 26.0;
  static const _arabic = 22.0;
  static const _translation = 15.0;

  /// The owner's colors on paper: the light theme, whatever the app's.
  static ThemeData _paper(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.light) return theme;
    try {
      final state = context.read<ThemeCubit>().state;
      return HudaTheme.build(
        colorTheme: state.colorTheme,
        brightness: Brightness.light,
        fontFamily: state.fontFamily,
      );
    } catch (_) {
      return theme;
    }
  }

  @override
  // Captured in an overlay with no Material above it; the reader's text
  // size doesn't apply to an image.
  Widget build(BuildContext context) => MediaQuery.withNoTextScaling(
    child: Theme(
      data: _paper(context),
      child: Material(
        type: MaterialType.transparency,
        child: Builder(builder: _card),
      ),
    ),
  );

  Widget _card(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final ink = scheme.primary;
    // Paper: the page warmed a little toward the gilt.
    final paper = Color.lerp(scheme.surfaceContainerLowest, tokens.gilt, 0.07)!;
    // The gilt on surfaces (the chrome's is too pale on paper).
    final gilt = OrnamentStyle(
      color: tokens.ornament.withValues(alpha: 0.8),
      render: OrnamentRender.line,
      stroke: tokens.stroke.fine,
    );
    final rubric = this.rubric;
    final arabicStyle = quietArabic
        ? context.type.hadith.copyWith(
            fontSize: 17,
            height: 1.9,
            color: scheme.onSurfaceVariant,
          )
        : context.type.hadith.copyWith(
            fontSize: _arabic,
            height: 2,
            color: scheme.onSurface,
          );

    final head = [
      Text(
        collection,
        key: const ValueKey('hadith_share_collection'),
        textAlign: TextAlign.center,
        textDirection: shareTextDirection(collection),
        style: context.type.eyebrow.copyWith(color: scheme.tertiary),
      ),
      if (rubric != null) ...[
        const SizedBox(height: 8),
        Text(
          rubric,
          key: const ValueKey('hadith_share_rubric'),
          textAlign: TextAlign.center,
          textDirection: shareTextDirection(rubric),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: RegExp(r'[؀-ۿ]').hasMatch(rubric)
              ? context.type.arabicTitle.copyWith(fontSize: 18, color: ink)
              : theme.textTheme.titleSmall?.copyWith(color: ink),
        ),
      ],
      if (narrators > 0) ...[
        const SizedBox(height: 12),
        Center(
          child: SizedBox(
            width: HadithChainPainter.widthFor(narrators),
            height: 14,
            child: Ornament(
              painter: HadithChainPainter(
                style: OrnamentStyle(
                  color: ink.withValues(alpha: 0.8),
                  render: OrnamentRender.line,
                  stroke: tokens.stroke.fine,
                ),
                nodes: narrators,
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ),
      ],
    ];

    final text = [
      if (arabic.isNotEmpty)
        HadithRunsText(
          key: const ValueKey('hadith_share_arabic'),
          runs: arabic,
          arabic: true,
          style: arabicStyle,
        ),
      if (translation.isNotEmpty) ...[
        if (arabic.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: SizedBox(
                width: 110,
                height: 10,
                child: Ornament(
                  painter: RuleBandPainter(
                    style: gilt,
                    textDirection: TextDirection.ltr,
                    points: 4,
                  ),
                ),
              ),
            ),
          ),
        HadithRunsText(
          key: const ValueKey('hadith_share_translated_text'),
          runs: translation,
          style: theme.textTheme.bodyMedium!.copyWith(
            fontSize: _translation,
            height: 1.55,
            color: scheme.onSurface,
          ),
        ),
      ],
    ];

    final grade = this.grade;
    final foot = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Transform.rotate(
          angle: -0.12,
          child: HadithSeal(
            key: const ValueKey('hadith_share_seal'),
            size: 84,
            color: ink,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      collectionArabic ?? collection,
                      textDirection: shareTextDirection(
                        collectionArabic ?? collection,
                      ),
                      style: context.type.arabicLabel.copyWith(
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                  ),
                  Text(
                    number,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        _Mark(color: ink),
      ],
    );

    return ColoredBox(
      color: paper,
      child: Padding(
        padding: const EdgeInsets.all(_margin),
        child: CustomPaint(
          // The jadwal: a gilt double rule, an ink hairline inside it, and
          // small squares at the corners.
          painter: RuledFramePainter(
            style: gilt,
            rules: const [0, 4, 10],
            corners: CornerMark.square,
          ),
          child: IntrinsicHeight(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: width - 2 * _margin),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(_inset, 30, _inset, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...head,
                    const SizedBox(height: 22),
                    const Spacer(),
                    ...text,
                    // The verdict closes the text, as in the books and the
                    // reader (owner round 1).
                    if (grade != null) ...[
                      const SizedBox(height: 22),
                      HadithGrade(
                        key: const ValueKey('hadith_share_grade'),
                        grade: grade,
                        gradedBy: gradedBy,
                      ),
                    ],
                    const Spacer(),
                    const SizedBox(height: 22),
                    foot,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Huda's logo above its name, in ink, small: the card's signature.
class _Mark extends StatelessWidget {
  const _Mark({required this.color});

  final Color color;

  // The glyph's box inside the 1024 square asset.
  static const _glyphWidth = 830 / 1024;
  static const _glyphHeight = 448 / 1024;
  static const _height = 16.0;

  @override
  Widget build(BuildContext context) {
    const side = _height / _glyphHeight;
    return Column(
      key: const ValueKey('hadith_share_logo'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: side * _glyphWidth,
          height: _height,
          child: OverflowBox(
            maxWidth: side,
            maxHeight: side,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              child: Image.asset(
                BrandedShareFrame.logoAsset,
                width: side,
                height: side,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Huda',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
