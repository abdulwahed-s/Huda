import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:vector_graphics/vector_graphics.dart';

class CustomizationJiggle extends StatelessWidget {
  const CustomizationJiggle({
    super.key,
    required this.animation,
    required this.seed,
    required this.child,
    this.active = true,
  });

  final Animation<double> animation;
  final int seed;
  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (!active || MediaQuery.disableAnimationsOf(context)) return child;
    final phase = (seed % 19) / 19 * math.pi * 2;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final wave = math.sin(animation.value * math.pi * 2 + phase);
        return Transform.translate(
          offset: Offset(wave * 0.55, wave.abs() * -0.35),
          child: Transform.rotate(angle: wave * 0.0105, child: child),
        );
      },
    );
  }
}

class EditableHomeFeatureCard extends StatelessWidget {
  const EditableHomeFeatureCard({
    super.key,
    required this.feature,
    required this.visible,
    required this.primary,
    required this.lifted,
    required this.jiggle,
    required this.onVisibilityChanged,
    required this.onMove,
  });

  final HomeFeatureDefinition feature;
  final bool visible;
  final bool primary;
  final bool lifted;
  final Animation<double> jiggle;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.primaryColor;
    final surface = Color.alphaBlend(
      accent.withValues(alpha: visible ? (isDark ? 0.09 : 0.025) : 0.015),
      visible ? scheme.surface : scheme.surfaceContainerHighest,
    );

    return CustomizationJiggle(
      animation: jiggle,
      seed: feature.id.index,
      active: !lifted,
      child: Semantics(
        container: true,
        label: feature.title,
        toggled: visible,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: visible ? 1 : 0.52,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: lifted
                    ? accent.withValues(alpha: 0.55)
                    : visible
                        ? accent.withValues(alpha: isDark ? 0.25 : 0.15)
                        : scheme.outlineVariant,
                width: lifted ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: lifted ? (isDark ? 0.38 : 0.20) : 0.06,
                  ),
                  blurRadius: lifted ? 28 : 12,
                  offset: Offset(0, lifted ? 14 : 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 24, 12, 9),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _FeatureGlyph(feature: feature, color: accent),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Center(
                            child: Text(
                              feature.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.12,
                                  ),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.drag_indicator_rounded,
                          size: 17,
                          color: scheme.onSurface.withValues(alpha: 0.36),
                        ),
                      ],
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 7,
                  start: 7,
                  child: _VisibilityBadge(
                    visible: visible,
                    tooltip: visible ? l10n.remove : feature.title,
                    onPressed: () => onVisibilityChanged(!visible),
                  ),
                ),
                PositionedDirectional(
                  top: 7,
                  end: 7,
                  child: _CardActionButton(
                    icon: primary ? Icons.south_rounded : Icons.north_rounded,
                    tooltip: primary ? l10n.moveToViewMore : l10n.moveToPrimary,
                    onPressed: onMove,
                  ),
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
    required this.visible,
    required this.lifted,
    required this.seed,
    required this.jiggle,
    required this.onVisibilityChanged,
  });

  final String title;
  final IconData icon;
  final bool visible;
  final bool lifted;
  final int seed;
  final Animation<double> jiggle;
  final ValueChanged<bool> onVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final accent = context.primaryColor;
    return CustomizationJiggle(
      animation: jiggle,
      seed: seed + 31,
      active: !lifted,
      child: Semantics(
        container: true,
        label: title,
        toggled: visible,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: visible ? 1 : 0.52,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 14, 10),
            decoration: BoxDecoration(
              color: visible ? scheme.surface : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: lifted
                    ? accent.withValues(alpha: 0.55)
                    : accent.withValues(alpha: visible ? 0.15 : 0.05),
                width: lifted ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: lifted ? 0.18 : 0.05),
                  blurRadius: lifted ? 26 : 10,
                  offset: Offset(0, lifted ? 12 : 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _VisibilityBadge(
                  visible: visible,
                  tooltip: visible ? l10n.remove : title,
                  onPressed: () => onVisibilityChanged(!visible),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 23),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.drag_indicator_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.42),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureGlyph extends StatelessWidget {
  const _FeatureGlyph({required this.feature, required this.color});

  final HomeFeatureDefinition feature;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.18),
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

class _VisibilityBadge extends StatelessWidget {
  const _VisibilityBadge({
    required this.visible,
    required this.tooltip,
    required this.onPressed,
  });

  final bool visible;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = visible
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: color,
          elevation: 2,
          shadowColor: Colors.black38,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 29,
              child: Icon(
                visible ? Icons.remove_rounded : Icons.add_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.90),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 29,
            child: Icon(icon, size: 17, color: scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
