import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:vector_graphics/vector_graphics.dart';

class EditableHomeFeatureCard extends StatelessWidget {
  const EditableHomeFeatureCard({
    super.key,
    required this.feature,
    required this.primary,
    required this.lifted,
    required this.onMove,
  });

  final HomeFeatureDefinition feature;
  final bool primary;
  final bool lifted;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.primaryColor;
    final surface = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.075 : 0.025),
      scheme.surface,
    );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedScale(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 170),
      curve: Curves.easeOutBack,
      scale: lifted ? 1.025 : 1,
      child: AnimatedContainer(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: lifted
                ? accent.withValues(alpha: 0.52)
                : scheme.outlineVariant,
            width: lifted ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(
                alpha: lifted ? (isDark ? 0.34 : 0.18) : 0.055,
              ),
              blurRadius: lifted ? 26 : 10,
              offset: Offset(0, lifted ? 12 : 4),
            ),
          ],
        ),
        child: _CardSplash(
          key: ValueKey('feature-splash-${feature.id.name}'),
          borderRadius: 22,
          color: accent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FeatureGlyph(feature: feature, color: accent),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 2, end: 2),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        size: 22,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: Text(
                      feature.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _MoveDestinationButton(
                  feature: feature,
                  primary: primary,
                  onPressed: onMove,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditableHomeSectionCard extends StatelessWidget {
  const EditableHomeSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.lifted,
  });

  final String title;
  final IconData icon;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = context.primaryColor;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 170),
      curve: Curves.easeOutBack,
      scale: lifted ? 1.018 : 1,
      child: AnimatedContainer(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: lifted
                ? accent.withValues(alpha: 0.52)
                : scheme.outlineVariant,
            width: lifted ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: lifted ? 0.18 : 0.05),
              blurRadius: lifted ? 24 : 9,
              offset: Offset(0, lifted ? 11 : 3),
            ),
          ],
        ),
        child: _CardSplash(
          borderRadius: 20,
          color: accent,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 24),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.drag_indicator_rounded,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.58),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardSplash extends StatelessWidget {
  const _CardSplash({
    super.key,
    required this.borderRadius,
    required this.color,
    required this.child,
  });

  final double borderRadius;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _splashOnly,
        excludeFromSemantics: true,
        borderRadius: radius,
        splashColor: color.withValues(alpha: 0.14),
        highlightColor: color.withValues(alpha: 0.055),
        hoverColor: color.withValues(alpha: 0.04),
        child: child,
      ),
    );
  }
}

class _MoveDestinationButton extends StatelessWidget {
  const _MoveDestinationButton({
    required this.feature,
    required this.primary,
    required this.onPressed,
  });

  final HomeFeatureDefinition feature;
  final bool primary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final accent = context.primaryColor;
    final semanticLabel = primary ? l10n.moveToViewMore : l10n.moveToHome;
    final visualLabel = primary ? l10n.viewMore : l10n.onHome;
    return Semantics(
      button: true,
      label: '$semanticLabel: ${feature.title}',
      excludeSemantics: true,
      child: Material(
        key: ValueKey('feature-move-${feature.id.name}'),
        color: primary
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.78)
            : accent.withValues(alpha: 0.12),
        shape: StadiumBorder(
          side: BorderSide(color: accent.withValues(alpha: 0.18)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    primary
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.home_rounded,
                    size: 19,
                    color: accent,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      visualLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _splashOnly() {}

class _FeatureGlyph extends StatelessWidget {
  const _FeatureGlyph({required this.feature, required this.color});

  final HomeFeatureDefinition feature;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.17),
            color.withValues(alpha: 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: feature.svgAsset == null
          ? Icon(feature.icon ?? Icons.apps_rounded, color: color, size: 25)
          : SvgPicture(
              AssetBytesLoader(feature.svgAsset!),
              width: 25,
              height: 25,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
    );
  }
}
