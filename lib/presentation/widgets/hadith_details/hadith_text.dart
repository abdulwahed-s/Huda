import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/hadith_text_formatter.dart';
import 'package:huda/data/models/hadith_details_model.dart' as details;
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/hadith/hadith_identity.dart';

/// One hadith as the reader shows it: the Arabic chain (isnad) and text
/// (matn), the English translation, the narrators in the chain, the bab it
/// sits under and its grade. Read once from the API's model.
class HadithEntry {
  const HadithEntry({
    required this.number,
    this.isnad = const [],
    this.arabic = const [],
    this.translation = const [],
    this.narrators = 0,
    this.babTitle,
    this.babArabic,
    this.grade,
    this.gradedBy,
  });

  factory HadithEntry.of(details.Data data) {
    details.Hadith? ar;
    details.Hadith? en;
    for (final entry in data.hadith ?? const <details.Hadith>[]) {
      if ((entry.body ?? '').trim().isEmpty) continue;
      if (entry.lang == 'ar') {
        ar ??= entry;
      } else {
        en ??= entry;
      }
    }
    final arabicRuns = ar == null
        ? const <HadithTextRun>[]
        : HadithTextFormatter.format(ar.body!).runs;
    final isnad = [
      for (final run in arabicRuns)
        if (run.isnad) run,
    ];
    final matn = isnad.isEmpty
        ? arabicRuns
        : [
            for (final run in arabicRuns)
              if (!run.isnad) run,
          ];
    String? grade;
    String? gradedBy;
    for (final entry in [?en, ?ar]) {
      for (final g in entry.grades ?? const <details.Grades>[]) {
        if ((g.grade ?? '').trim().isEmpty) continue;
        grade = g.grade!.trim();
        gradedBy = g.gradedBy?.trim();
        break;
      }
      if (grade != null) break;
    }
    String? clean(String? text) {
      final plain = HadithTextFormatter.format(text ?? '').plainText.trim();
      return plain.isEmpty ? null : plain;
    }

    return HadithEntry(
      number: data.hadithNumber?.trim() ?? '',
      isnad: _trim(isnad),
      arabic: _trim(matn),
      translation: en == null
          ? const []
          : HadithTextFormatter.format(en.body!).runs,
      narrators: hadithNarratorCount(
        (isnad.isEmpty ? arabicRuns : isnad).map((run) => run.narrator),
      ),
      babTitle: clean(en?.chapterTitle),
      babArabic: clean(ar?.chapterTitle),
      grade: grade,
      gradedBy: gradedBy == null || gradedBy.isEmpty ? null : gradedBy,
    );
  }

  final String number;

  /// The Arabic chain of narrators, when the source marks it.
  final List<HadithTextRun> isnad;

  /// The Arabic text: the matn alone when the chain is marked, else the
  /// whole narration.
  final List<HadithTextRun> arabic;
  final List<HadithTextRun> translation;

  /// Narrators named in the chain (0 when unmarked).
  final int narrators;
  final String? babTitle;
  final String? babArabic;
  final String? grade;
  final String? gradedBy;

  String get arabicText => _plain(arabic);

  /// The Arabic opens with a chain the source doesn't mark ("حدثنا …"), so
  /// it can't be set apart from the matn.
  bool get unmarkedChain {
    if (isnad.isNotEmpty) return false;
    final bare = arabicText.replaceAll(_harakat, '');
    return _chainOpenings.any(bare.startsWith);
  }

  static final _harakat = RegExp('[\u064B-\u065F\u0670\u06D6-\u06ED]');
  static const _chainOpenings = ['حدثنا', 'حدثني', 'أخبرنا', 'أخبرني', 'عن '];
  String get isnadText => _plain(isnad);
  String get translationText => _plain(translation);

  /// The bab in the app's language, if any.
  String? bab({required bool arabicUi}) =>
      arabicUi ? babArabic ?? babTitle : babTitle ?? babArabic;

  static String _plain(List<HadithTextRun> runs) =>
      runs.map((run) => run.text).join().trim();

