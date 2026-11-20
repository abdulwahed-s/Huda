import 'dart:math' as math;
import 'dart:ui' show DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_system_ui.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

const double _chromeTitleMaxScale = 1.6;

typedef HeaderArtBuilder = CustomPainter Function(OrnamentStyle style);

class HudaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HudaAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.bottom,
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final inColumn = HudaChromeFrame.hasSideChrome(context);
    final bar = AppBar(
      leading: inColumn ? null : leading,
      automaticallyImplyLeading: !inColumn,
      title: MediaQuery.withClampedTextScaling(
        maxScaleFactor: _chromeTitleMaxScale,
        child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      actions: inColumn
          ? null
          : [...actions, SizedBox(width: context.tokens.space.xxs)],
      bottom: bottom,
    );
    final side = inColumn ? SideChrome.sideOf(context) : null;
    if (side == null) return bar;
    return Padding(
      padding: SideChrome.clearance(context),
      child: ClipRect(
        clipper: const _BelowOnlyClipper(),
        child: MediaQuery.removePadding(
          context: context,
          removeLeft: side == AxisDirection.left,
          removeRight: side == AxisDirection.right,
          child: bar,
        ),
      ),
    );
  }
}

class _BelowOnlyClipper extends CustomClipper<Rect> {
  const _BelowOnlyClipper();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, -size.height, size.width, size.height * 3);

  @override
  bool shouldReclip(_BelowOnlyClipper oldClipper) => false;
}

class HudaImmersiveBar extends StatelessWidget implements PreferredSizeWidget {
  const HudaImmersiveBar({
    super.key,
    this.title,
    this.leading,
    this.actions = const [],
  });

  final String? title;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final inColumn = HudaChromeFrame.hasSideChrome(context);
    return AppBar(
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      leading: inColumn ? null : leading,
      automaticallyImplyLeading: !inColumn,
      title: title == null
          ? null
          : MediaQuery.withClampedTextScaling(
              maxScaleFactor: _chromeTitleMaxScale,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
      actions: inColumn
          ? null
          : [...actions, SizedBox(width: context.tokens.space.xxs)],
    );
  }
}

abstract final class SideChrome {
  static const double minInset = 60;

  static AxisDirection? sideOf(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    if (context.windowClass.height >= WindowHeightClass.expanded) return null;
    if (padding.left >= minInset && padding.left > padding.right) {
      return AxisDirection.left;
    }
    if (padding.right >= minInset && padding.right > padding.left) {
      return AxisDirection.right;
    }
    return null;
  }

  static EdgeInsets clearance(BuildContext context) {
    final side = sideOf(context);
    if (side == null) return EdgeInsets.zero;
    final padding = MediaQuery.paddingOf(context);
    return side == AxisDirection.left
        ? EdgeInsets.only(left: padding.left)
        : EdgeInsets.only(right: padding.right);
  }

  static double freeTop(BuildContext context, AxisDirection side) {
    final media = MediaQuery.of(context);
    final width = side == AxisDirection.left
        ? media.padding.left
        : media.padding.right;
    final column = Rect.fromLTWH(
      side == AxisDirection.left ? 0 : media.size.width - width,
      0,
      width,
      media.size.height,
    );
    var top = media.padding.top;
    for (final feature in media.displayFeatures) {
      if (feature.type != DisplayFeatureType.cutout) continue;
      if (!feature.bounds.overlaps(column)) continue;
      top = math.max(top, feature.bounds.bottom);
    }
    return top;
  }
}

class HudaChromeFrame extends StatelessWidget {
  const HudaChromeFrame({
    super.key,
    required this.child,
    this.leading,
    this.actions = const [],
    this.columnColor,
    this.columnForeground,
  });

  final Widget child;

  final Widget? leading;
  final List<Widget> actions;

  final Color? columnColor;
  final Color? columnForeground;

