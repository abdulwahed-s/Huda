import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/hadith/hadith_identity.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_text.dart';

/// One hadith as a folio: a card ruled inside with a jadwal; at its head
/// the hadith's number in an ink seal and its chain of narrators as linked
/// nodes, and the one action, Share; then the Arabic (in Arabic the chain
/// too, quieter than the text) and, in other languages, the translation;
/// the grade at its foot as marginalia. The text is selectable.
class HadithFolioCard extends StatelessWidget {
  const HadithFolioCard({
    super.key,
    required this.entry,
    required this.onShare,
  });

  final HadithEntry entry;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final arabicUi = Localizations.localeOf(context).languageCode == 'ar';
    final showArabic = entry.arabic.isNotEmpty;
    // Arabic readers get the whole chain; others the matn and the
    // translation (which names the companion).
    final showIsnad = arabicUi && entry.isnad.isNotEmpty;
    final showTranslation =
        entry.translation.isNotEmpty && (!arabicUi || !showArabic);
    final narrated = entry.narratedSplit;
    final hadith = context.type.hadith.copyWith(color: scheme.onSurface);
    final chain = hadith.copyWith(
      fontSize: 17,
      height: 1.85,
      color: scheme.onSurfaceVariant,
    );

    final head = Row(
      children: [
        Semantics(
          label: l10n.hadithNumber(entry.number),
          excludeSemantics: true,
          child: HadithSeal(
            size: 44,
            child: Text(
              entry.number,
              maxLines: 1,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        SizedBox(width: space.sm),
        // The chain beside the seal, at its own step (not stretched across
        // the card, where it read as a progress track).
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: SizedBox(
                width: HadithChainPainter.widthFor(
                  entry.narrators,
                ).clamp(0.0, constraints.maxWidth),
                height: 16,
                child: Ornament(
                  painter: HadithChainPainter(
                    style: OrnamentStyle.of(context),
                    nodes: entry.narrators,
                    textDirection: Directionality.of(context),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: space.xs),
        IconButton(
          tooltip: l10n.share,
          onPressed: onShare,
          icon: const Icon(Icons.ios_share_rounded),
        ),
      ],
    );

    final body = <Widget>[
      if (showIsnad)
        HadithRunsText(runs: entry.isnad, arabic: true, style: chain),
      if (showArabic)
        HadithRunsText(
          runs: entry.arabic,
          arabic: true,
          // An unmarked chain for non-Arabic readers: the whole narration
          // at the chain's quieter size, the translation leads.
          style: !arabicUi && entry.unmarkedChain ? chain : hadith,
        ),
      if (showTranslation) ...[
        if (showArabic) const _Divider(),
        if (narrated.head != null)
          Text(
            narrated.head!,
            style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary),
          ),
        HadithRunsText(
          runs: narrated.head == null ? entry.translation : narrated.body,
          style: theme.textTheme.bodyLarge!.copyWith(color: scheme.onSurface),
        ),
      ],
    ];

    return HudaCard(
      padding: EdgeInsets.zero,
      child: CustomPaint(
        // The jadwal: a double rule just inside the card's edge.
        painter: RuledFramePainter(
          style: OrnamentStyle.of(context, quiet: true),
          rules: const [5, 8],
          corners: CornerMark.none,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(space.lg, space.md, space.sm, space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              head,
              Padding(
                padding: EdgeInsetsDirectional.only(end: space.md),
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < body.length; i++) ...[
                        SizedBox(height: i == 0 ? space.sm : space.md),
                        body[i],
                      ],
                    ],
                  ),
                ),
              ),
              // The verdict closes the folio, as in the books.
              if (entry.grade != null) ...[
                SizedBox(height: space.lg),
                Padding(
                  padding: EdgeInsetsDirectional.only(end: space.md),
                  child: HadithGrade(
                    grade: entry.grade!,
                    gradedBy: entry.gradedBy,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Between the Arabic and the translation: a short hairline with a lozenge.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 120,
      height: 10,
      child: Ornament(
        painter: RuleBandPainter(
          style: OrnamentStyle.of(context, quiet: true),
          textDirection: Directionality.of(context),
          points: 4,
        ),
      ),
    ),
  );
}

/// A bab heading as a rubric: the section's title in the ink accent,
/// centered between the hadith it heads, over a short rule.
class HadithRubric extends StatelessWidget {
  const HadithRubric({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arabic = RegExp(r'[؀-ۿ]').hasMatch(title);
    final style = arabic
        ? context.type.arabicTitle.copyWith(
            fontSize: 19,
            color: theme.colorScheme.primary,
          )
        : theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          );
    return Semantics(
      header: true,
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            textDirection: arabic ? TextDirection.rtl : null,
            style: style,
          ),
          SizedBox(height: context.tokens.space.xs),
          const _Divider(),
        ],
      ),
    );
  }
}

/// A loading card shaped like [HadithFolioCard].
class HadithFolioCardSkeleton extends StatelessWidget {
  const HadithFolioCardSkeleton({super.key, this.announce = false});

  final bool announce;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return HudaCard(
      padding: EdgeInsets.all(space.lg),
      child: HudaSkeleton(
        announce: announce,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                HudaSkeletonBlock(width: 44, height: 44, circle: true),
                Spacer(),
              ],
            ),
            SizedBox(height: space.md),
            HudaSkeletonLines(lines: 3, style: context.type.hadith),
            SizedBox(height: space.md),
            HudaSkeletonLines(
              lines: 4,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
