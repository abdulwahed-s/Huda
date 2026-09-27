import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/presentation/widgets/home/classic_feature_card_content.dart';

class FeatureCard extends StatelessWidget {
  final String title;
  final String? svgAsset;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isDarkMode;
  final int index;
  final bool animateEntrance;
  final bool enabled;
  final FocusNode? focusNode;
  final SemanticsSortKey? semanticsSortKey;

  const FeatureCard({
    super.key,
    required this.title,
    this.svgAsset,
    this.icon,
    required this.onTap,
    required this.isDarkMode,
    required this.index,
    this.animateEntrance = true,
    this.enabled = true,
    this.focusNode,
    this.semanticsSortKey,
  });

  @override
  Widget build(BuildContext context) {
    final surface = ExcludeSemantics(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [const Color(0xFF2B2F3A), const Color(0xFF1E2230)]
                : [const Color(0xFFFFFFFF), const Color(0xFFF8FAFF)],
          ),
          border: Border.all(
            color: (isDarkMode ? Colors.white : Colors.black).withValues(
              alpha: 0.06,
            ),
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: enabled ? onTap : null,
            canRequestFocus: enabled,
            focusNode: focusNode,
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.pressed)
                  ? context.primaryColor.withValues(alpha: 0.12)
                  : states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.focused)
                  ? context.primaryColor.withValues(alpha: 0.07)
                  : null,
            ),
            child: ClassicFeatureCardContent(
              title: title,
              titleColor: isDarkMode
                  ? Colors.white
                  : Colors.black.withValues(alpha: 0.85),
              iconBuilder: (metrics) => Container(
                padding: EdgeInsets.all(metrics.iconPadding),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.12),
                  ),
                ),
                child: svgAsset != null
                    ? SvgPicture(
                        AssetBytesLoader(svgAsset!),
                        width: metrics.iconSize,
                        height: metrics.iconSize,
                        colorFilter: ColorFilter.mode(
                          isDarkMode
                              ? context.primaryLightColor
                              : context.primaryColor,
                          BlendMode.srcIn,
                        ),
                      )
                    : Icon(
                        icon,
                        size: metrics.iconSize,
                        color: isDarkMode
                            ? context.primaryLightColor
                            : context.primaryColor,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
    final card = enabled
        ? Semantics(
            button: true,
            enabled: true,
            label: title,
            onTap: onTap,
            sortKey: semanticsSortKey,
            child: surface,
          )
        : surface;

    if (!animateEntrance) return card;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      child: card,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
    );
  }
}
