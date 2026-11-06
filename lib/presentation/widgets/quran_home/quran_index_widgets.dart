import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/quran/surah_builder.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/text_utils.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/quran_home/quran_identity.dart';

/// A surah as the Quran screens show it, in the reader's language.
@immutable
class QuranSurahRef {
  const QuranSurahRef({
    required this.number,
    required this.arabic,
    required this.title,
    required this.ayat,
    required this.meccan,
    this.translation,
    this.model,
  });

  factory QuranSurahRef.of(QuranModel surah, String language) {
    final arabic = surah.names?['ar'] ?? surah.name ?? '';
    final arabicUi = language == 'ar' || language == 'ur';
    return QuranSurahRef(
      number: surah.number ?? 1,
      arabic: arabic,
      title: arabicUi
          ? arabic
          : surah.localizedTransliteration(language) ??
                surah.englishName ??
                arabic,
      translation: language == 'ar' ? null : surah.localizedName(language),
      ayat: surah.numberOfAyahs ?? 0,
      meccan: surah.revelationType == 'Meccan',
      model: surah,
    );
  }

  /// Surah [number] from the bundled index (routes often pass only a
  /// number and a name).
  factory QuranSurahRef.number(int number, String language) =>
      QuranSurahRef.of(index[(number - 1).clamp(0, 113)], language);

  /// The 114 surahs, built once from the bundled data.
  static final List<QuranModel> index = SurahBuilder.buildQuranIndex();

  final int number;

  /// The Arabic name ("الفاتحة").
  final String arabic;

  /// The name in the reader's script: transliterated, or Arabic in Arabic
  /// and Urdu.
  final String title;

  /// What the name means, in the reader's language (none in Arabic).
  final String? translation;
  final int ayat;
  final bool meccan;
  final QuranModel? model;

  QuranModel get asModel => model ?? index[number - 1];

  /// "Meccan · 7 verses".
  String meta(AppLocalizations l10n) =>
      '${meccan ? l10n.meccan : l10n.medinan} · ${l10n.verseCountLabel(ayat)}';
}

/// The surah's name as the Mushaf's headings write it: the surah-name
/// font's ligature for "surahNNN". Decorative; the row says the name.
class QuranSurahCalligraphy extends StatelessWidget {
  const QuranSurahCalligraphy({
    super.key,
    required this.number,
    this.size = 30,
    this.color,
  });

  final int number;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Text(
      'surah${number.toString().padLeft(3, '0')}',
      textDirection: TextDirection.rtl,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
      style: context.type.surahTitle.copyWith(
        fontSize: size,
        height: 1.1,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

/// A surah in the index: its number in a rosette, its names, where it was
/// revealed and how many verses, and its name in the heading's calligraphy
/// at the end. Selected while it's the open surah.
class QuranSurahTile extends StatelessWidget {
  const QuranSurahTile({
    super.key,
    required this.surah,
    required this.onTap,
    this.selected = false,
    this.dense = false,
  });

  final QuranSurahRef surah;
  final void Function(BuildContext tileContext) onTap;
  final bool selected;

  /// A row in a side pane or sheet: no calligraphy, tighter.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final translation = surah.translation;
    final showTranslation =
        translation != null &&
        translation.isNotEmpty &&
        translation != surah.title;
    final names = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          surah.title,
          style: language == 'ar' || language == 'ur'
              ? context.type.arabicTitle.copyWith(height: 1.4)
              : theme.textTheme.titleMedium,
        ),
        if (showTranslation)
          Text(
            translation,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        SizedBox(height: space.xxs),
        Text(
          surah.meta(l10n),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    final row = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        space.md,
        dense ? space.sm : space.md,
        space.md,
        dense ? space.sm : space.md,
      ),
      child: Row(
        children: [
          QuranSurahMark(number: surah.number, size: dense ? 38 : 44),
          SizedBox(width: space.md),
          Expanded(child: names),
          if (!dense) ...[
            SizedBox(width: space.sm),
            QuranSurahCalligraphy(number: surah.number, color: scheme.primary),
          ],
        ],
      ),
    );
    final semantics = [
      l10n.surahNumberBadge(surah.number),
      surah.title,
      if (showTranslation) translation,
      surah.meta(l10n),
    ].join(', ');
    return Semantics(
      key: ValueKey('quran-surah-${surah.number}'),
      button: true,
      selected: selected,
      label: semantics,
      excludeSemantics: true,
      child: Builder(
        builder: (tileContext) => dense
            ? Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () => onTap(tileContext),
                  child: selected
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer.withValues(
                              alpha: 0.6,
                            ),
                            border: BorderDirectional(
                              start: BorderSide(
                                color: scheme.primary,
                                width: tokens.stroke.bold,
                              ),
                            ),
                          ),
                          child: row,
                        )
                      : row,
                ),
              )
            : HudaCard(
                padding: EdgeInsets.zero,
                onTap: () => onTap(tileContext),
                child: row,
              ),
      ),
    );
  }
}