  /// Without the spaces and breaks left at the edges by the split.
  static List<HadithTextRun> _trim(List<HadithTextRun> runs) {
    final out = List.of(runs);
    while (out.isNotEmpty && out.first.text.trim().isEmpty) {
      out.removeAt(0);
    }
    while (out.isNotEmpty && out.last.text.trim().isEmpty) {
      out.removeLast();
    }
    if (out.isEmpty) return out;
    out[0] = _copy(out.first, out.first.text.trimLeft());
    out[out.length - 1] = _copy(out.last, out.last.text.trimRight());
    return out;
  }

  static HadithTextRun _copy(HadithTextRun run, String text) => HadithTextRun(
    text,
    bold: run.bold,
    italic: run.italic,
    narrator: run.narrator,
    quran: run.quran,
    isnad: run.isnad,
    matn: run.matn,
  );

  /// The translation's opening "Narrated …:" line, and the rest. Null
  /// [head] when the translation doesn't open with one.
  ({String? head, List<HadithTextRun> body}) get narratedSplit {
    final plain = translation.map((run) => run.text).join();
    final end = plain.indexOf('\n');
    final head = end <= 0 ? '' : plain.substring(0, end).trim();
    if (head.isEmpty || !head.endsWith(':') || head.length > 120) {
      return (head: null, body: translation);
    }
    var skip = end;
    final body = <HadithTextRun>[];
    for (final run in translation) {
      if (skip >= run.text.length) {
        skip -= run.text.length;
        continue;
      }
      body.add(_copy(run, run.text.substring(skip)));
      skip = 0;
    }
    return (head: head, body: _trim(body));
  }
}

/// Styled hadith text: narrators in the ink accent, Quran quotations in
/// gilt (as copyists illuminated them), bold and italic from the source.
/// The matn keeps the base weight: its size is its emphasis.
class HadithRunsText extends StatelessWidget {
  const HadithRunsText({
    super.key,
    required this.runs,
    required this.style,
    this.arabic = false,
  });

  final List<HadithTextRun> runs;
  final TextStyle style;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (final run in runs)
            TextSpan(
              text: run.text,
              style: TextStyle(
                fontWeight: run.bold && !run.matn ? FontWeight.w700 : null,
                fontStyle: run.italic ? FontStyle.italic : null,
                color: run.narrator
                    ? scheme.primary
                    : run.quran
                    ? tokens.ornament
                    : null,
              ),
            ),
        ],
      ),
      textAlign: TextAlign.start,
      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
    );
  }
}

/// A grade's weight, for its tone: strong, good, weak or other.
enum HadithGradeTone { strong, good, weak, other }

HadithGradeTone hadithGradeTone(String grade) {
  final g = grade.toLowerCase();
  if (g.contains('mawdu') || g.contains('fabricated')) {
    return HadithGradeTone.weak;
  }
  if (g.contains('da') || g.contains('weak')) return HadithGradeTone.weak;
  if (g.contains('sahih')) return HadithGradeTone.strong;
  if (g.contains('hasan')) return HadithGradeTone.good;
  return HadithGradeTone.other;
}

/// A grade in the app's language, as the source writes it: "Hasan Sahih",
/// "Sahih (chain)", "Daif" …, with a capital in Latin scripts (the strings
/// are lower case).
String hadithGradeLabel(AppLocalizations t, String grade) {
  final label = _gradeLabel(t, grade);
  if (label.isEmpty) return label;
  final first = label[0];
  return RegExp('[a-z]').hasMatch(first)
      ? first.toUpperCase() + label.substring(1)
      : label;
}

String _gradeLabel(AppLocalizations t, String grade) {
  final g = grade.trim().toLowerCase();
  if (g.contains('sahih') && g.contains('hasan')) {
    return '${t.hasan} ${t.sahih}';
  }
  if (g.contains('sahih') && g.contains('chain')) {
    return '${t.sahih} (${t.chain})';
  }
  if (g.contains('hasan') && g.contains('chain')) {
    return '${t.hasan} (${t.chain})';
  }
  if (g.contains('mawdu') || g.contains('fabricated')) return t.mawdu;
  if ((g.contains('da') || g.contains('weak')) && g.contains('chain')) {
    return '${t.daif} (${t.chain})';
  }
  if (g.contains('sahih')) return t.sahih;
  if (g.contains('hasan')) return t.hasan;
  if (g.contains('da') || g.contains('weak')) return t.daif;
  if (g.contains('shadh')) return t.shadh;
  if (g.contains('munkar')) return t.munkar;
  if (g.contains('gharib')) return t.gharib;
  return grade.trim();
}