  static bool hasSideChrome(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SideChromeScope>()?.enabled ??
      false;

  @override
  Widget build(BuildContext context) {
    final side = SideChrome.sideOf(context);
    final scoped = _SideChromeScope(enabled: side != null, child: child);
    if (side == null) {
      return Stack(fit: StackFit.passthrough, children: [scoped]);
    }
    final space = context.tokens.space;
    final media = MediaQuery.of(context);
    final left = side == AxisDirection.left;
    final inset = left ? media.padding.left : media.padding.right;
    final back =
        leading ??
        (ModalRoute.of(context)?.impliesAppBarDismissal ?? false
            ? const BackButton()
            : null);
    Widget buttons = Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?back,
          if (back != null && actions.isNotEmpty) SizedBox(height: space.xs),
          ...actions,
        ],
      ),
    );
    final foreground = columnForeground;
    if (foreground != null) {
      buttons = IconTheme.merge(
        data: IconThemeData(color: foreground),
        child: buttons,
      );
    }
    final color = columnColor;
    final column = Stack(
      fit: StackFit.expand,
      children: [
        if (color != null) IgnorePointer(child: ColoredBox(color: color)),
        Padding(
          padding: EdgeInsets.only(
            top: SideChrome.freeTop(context, side) + space.xs,
            bottom: media.padding.bottom + space.xxs,
          ),
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: double.infinity,
              child: buttons,
            ),
          ),
        ),
      ],
    );
    return Stack(
      fit: StackFit.passthrough,
      children: [
        scoped,
        Positioned(
          top: 0,
          bottom: 0,
          left: left ? 0 : null,
          right: left ? null : 0,
          width: inset,
          child: column,
        ),
      ],
    );
  }
}

class _SideChromeScope extends InheritedWidget {
  const _SideChromeScope({required this.enabled, required super.child});

  final bool enabled;

  @override
  bool updateShouldNotify(_SideChromeScope oldWidget) =>
      oldWidget.enabled != enabled;
}

class HudaScaffold extends StatelessWidget {
  const HudaScaffold({
    super.key,
    required this.title,
    required this.body,
    this.leading,
    this.actions = const [],
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final page = Theme.of(context).brightness;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: HudaSystemUi.over(top: page, bottom: page),
      child: HudaChromeFrame(
        leading: leading,
        actions: actions,
        child: Scaffold(
          appBar: HudaAppBar(title: title, leading: leading, actions: actions),
          body: body,
          floatingActionButton: floatingActionButton,
        ),
      ),
    );
  }
}

class HudaLandingScaffold extends StatelessWidget {
  const HudaLandingScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.eyebrow,
    this.art,
    this.titleMark,
    this.titleMarkHeight = 48,
    this.toolbarMark,
    this.leading,
    this.actions = const [],
    this.contentMaxWidth,
  });

  final String title;
  final List<Widget> slivers;
  final String? eyebrow;
  final HeaderArtBuilder? art;

  final Widget? titleMark;
  final double titleMarkHeight;

  final Widget? toolbarMark;
  final Widget? leading;
  final List<Widget> actions;
  final double? contentMaxWidth;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final side = SideChrome.sideOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: HudaSystemUi.over(
        top: Brightness.dark,
        bottom: Theme.of(context).brightness,
      ),
      child: HudaChromeFrame(
        leading: leading,
        actions: actions,
        columnForeground: tokens.onChrome,
        child: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (side != null)
                Positioned(
                  top: 0,
                  height: _columnTabHeight(context, side),
                  left: side == AxisDirection.left ? 0 : null,
                  right: side == AxisDirection.right ? 0 : null,
                  width: side == AxisDirection.left
                      ? MediaQuery.paddingOf(context).left
                      : MediaQuery.paddingOf(context).right,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.chrome,
                      borderRadius: BorderRadius.only(
                        bottomLeft: side == AxisDirection.right
                            ? Radius.circular(tokens.radius.lg)
                            : Radius.zero,
                        bottomRight: side == AxisDirection.left
                            ? Radius.circular(tokens.radius.lg)
                            : Radius.zero,
                      ),
                    ),
                  ),
                ),
              CustomScrollView(
                slivers: [
                  HudaLandingAppBar(
                    title: title,
                    eyebrow: eyebrow,
                    art: art,
                    titleMark: titleMark,
                    titleMarkHeight: titleMarkHeight,
                    toolbarMark: toolbarMark,
                    leading: leading,
                    actions: actions,
                    contentMaxWidth: contentMaxWidth,
                  ),
                  ...slivers,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  double _columnTabHeight(BuildContext context, AxisDirection side) {
    final space = context.tokens.space;
    final back =
        leading != null ||
        (ModalRoute.of(context)?.impliesAppBarDismissal ?? false);
    final buttons = (back ? 1 : 0) + actions.length;
    if (buttons == 0) return 0;
    final top = SideChrome.freeTop(context, side);
    return top +
        space.xs +
        buttons * kMinInteractiveDimension +
        (buttons - 1) * space.xs +
        space.sm;
  }
}


class HudaImmersiveScaffold extends StatelessWidget {
  const HudaImmersiveScaffold({
    super.key,
    required this.body,
    this.title,
    this.leading,
    this.actions = const [],
  });

  final Widget body;
  final String? title;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).brightness;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: HudaSystemUi.over(top: surface, bottom: surface),
      child: HudaChromeFrame(
        leading: leading,
        actions: actions,
        child: Builder(
          builder: (context) => Scaffold(
            extendBodyBehindAppBar: true,
            appBar: title == null && HudaChromeFrame.hasSideChrome(context)
                ? null
                : HudaImmersiveBar(
                    title: title,
                    leading: leading,
                    actions: actions,
                  ),
            body: body,
          ),
        ),
      ),
    );
  }
}