/// A surah tile while the index loads, in the tile's shape.
class QuranSurahTileSkeleton extends StatelessWidget {
  const QuranSurahTileSkeleton({super.key, this.announce = false});

  final bool announce;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final text = Theme.of(context).textTheme;
    return HudaCard(
      child: HudaSkeleton(
        announce: announce,
        child: Row(
          children: [
            const HudaSkeletonBlock(width: 44, height: 44, circle: true),
            SizedBox(width: space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HudaSkeletonLines(lines: 1, style: text.titleMedium),
                  SizedBox(height: space.xxs),
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: HudaSkeletonLines(lines: 1, style: text.bodySmall),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An ayah found by its words: where it is, then the ayah with the words
/// that matched washed in gilt.
class QuranAyahHitTile extends StatelessWidget {
  const QuranAyahHitTile({
    super.key,
    required this.surah,
    required this.ayah,
    required this.text,
    required this.onTap,
    this.query = '',
  });

  final QuranSurahRef surah;
  final int ayah;
  final String text;
  final void Function(BuildContext tileContext) onTap;

  /// What was searched; its matches in [text] are highlighted.
  final String query;

  /// Matches from this far in start the excerpt shortly before them, so
  /// the four lines show the highlight.
  static const int _excerptAfter = 120;
  static const int _excerptLead = 50;

  /// [text], or its excerpt from shortly before the first match when that
  /// lies deep in a long ayah, with the matches' ranges in what's shown.
  ({String shown, List<(int, int)> marks}) _excerpt() {
    final ranges = TextUtils.normalizedMatchRanges(text, query);
    if (ranges.isEmpty) return (shown: text, marks: const []);
    var from = 0;
    var lead = '';
    final first = ranges.first.$1;
    if (first > _excerptAfter) {
      // Back to a word start a little before the match.
      final space = text.lastIndexOf(' ', first - _excerptLead);
      if (space > 0) {
        from = space + 1;
        lead = '… ';
      }
    }
    final shift = lead.length - from;
    return (
      shown: lead + text.substring(from),
      marks: [
        for (final (start, end) in ranges)
          if (end > from)
            ((start < from ? from : start) + shift, end + shift),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reference = '${surah.title} · ${l10n.ayahNumber(ayah)}';
    return Semantics(
      key: ValueKey('quran-hit-${surah.number}-$ayah'),
      button: true,
      label: '$reference. $text',
      excludeSemantics: true,
      child: Builder(
        builder: (tileContext) => HudaCard(
          onTap: () => onTap(tileContext),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  QuranSurahMark(number: surah.number, size: 30),
                  SizedBox(width: space.sm),
                  Expanded(
                    child: Text(
                      reference,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: space.sm),
              Builder(
                builder: (context) {
                  final excerpt = _excerpt();
                  return QuranMarkedText(
                    key: const ValueKey('quran-hit-text'),
                    text: excerpt.shown,
                    marks: excerpt.marks,
                    maxLines: 4,
                    style: context.type.ayah.copyWith(
                      fontSize: 22,
                      color: scheme.onSurface,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where the reader stopped: the surah and ayah, opened again at that
/// ayah with one tap. The surah's headpiece calligraphy sits at its end.
class QuranContinueCard extends StatelessWidget {
  const QuranContinueCard({
    super.key,
    required this.surah,
    required this.ayah,
    required this.onTap,
  });

  final QuranSurahRef surah;
  final int ayah;
  final void Function(BuildContext cardContext) onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      key: const ValueKey('quran-continue'),
      button: true,
      label:
          '${l10n.sectionContinueReading}: ${surah.title}, ${l10n.ayahNumber(ayah)}',
      excludeSemantics: true,
      child: Builder(
        builder: (cardContext) => HudaCard(
          onTap: () => onTap(cardContext),
          padding: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(space.md),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A gilt rule at the start, like a marginal band.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.tertiary,
                      borderRadius: BorderRadius.circular(tokens.stroke.bold),
                    ),
                    child: SizedBox(width: tokens.stroke.bold * 1.6),
                  ),
                  SizedBox(width: space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HudaEyebrow(l10n.sectionContinueReading),
                        SizedBox(height: space.xxs),
                        Text(surah.title, style: theme.textTheme.titleLarge),
                        Text(
                          l10n.ayahNumber(ayah),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: space.sm),
                  Center(
                    child: QuranSurahCalligraphy(
                      number: surah.number,
                      size: 34,
                      color: scheme.primary,
                    ),
                  ),
                  SizedBox(width: space.sm),
                  // Mirrors itself in right-to-left text.
                  Icon(Icons.arrow_forward_rounded, color: scheme.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// On a half-open book fold, keeps [child] (a search field, a card, a row
/// of chips) to the leading half, so nothing crosses the band. Elsewhere it
/// takes the full width. Assumes its column is centered in the window.
class QuranLeadingHalf extends StatelessWidget {
  const QuranLeadingHalf({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fold = FoldInfo.of(context);
    if (!fold.isBook) return child;
    final window = MediaQuery.sizeOf(context).width;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final gap = context.tokens.space.md;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = (window - constraints.maxWidth) / 2;
        final half = rtl ? window - fold.end : fold.start;
        final width = (half - side - gap).clamp(0.0, constraints.maxWidth);
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(width: width, child: child),
        );
      },
    );
  }
}

/// Arabic with some words marked as a reader marks a copy: a rounded gilt
/// wash behind each marked run, line by line, with a fine gilt rule along
/// its foot. Painted from the paragraph's own line boxes, behind text set
/// in one style, so the words join across a mark and keep their harakat.
class QuranMarkedText extends StatelessWidget {
  const QuranMarkedText({
    super.key,
    required this.text,
    required this.marks,
    required this.style,
    this.maxLines,
  });

  final String text;

  /// Ranges of [text] to mark (start inclusive, end exclusive).
  final List<(int, int)> marks;
  final TextStyle style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.start,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: style,
    );
    if (marks.isEmpty) return label;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Measured where it paints, at the width the text got: a LayoutBuilder
    // here would break the hit card's IntrinsicHeight.
    return CustomPaint(
      painter: _MarkPainter(
        text: TextSpan(
          text: text,
          style: DefaultTextStyle.of(context).style.merge(style),
        ),
        marks: marks,
        maxLines: maxLines,
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
        textHeightBehavior: DefaultTextHeightBehavior.maybeOf(context),
        wash: scheme.tertiary.withValues(alpha: dark ? 0.26 : 0.18),
        rule: scheme.tertiary.withValues(alpha: dark ? 0.9 : 0.75),
        radius: const HudaRadii().sm,
      ),
      child: label,
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({
    required this.text,
    required this.marks,
    required this.maxLines,
    required this.textScaler,
    required this.locale,
    required this.textHeightBehavior,
    required this.wash,
    required this.rule,
    required this.radius,
  });

  final TextSpan text;
  final List<(int, int)> marks;
  final int? maxLines;
  final TextScaler textScaler;
  final Locale? locale;
  final TextHeightBehavior? textHeightBehavior;
  final Color wash;
  final Color rule;
  final double radius;

  double? _width;
  List<Rect> _runs = const [];

  /// Each mark's lines, as the [Text] above lays them out at [width].
  List<Rect> _runsAt(double width) {
    if (_width == width) return _runs;
    final painter = TextPainter(
      text: text,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.start,
      maxLines: maxLines,
      ellipsis: maxLines == null ? null : '\u2026',
      textScaler: textScaler,
      locale: locale,
      textHeightBehavior: textHeightBehavior,
    )..layout(minWidth: width, maxWidth: width);
    final runs = <Rect>[];
    for (final (start, end) in marks) {
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
        boxHeightStyle: ui.BoxHeightStyle.max,
      );
      // One run per line: the boxes of a line joined.
      final lines = <double, Rect>{};
      for (final box in boxes) {
        final rect = box.toRect();
        if (rect.isEmpty) continue;
        final key = rect.top.roundToDouble();
        lines[key] = lines[key]?.expandToInclude(rect) ?? rect;
      }
      runs.addAll(lines.values);
    }
    painter.dispose();
    _width = width;
    return _runs = runs;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final runs = _runsAt(size.width);
    final fill = Paint()..color = wash;
    final line = Paint()
      ..color = rule
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final run in runs) {
      // A little air either side; the line's leading trimmed so the
      // marks of two lines don't touch.
      final h = run.height;
      final rect = Rect.fromLTRB(
        run.left - 4,
        run.top + h * 0.08,
        run.right + 4,
        run.bottom - h * 0.06,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        fill,
      );
      canvas.drawLine(
        Offset(rect.left + radius, rect.bottom - 0.75),
        Offset(rect.right - radius, rect.bottom - 0.75),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.text != text ||
      !listEquals(old.marks, marks) ||
      old.maxLines != maxLines ||
      old.textScaler != textScaler ||
      old.locale != locale ||
      old.wash != wash ||
      old.rule != rule ||
      old.radius != radius;
}