/// Who graded a hadith, in the app's language: the graders sunnah.com
/// names, in Arabic for the Arabic UI (others as the source writes them).
String? hadithGraderName(String? gradedBy, {required bool arabic}) {
  final by = gradedBy?.trim();
  if (by == null || by.isEmpty || !arabic) return by;
  const names = {
    'al-albani': 'الألباني',
    "zubair `aliza'i": 'زبير علي زئي',
    "zubair 'aliza'i": 'زبير علي زئي',
    'darussalam': 'دار السلام',
    'ibn hajar': 'ابن حجر',
    'ahmad shakir': 'أحمد شاكر',
    'adh-dhahabi': 'الذهبي',
  };
  return names[by.toLowerCase()] ?? by;
}

/// The grade as the folio's colophon: the closing line where hadith books
/// state their verdict on a narration ("هذا حديث حسن صحيح"). A ruled band
/// across the foot, in the jadwal's gilt, with the grade at its middle in
/// its tone's ink (strong in the ink accent, hasan in gilt, weak in the
/// error tone) and who graded it beside it. Owner round 1: a chip at the
/// foot read as a tag stuck on, not part of the page.
class HadithGrade extends StatelessWidget {
  const HadithGrade({super.key, required this.grade, this.gradedBy});

  final String grade;
  final String? gradedBy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final ink = switch (hadithGradeTone(grade)) {
      HadithGradeTone.strong => scheme.primary,
      HadithGradeTone.good => scheme.tertiary,
      HadithGradeTone.weak => scheme.error,
      HadithGradeTone.other => scheme.onSurfaceVariant,
    };
    final label = hadithGradeLabel(l10n, grade);
    final by = hadithGraderName(
      gradedBy,
      arabic: Localizations.localeOf(context).languageCode == 'ar',
    );
    // The jadwal's gilt at a hairline: present, not loud.
    final rule = OrnamentStyle.of(
      context,
    ).copyWith(stroke: tokens.stroke.hairline);
    Widget band(bool leading) => Expanded(
      child: SizedBox(
        height: 12,
        child: Ornament(
          painter: _ColophonRulePainter(
            style: rule,
            ink: ink,
            towardText: leading
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            textDirection: Directionality.of(context),
          ),
        ),
      ),
    );
    return Semantics(
      label: '${l10n.status}: $label${by == null ? '' : ', $by'}',
      excludeSemantics: true,
      // Centered: the text keeps its width (capped), the rules share the
      // rest. No LayoutBuilder: the share card sizes itself by intrinsics.
      child: Row(
        children: [
          band(true),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.space.sm),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: label,
                      style: theme.textTheme.titleSmall?.copyWith(color: ink),
                    ),
                    if (by != null)
                      TextSpan(
                        text: '  ·  $by',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          band(false),
        ],
      ),
    );
  }
}

/// One side of the colophon's band: a gilt double rule ending in a small
/// lozenge in the grade's ink next to the text.
class _ColophonRulePainter extends CustomPainter {
  const _ColophonRulePainter({
    required this.style,
    required this.ink,
    required this.towardText,
    required this.textDirection,
  });

  final OrnamentStyle style;
  final Color ink;
  final AlignmentDirectional towardText;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final atEnd = towardText.resolve(textDirection).x > 0;
    const d = 3.5;
    final lozenge = atEnd ? size.width - d : d;
    final line = style.line;
    for (final dy in [-2.0, 2.0]) {
      canvas.drawLine(
        Offset(atEnd ? 0 : d * 2.6, y + dy),
        Offset(atEnd ? size.width - d * 2.6 : size.width, y + dy),
        line,
      );
    }
    canvas.drawPath(
      OrnamentGeometry.polygon(Offset(lozenge, y), d, sides: 4, rotation: 0),
      Paint()..color = ink.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(_ColophonRulePainter old) =>
      old.style != style ||
      old.ink != ink ||
      old.towardText != towardText ||
      old.textDirection != textDirection;
}