class HudaLandingAppBar extends StatelessWidget {
  const HudaLandingAppBar({
    super.key,
    required this.title,
    this.eyebrow,
    this.art,
    this.titleMark,
    this.titleMarkHeight = 48,
    this.toolbarMark,
    this.leading,
    this.actions = const [],
    this.contentMaxWidth,
  });

  final String title;

  final String? eyebrow;
  final HeaderArtBuilder? art;

  final Widget? titleMark;
  final double titleMarkHeight;

  final Widget? toolbarMark;
  final Widget? leading;
  final List<Widget> actions;

  final double? contentMaxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final media = MediaQuery.of(context);
    final compactHeight = context.windowClass.isCompactHeight;
    final titleStyle = theme.textTheme.headlineLarge!.copyWith(
      color: tokens.onChrome,
    );
    final eyebrowStyle = context.type.eyebrow.copyWith(color: tokens.gilt);
    final scaler = media.textScaler.clamp(maxScaleFactor: _chromeTitleMaxScale);

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final gutter = tokens.space.gutter(width);
        final cap = contentMaxWidth;
        final inset = cap == null ? 0.0 : math.max(0.0, (width - cap) / 2);
        final artWidth = art == null || compactHeight
            ? 0.0
            : (math.min(width, cap ?? width) * 0.3).clamp(96.0, 240.0);
        final reserve = _artReserve(artWidth, gutter, tokens);
        final textWidth = math.max(
          120.0,
          width -
              media.padding.left -
              media.padding.right -
              gutter * 2 -
              inset * 2 -
              reserve,
        );
        double measure(String text, TextStyle style, int lines) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: scaler,
            maxLines: lines,
          )..layout(maxWidth: textWidth);
          final height = painter.height;
          painter.dispose();
          return height;
        }

        final minExtent = media.padding.top + kToolbarHeight;
        final titleBlock =
            (titleMark != null
                ? titleMarkHeight
                : measure(title, titleStyle, 3)) +
            (eyebrow == null
                ? 0
                : measure(eyebrow!.toUpperCase(), eyebrowStyle, 1) +
                      tokens.space.xxs);
        final airy = context.windowClass.height >= WindowHeightClass.expanded;
        final maxExtent = compactHeight
            ? minExtent
            : minExtent +
                  titleBlock +
                  tokens.space.xl +
                  (airy ? tokens.space.xxxl : tokens.space.md);

        final inColumn = HudaChromeFrame.hasSideChrome(context);
        return SliverPersistentHeader(
          pinned: true,
          delegate: _LandingDelegate(
            title: title,
            eyebrow: eyebrow,
            art: art,
            titleMark: titleMark,
            toolbarMark: toolbarMark,
            leading: inColumn ? null : leading,
            actions: inColumn ? const [] : actions,
            minHeight: minExtent,
            maxHeight: maxExtent,
            gutter: gutter + inset,
            artWidth: artWidth,
            artReserve: reserve,
            titleStyle: titleStyle,
            eyebrowStyle: eyebrowStyle,
            tokens: tokens,
            scaler: scaler,
          ),
        );
      },
    );
  }
}

double _artReserve(double artWidth, double gutter, HudaTokens tokens) {
  if (artWidth <= 0) return 0;
  return math.max(0, gutter * 0.5 + artWidth * 0.8 - gutter + tokens.space.xs);
}

