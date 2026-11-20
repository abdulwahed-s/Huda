import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/hadith_text_formatter.dart';
import 'package:huda/data/models/hadith_details_model.dart' as details;
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/hadith/hadith_identity.dart';

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

  final List<HadithTextRun> isnad;

  final List<HadithTextRun> arabic;
  final List<HadithTextRun> translation;

  final int narrators;
  final String? babTitle;
  final String? babArabic;
  final String? grade;
  final String? gradedBy;

  String get arabicText => _plain(arabic);

  bool get unmarkedChain {
    if (isnad.isNotEmpty) return false;
    final bare = arabicText.replaceAll(_harakat, '');
    return _chainOpenings.any(bare.startsWith);
  }

  static final _harakat = RegExp('[\u064B-\u065F\u0670\u06D6-\u06ED]');
  static const _chainOpenings = ['حدثنا', 'حدثني', 'أخبرنا', 'أخبرني', 'عن '];
  String get isnadText => _plain(isnad);
  String get translationText => _plain(translation);

  String? bab({required bool arabicUi}) =>
      arabicUi ? babArabic ?? babTitle : babTitle ?? babArabic;

  static String _plain(List<HadithTextRun> runs) =>
      runs.map((run) => run.text).join().trim();

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
