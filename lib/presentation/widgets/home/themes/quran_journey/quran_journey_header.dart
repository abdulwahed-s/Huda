import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey/quran_journey_motion.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey/quran_journey_visual_style.dart';

class QuranJourneyHeaderSection extends StatelessWidget {
  const QuranJourneyHeaderSection({
    super.key,
    required this.onCustomize,
    required this.entranceAnimation,
  });

  static const double contentExtent = 72;

  final VoidCallback onCustomize;
  final Animation<double> entranceAnimation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final content = SafeArea(
      bottom: false,
      child: SizedBox(
        height: contentExtent,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 12, 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        container: true,
                        label: l10n.huda,
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _QuranHeaderPageMark(),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  l10n.huda,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.15,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      key: const ValueKey('quran-home-customize'),
                      tooltip: l10n.customizeHome,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onCustomize();
                      },
                      style: IconButton.styleFrom(
                        minimumSize: const Size.square(48),
                        foregroundColor: context.primaryColor,
                        backgroundColor:
                            context.primaryColor.withValues(alpha: 0.075),
                        hoverColor:
                            context.primaryColor.withValues(alpha: 0.13),
                        focusColor:
                            context.primaryColor.withValues(alpha: 0.12),
                        highlightColor:
                            context.primaryColor.withValues(alpha: 0.10),
                        side: BorderSide(
                          color: QuranJourneyVisualStyle.rule(context),
                          width: QuranJourneyVisualStyle.innerRuleWidth,
                        ),
                      ),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const _QuranHeaderRule(),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      key: const ValueKey('quran-home-header-section'),
      container: true,
      explicitChildNodes: true,
      child: QuranJourneyEntranceReveal(
        animation: entranceAnimation,
        begin: 0,
        end: 0.24,
        distance: 2,
        beginScale: 0.998,
        startOpacity: 0.78,
        child: content,
      ),
    );
  }
}

class _QuranHeaderPageMark extends StatelessWidget {
  const _QuranHeaderPageMark();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = Color.alphaBlend(
      context.primaryColor.withValues(alpha: isDark ? 0.075 : 0.022),
      scheme.surface,
    );
    return SizedBox(
      key: const ValueKey('quran-home-app-mark'),
      width: 38,
      height: 36,
      child: Stack(
        children: [
          PositionedDirectional(
            start: 5,
            top: 4,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: context.primaryColor.withValues(alpha: 0.14),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 0,
            top: 0,
            child: Container(
              width: 30,
              height: 30,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: paper,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: context.primaryColor.withValues(alpha: 0.18),
                ),
              ),
              child: ImageIcon(
                const AssetImage('assets/images/huda.png'),
                key: const ValueKey('quran-home-logo-image'),
                color: isDark ? Colors.white : context.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuranHeaderRule extends StatelessWidget {
  const _QuranHeaderRule();

  @override
  Widget build(BuildContext context) {
    final illumination = QuranJourneyVisualStyle.illumination(context);
    return ExcludeSemantics(
      child: SizedBox(
        key: const ValueKey('quran-home-header-rule'),
        height: QuranJourneyVisualStyle.ruleWidth,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: QuranJourneyVisualStyle.rule(context, strong: true),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                width: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      context.primaryColor.withValues(alpha: 0.82),
                      illumination.withValues(alpha: 0.55),
                      illumination.withValues(alpha: 0),
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
