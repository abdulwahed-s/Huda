import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/athkar/athkar_identity.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

class AthkarChapterHeader extends StatelessWidget {
  const AthkarChapterHeader({
    super.key,
    required this.title,
    required this.titleEn,
    required this.done,
    required this.total,
    this.compact = false,
  });

  final String title;
  final String titleEn;
  final int done;
  final int total;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final arabicUi = Localizations.localeOf(context).languageCode == 'ar';
    final localized = arabicUi || titleEn.trim().isEmpty ? title : titleEn;
    const motion = HudaMotion();
    final count = Semantics(
      liveRegion: true,
      child: Text(
        l10n.athkarProgress(done, total),
        style: theme.textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
    final bar = ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: total == 0 ? 0 : done / total),
        duration: motion.of(context, motion.medium),
        curve: motion.standard,
        builder: (context, value, _) => ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radius.sm),
          child: LinearProgressIndicator(value: value, minHeight: 6),
        ),
      ),
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              localized,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
          SizedBox(height: space.xs),
          Row(
            children: [
              count,
              SizedBox(width: space.md),
              Expanded(child: bar),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HudaEyebrow(l10n.athkarSource),
        SizedBox(height: space.xs),
        if (!arabicUi) ...[
          Text(
            title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.left,
            style: context.type.arabicTitle,
          ),
          SizedBox(height: space.xxs),
        ],
        Semantics(
          header: true,
          child: Text(localized, style: theme.textTheme.headlineSmall),
        ),
        SizedBox(height: space.md),
        count,
        SizedBox(height: space.xs),
        bar,
      ],
    );
  }
}

class AthkarChapterSkeleton extends StatelessWidget {
  const AthkarChapterSkeleton({super.key, this.header = true});

  final bool header;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header) ...[
          HudaSkeleton(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HudaSkeletonBlock(width: 96, height: 12),
                SizedBox(height: space.sm),
                HudaSkeletonLines(lines: 1, style: context.type.arabicTitle),
                HudaSkeletonLines(lines: 1, style: text.headlineSmall),
                SizedBox(height: space.md),
                const HudaSkeletonBlock(height: 6),
              ],
            ),
          ),
          SizedBox(height: space.xl),
        ],
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) SizedBox(height: space.md),
          AthkarDhikrCardSkeleton(announce: !header && i == 0),
        ],
      ],
    );
  }
}

class AthkarCompletion extends StatelessWidget {
  const AthkarCompletion({super.key, required this.onStartAgain});

  final VoidCallback onStartAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    return HudaCard(
      key: const ValueKey('athkar-completion'),
      padding: EdgeInsets.fromLTRB(space.lg, space.md, space.lg, space.lg),
      child: Column(
        children: [
          SizedBox(
            height: 112,
            width: 160,
            child: AthkarRisingSun(
              from: athkarSunAtRest,
              to: 1,
              delay: const Duration(milliseconds: 900),
              builder: (context, rise) => Ornament(
                painter: AthkarHorizonPainter(
                  style: OrnamentStyle.of(context),
                  riseOf: rise,
                ),
              ),
            ),
          ),
          SizedBox(height: space.sm),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.athkarAllDone,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
          ),
          SizedBox(height: space.xxs),
          Text(
            l10n.athkarAllDoneMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: space.md),
          FilledButton(
            onPressed: onStartAgain,
            child: Text(l10n.athkarStartAgain),
          ),
        ],
      ),
    );
  }
}

class AthkarChapterPanel extends StatelessWidget {
  const AthkarChapterPanel({
    super.key,
    required this.title,
    required this.titleEn,
    required this.done,
    required this.total,
    this.horizontal = false,
  });

  final String title;
  final String titleEn;
  final int done;
  final int total;

  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    if (horizontal) {
      return Row(
        children: [
          AthkarMedallion(
            remaining: total - done,
            total: total,
            size: 128,
            label: '$done/$total',
          ),
          SizedBox(width: space.xl),
          Expanded(
            child: AthkarChapterHeader(
              title: title,
              titleEn: titleEn,
              done: done,
              total: total,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AthkarMedallion(
            remaining: total - done,
            total: total,
            size: 160,
            label: '$done/$total',
          ),
        ),
        SizedBox(height: space.lg),
        AthkarChapterHeader(
          title: title,
          titleEn: titleEn,
          done: done,
          total: total,
        ),
      ],
    );
  }
}

class AthkarChapterPanelSkeleton extends StatelessWidget {
  const AthkarChapterPanelSkeleton({super.key, this.horizontal = false});

  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final text = Theme.of(context).textTheme;
    if (horizontal) {
      return HudaSkeleton(
        child: Row(
          children: [
            const HudaSkeletonBlock(width: 128, height: 128, circle: true),
            SizedBox(width: space.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HudaSkeletonLines(lines: 3, style: text.headlineSmall),
                  SizedBox(height: space.md),
                  const HudaSkeletonBlock(height: 6),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return HudaSkeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: HudaSkeletonBlock(width: 160, height: 160, circle: true),
          ),
          SizedBox(height: space.lg),
          HudaSkeletonLines(lines: 3, style: text.headlineSmall),
          SizedBox(height: space.md),
          const HudaSkeletonBlock(height: 6),
        ],
      ),
    );
  }
}

class AthkarDhikrCardSkeleton extends StatelessWidget {
  const AthkarDhikrCardSkeleton({super.key, this.announce = false});

  final bool announce;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return HudaCard(
      child: HudaSkeleton(
        announce: announce,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const HudaSkeletonBlock(width: 56, height: 56, circle: true),
                SizedBox(width: space.sm),
                const HudaSkeletonBlock(width: 64, height: 12),
                const Spacer(),
              ],
            ),
            SizedBox(height: space.md),
            HudaSkeletonLines(lines: 3, style: context.type.dhikr),
            SizedBox(height: space.sm),
            HudaSkeletonLines(
              lines: 2,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: space.md),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: HudaSkeletonBlock(width: 120, height: 40),
            ),
          ],
        ),
      ),
    );
  }
}