class _LandingDelegate extends SliverPersistentHeaderDelegate {
  _LandingDelegate({
    required this.title,
    required this.eyebrow,
    required this.art,
    required this.titleMark,
    required this.toolbarMark,
    required this.leading,
    required this.actions,
    required this.minHeight,
    required this.maxHeight,
    required this.gutter,
    required this.artWidth,
    required this.artReserve,
    required this.titleStyle,
    required this.eyebrowStyle,
    required this.tokens,
    required this.scaler,
  });

  final String title;
  final String? eyebrow;
  final HeaderArtBuilder? art;
  final Widget? titleMark;
  final Widget? toolbarMark;
  final Widget? leading;
  final List<Widget> actions;
  final double minHeight;
  final double maxHeight;
  final double gutter;
  final double artWidth;
  final double artReserve;
  final TextStyle titleStyle;
  final TextStyle eyebrowStyle;
  final HudaTokens tokens;
  final TextScaler scaler;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final range = maxHeight - minHeight;
    final t = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final height = math.max(minHeight, maxHeight - shrinkOffset);
    final art = this.art;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final startInset = rtl ? media.padding.right : media.padding.left;
    final endInset = rtl ? media.padding.left : media.padding.right;
    final artTop = media.padding.top + kToolbarHeight - 4;
    final artHeight = maxHeight - artTop;
    final onChromeArt = OrnamentStyle.of(context, onChrome: true);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: HudaSystemUi.over(top: Brightness.dark, bottom: theme.brightness),
      child: ClipRect(
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(gradient: tokens.bandGradient),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.35,
                  child: Ornament(
                    painter: StarFieldPainter(
                      style: onChromeArt.copyWith(
                        color: tokens.gilt.withValues(alpha: 0.5),
                        stroke: tokens.stroke.hairline,
                        render: OrnamentRender.line,
                      ),
                      module: 44,
                      fade: AlignmentDirectional.centerStart.resolve(
                        Directionality.of(context),
                      ),
                    ),
                  ),
                ),
              ),
              if (art != null && artWidth > 0 && artHeight > 0)
                PositionedDirectional(
                  end: gutter * 0.5 + endInset,
                  top: artTop,
                  width: artWidth,
                  height: artHeight + 8,
                  child: Opacity(
                    opacity: (1 - t * 1.4).clamp(0.0, 1.0),
                    child: Ornament(painter: art(onChromeArt)),
                  ),
                ),
              if (maxHeight > minHeight)
                PositionedDirectional(
                  start: gutter + startInset,
                  end: gutter + endInset + artReserve,
                  bottom: tokens.space.xl,
                  child: Opacity(
                    opacity: (1 - t * 1.8).clamp(0.0, 1.0),
                    child: MediaQuery(
                      data: media.copyWith(textScaler: scaler),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (eyebrow != null) ...[
                            Text(
                              eyebrow!.toUpperCase(),
                              style: eyebrowStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: tokens.space.xxs),
                          ],
                          Semantics(
                            header: true,
                            label: titleMark == null ? null : title,
                            child:
                                titleMark ??
                                Text(
                                  title,
                                  style: titleStyle,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: math.min(height, minHeight),
                child: SafeArea(
                  bottom: false,
                  child: IconTheme.merge(
                    data: IconThemeData(color: tokens.onChrome),
                    child: NavigationToolbar(
                      leading: leading,
                      middle: Opacity(
                        opacity: maxHeight > minHeight
                            ? ((t - 0.6) / 0.4).clamp(0.0, 1.0)
                            : 1,
                        child: toolbarMark != null
                            ? Semantics(label: title, child: toolbarMark)
                            : MediaQuery(
                                data: media.copyWith(textScaler: scaler),
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: tokens.onChrome,
                                  ),
                                ),
                              ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions,
                      ),
                      centerMiddle: false,
                      middleSpacing: leading == null ? gutter : 4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_LandingDelegate old) =>
      old.title != title ||
      old.eyebrow != eyebrow ||
      old.art != art ||
      old.titleMark != titleMark ||
      old.toolbarMark != toolbarMark ||
      old.minHeight != minHeight ||
      old.maxHeight != maxHeight ||
      old.gutter != gutter ||
      old.artWidth != artWidth ||
      old.tokens != tokens ||
      old.titleStyle != titleStyle ||
      old.scaler != scaler;
}
