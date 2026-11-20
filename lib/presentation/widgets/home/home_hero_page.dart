import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_system_ui.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/home/home_content.dart';

class HomeHeroPage extends StatefulWidget {
  const HomeHeroPage({super.key, required this.hero, required this.page});

  final Widget Function(BuildContext context, bool fill) hero;

  final Widget Function(BuildContext context, bool spansFold) page;

  @override
  State<HomeHeroPage> createState() => _HomeHeroPageState();
}

class _HomeHeroPageState extends State<HomeHeroPage> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final fold = FoldInfo.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final page = Theme.of(context).brightness;
    final Widget body;
    if (homeSplitsAtFold(context)) {
      body = TabletopSplit(
        top: widget.hero(context, true),
        bottom: CustomScrollView(
          slivers: [homePageSliver(context, widget.page(context, false))],
        ),
      );
    } else if (!context.windowClass.isCompact || fold.splitsHorizontally) {
      final width = media.size.width;
      final heroWidth = fold.splitsHorizontally
          ? (rtl ? width - fold.end : fold.start)
          : (width * 0.48).clamp(340.0, 820.0);
      final gap = fold.splitsHorizontally ? fold.end - fold.start : 0.0;
      body = Row(
        children: [
          SizedBox(
            width: heroWidth,
            child: MediaQuery(
              data: media.copyWith(
                size: Size(heroWidth, media.size.height),
                padding: rtl
                    ? media.padding.copyWith(left: 0)
                    : media.padding.copyWith(right: 0),
              ),
              child: widget.hero(context, true),
            ),
          ),
          if (gap > 0) SizedBox(width: gap),
          Expanded(
            child: Column(
              children: [
                if (media.padding.top > 0)
                  Container(
                    height: media.padding.top,
                    decoration: BoxDecoration(
                      gradient: context.tokens.chromeGradient,
                    ),
                  ),
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    removeLeft: !rtl,
                    removeRight: rtl,
                    child: LayoutBuilder(
                      builder: (context, box) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: box.maxHeight),
                          child: Center(
                            child: Padding(
                              padding: context.scrollPadding(
                                EdgeInsets.all(
                                  context.tokens.space.gutter(width),
                                ),
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 560,
                                ),
                                child: widget.page(context, false),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      body = Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(child: widget.hero(context, false)),
              homePageSliver(context, widget.page(context, true)),
            ],
          ),
          _StatusVeil(scroll: _scroll),
        ],
      );
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: HudaSystemUi.over(top: Brightness.dark, bottom: page),
      child: Scaffold(body: body),
    );
  }
}

class HomeHero extends StatelessWidget {
  const HomeHero({
    super.key,
    required this.fill,
    required this.builder,
    this.reserve = 170,
    this.warm = true,
  });

  final bool fill;
  final double reserve;
  final bool warm;
  final Widget Function(BuildContext context, double centerpiece) builder;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final media = MediaQuery.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final gutter = space.gutter(media.size.width);
    final padding = EdgeInsetsDirectional.fromSTEB(
      gutter + (rtl ? media.padding.right : media.padding.left),
      media.padding.top + space.md,
      gutter + (rtl ? media.padding.left : media.padding.right),
      space.xl + (fill ? media.padding.bottom : 0),
    );
    final Widget body;
    if (fill) {
      body = LayoutBuilder(
        builder: (context, box) {
          final scale = media.textScaler.scale(1).clamp(1.0, 2.0);
          final room = box.maxHeight - padding.vertical - reserve * scale;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: Padding(
                padding: padding,
                child: Center(child: builder(context, math.max(200, room))),
              ),
            ),
          );
        },
      );
    } else {
      body = Padding(
        padding: padding,
        child: builder(context, double.infinity),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(gradient: tokens.bandGradient),
      child: Stack(
        fit: fill ? StackFit.expand : StackFit.loose,
        children: [
          Positioned.fill(child: HomeHeroBackdrop(warm: warm)),
          body,
        ],
      ),
    );
  }
}

class HomeHeroBackdrop extends StatelessWidget {
  const HomeHeroBackdrop({super.key, this.warm = true});

  final bool warm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: 0.3,
          child: Ornament(
            painter: StarFieldPainter(
              style: OrnamentStyle(
                color: tokens.gilt.withValues(alpha: 0.5),
                render: OrnamentRender.line,
                stroke: tokens.stroke.hairline,
              ),
              module: 44,
              fade: Alignment.bottomCenter,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.1),
              radius: 0.8,
              colors: [
                (warm ? tokens.gilt : tokens.onChrome).withValues(
                  alpha: warm ? 0.16 : 0.08,
                ),
                tokens.gilt.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusVeil extends StatelessWidget {
  const _StatusVeil({required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    if (top <= 0) return const SizedBox.shrink();
    final chrome = context.tokens.chrome;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: top,
      child: IgnorePointer(
        child: ListenableBuilder(
          listenable: scroll,
          builder: (context, _) {
            final offset = scroll.hasClients ? scroll.offset : 0.0;
            final t = (offset / 24).clamp(0.0, 1.0);
            return ColoredBox(color: chrome.withValues(alpha: chrome.a * t));
          },
        ),
      ),
    );
  }
}
