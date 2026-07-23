import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/core/utils/responsive_utils.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:vector_graphics/vector_graphics.dart';

enum HomeFeatureVisual { prayer, quran, compact }

typedef HomeExpandableFeatureCardBuilder = Widget Function(
  BuildContext context,
  bool expanded,
  VoidCallback toggle,
);

class HomeFeatureCollection extends StatefulWidget {
  const HomeFeatureCollection({
    super.key,
    required this.configuration,
    required this.features,
    required this.visual,
    this.leadingCardBuilder,
    this.leadingExpansionBuilder,
  });

  final HomeThemeConfiguration configuration;
  final List<HomeFeatureDefinition> features;
  final HomeFeatureVisual visual;
  final HomeExpandableFeatureCardBuilder? leadingCardBuilder;
  final WidgetBuilder? leadingExpansionBuilder;

  @override
  State<HomeFeatureCollection> createState() => _HomeFeatureCollectionState();
}

class _HomeFeatureCollectionState extends State<HomeFeatureCollection> {
  bool _expanded = false;
  bool _leadingExpanded = false;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final feature in widget.features) feature.id: feature};
    List<HomeFeatureDefinition> resolve(List<HomeFeatureId> ids) => ids
        .where((id) => !widget.configuration.hiddenFeatures.contains(id))
        .map((id) => byId[id])
        .whereType<HomeFeatureDefinition>()
        .toList();

    final primary = resolve(widget.configuration.primaryFeatures);
    final more = resolve(widget.configuration.viewMoreFeatures);
    final leadingCard = widget.leadingCardBuilder?.call(
      context,
      _leadingExpanded,
      () => setState(() => _leadingExpanded = !_leadingExpanded),
    );
    final columns = context.responsive(mobile: 2, tablet: 4, desktop: 6);
    final leadingRowFeatures =
        leadingCard == null ? primary : primary.take(columns - 1).toList();
    final remainingPrimaryFeatures = leadingCard == null
        ? const <HomeFeatureDefinition>[]
        : primary.skip(columns - 1).toList();
    if (primary.isEmpty && more.isEmpty && leadingCard == null) {
      return const SizedBox.shrink();
    }
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.widgets_outlined,
              color: context.primaryColor,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.homeMoreTools,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (leadingRowFeatures.isNotEmpty || leadingCard != null)
          _FeatureGrid(
            features: leadingRowFeatures,
            visual: widget.visual,
            leading: leadingCard,
          ),
        if (leadingCard != null && widget.leadingExpansionBuilder != null)
          AnimatedSize(
            duration: disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _leadingExpanded
                ? Padding(
                    padding: EdgeInsets.only(top: 16.h),
                    child: widget.leadingExpansionBuilder!(context),
                  )
                : const SizedBox.shrink(),
          ),
        if (remainingPrimaryFeatures.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: _FeatureGrid(
              features: remainingPrimaryFeatures,
              visual: widget.visual,
            ),
          ),
        if (more.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Semantics(
            button: true,
            expanded: _expanded,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                child: const Icon(Icons.expand_more),
              ),
              label: Text(
                _expanded
                    ? AppLocalizations.of(context)!.showLess
                    : AppLocalizations.of(context)!.viewMore,
              ),
            ),
          ),
          AnimatedSize(
            duration: disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: _FeatureGrid(
                      features: more,
                      visual: widget.visual,
                      secondary: true,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({
    required this.features,
    required this.visual,
    this.secondary = false,
    this.leading,
  });

  final List<HomeFeatureDefinition> features;
  final HomeFeatureVisual visual;
  final bool secondary;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final columns = context.responsive(mobile: 2, tablet: 4, desktop: 6);
        final tileHeight = scale > 1.45 ? 88.h : 72.h;
        return GridView.builder(
          shrinkWrap: true,
          primary: false,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
            mainAxisExtent: tileHeight,
          ),
          itemCount: features.length + (leading == null ? 0 : 1),
          itemBuilder: (context, index) {
            if (leading != null && index == 0) return leading!;
            final featureIndex = index - (leading == null ? 0 : 1);
            return _FeatureActionCard(
              key: ValueKey(features[featureIndex].id),
              feature: features[featureIndex],
              visual: visual,
              secondary: secondary,
            );
          },
        );
      },
    );
  }
}

class _FeatureActionCard extends StatelessWidget {
  const _FeatureActionCard({
    super.key,
    required this.feature,
    required this.visual,
    required this.secondary,
  });

  final HomeFeatureDefinition feature;
  final HomeFeatureVisual visual;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quranVisual = visual == HomeFeatureVisual.quran;
    final foreground = context.primaryColor;
    final background = quranVisual
        ? Color.alphaBlend(
            context.primaryColor.withValues(alpha: isDark ? 0.11 : 0.035),
            isDark
                ? Theme.of(context).colorScheme.surface
                : context.lightSurface,
          )
        : Theme.of(context).colorScheme.surface;

    return Semantics(
      button: true,
      label: feature.title,
      child: Material(
        color: background,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
          side: BorderSide(
            color: secondary
                ? Theme.of(context).colorScheme.outlineVariant
                : foreground.withValues(alpha: quranVisual ? 0.13 : 0.16),
          ),
        ),
        child: InkWell(
          onTap: feature.onTap,
          borderRadius: BorderRadius.circular(14.r),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? foreground.withValues(alpha: 0.12)
                : states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.focused)
                    ? foreground.withValues(alpha: 0.07)
                    : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 8.h),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.09),
                    borderRadius:
                        BorderRadius.circular(quranVisual ? 20.r : 11.r),
                  ),
                  child: _FeatureIcon(
                    feature: feature,
                    color: foreground,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 9.w),
                Expanded(
                  child: _FeatureLabel(feature.title, compact: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  const _FeatureIcon({
    required this.feature,
    required this.color,
    required this.size,
  });

  final HomeFeatureDefinition feature;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (feature.svgAsset != null) {
      return SvgPicture(
        AssetBytesLoader(feature.svgAsset!),
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Icon(feature.icon ?? Icons.apps, size: size, color: color);
  }
}

class _FeatureLabel extends StatelessWidget {
  const _FeatureLabel(this.label, {this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: compact ? 2 : 2,
      overflow: TextOverflow.ellipsis,
      textAlign: compact ? TextAlign.start : TextAlign.center,
      style: TextStyle(
        fontSize: compact ? 12.sp : 13.sp,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }
}
