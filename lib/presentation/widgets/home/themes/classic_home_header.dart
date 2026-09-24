import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/shared/home_edit_button.dart';
import 'package:huda/presentation/widgets/home/shared/andalusian_star_cross_pattern.dart';

class ClassicHomeSystemOverlay extends StatelessWidget {
  const ClassicHomeSystemOverlay({
    super.key,
    required this.isDark,
    required this.child,
  });

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style =
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
              statusBarColor: Colors.transparent,
              systemStatusBarContrastEnforced: false,
            );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      key: const ValueKey('classic-home-system-overlay'),
      value: style,
      child: child,
    );
  }
}

class ClassicHomeHeaderSliver extends StatelessWidget {
  const ClassicHomeHeaderSliver({
    super.key,
    required this.onCustomize,
    required this.entranceAnimation,
  });

  final VoidCallback onCustomize;
  final Animation<double> entranceAnimation;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ClassicHomeHeaderSection(
        onCustomize: onCustomize,
        entranceAnimation: entranceAnimation,
      ),
    );
  }
}

class ClassicHomeHeaderSection extends StatelessWidget {
  const ClassicHomeHeaderSection({
    super.key,
    required this.onCustomize,
    required this.entranceAnimation,
  });

  static const double _baseContentExtent = 80;
  static const double _maxContentExtent = 86;
  static const double _contentMaxWidth = 1120;

  final VoidCallback onCustomize;
  final Animation<double> entranceAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? scheme.primary : context.primaryColor;
    final accent = context.accentColor;
    final surface = scheme.surface;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final contentExtent =
        (_baseContentExtent + ((textScale - 1).clamp(0.0, 1.0) * 6))
            .clamp(_baseContentExtent, _maxContentExtent)
            .toDouble();

    final topSurface = Color.alphaBlend(
      primary.withValues(alpha: isDark ? 0.11 : 0.055),
      surface,
    );
    final warmSurface = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.045 : 0.025),
      surface,
    );
    final horizontalInset = 20.w;

    final header = Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  topSurface.withValues(alpha: isDark ? 0.82 : 0.88),
                  warmSurface.withValues(alpha: isDark ? 0.58 : 0.64),
                  surface.withValues(alpha: 0),
                ],
                stops: const [0, 0.62, 1],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: AlignmentDirectional.topStart,
                radius: 1.05,
                colors: [
                  primary.withValues(alpha: isDark ? 0.075 : 0.045),
                  primary.withValues(alpha: 0),
                ],
                stops: const [0, 1],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(
                  key: const ValueKey('classic-home-geometry'),
                  painter: AndalusianStarCrossPatternPainter(
                    primary: primary,
                    accent: accent,
                    isDark: isDark,
                    bandHeight: 48,
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: SizedBox(
            height: contentExtent,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _contentMaxWidth + horizontalInset * 2,
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: horizontalInset,
                  ),
                  child: _ClassicHeaderRow(
                    primary: primary,
                    accent: accent,
                    onCustomize: onCustomize,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    final content = Semantics(
      key: const ValueKey('classic-home-header-section'),
      container: true,
      explicitChildNodes: true,
      child: header,
    );
    if (MediaQuery.disableAnimationsOf(context)) return content;

    return AnimatedBuilder(
      key: const ValueKey('classic-home-header-entrance'),
      animation: entranceAnimation,
      child: content,
      builder: (context, child) {
        final interval = (entranceAnimation.value / 0.34).clamp(0.0, 1.0);
        final settled = Curves.easeOutCubic.transform(interval);
        return Opacity(
          opacity: 0.86 + settled * 0.14,
          child: Transform.translate(
            offset: Offset(0, (1 - settled) * 4),
            child: child,
          ),
        );
      },
    );
  }
}

class _ClassicHeaderRow extends StatelessWidget {
  const _ClassicHeaderRow({
    required this.primary,
    required this.accent,
    required this.onCustomize,
  });

  final Color primary;
  final Color accent;
  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.15,
    );
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Semantics(
              container: true,
              header: true,
              label: l10n.huda,
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ClassicAppMark(primary: primary, accent: accent),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        l10n.huda,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        HomeEditButton(
          key: const ValueKey('classic-home-customize'),
          onPressed: onCustomize,
          foregroundColor: primary,
          backgroundColor: primary.withValues(alpha: 0.055),
          borderColor: primary.withValues(alpha: 0.18),
        ),
      ],
    );
  }
}

class _ClassicAppMark extends StatelessWidget {
  const _ClassicAppMark({required this.primary, required this.accent});

  final Color primary;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surface = Color.alphaBlend(
      primary.withValues(alpha: 0.065),
      scheme.surface,
    );
    return SizedBox(
      key: const ValueKey('classic-home-app-mark'),
      width: 43,
      height: 43,
      child: Stack(
        children: [
          PositionedDirectional(
            start: 5,
            top: 5,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: const BorderRadiusDirectional.only(
                  topStart: Radius.circular(11),
                  topEnd: Radius.circular(7),
                  bottomStart: Radius.circular(7),
                  bottomEnd: Radius.circular(13),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 0,
            top: 0,
            child: Container(
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: const BorderRadiusDirectional.only(
                  topStart: Radius.circular(13),
                  topEnd: Radius.circular(8),
                  bottomStart: Radius.circular(8),
                  bottomEnd: Radius.circular(13),
                ),
                border: Border.all(color: primary.withValues(alpha: 0.22)),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ImageIcon(
                const AssetImage('assets/images/huda.png'),
                key: const ValueKey('classic-home-app-mark-image'),
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
