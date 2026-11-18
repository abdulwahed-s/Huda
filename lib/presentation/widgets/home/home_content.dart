import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/home_customization/home_customization_cubit.dart';
import 'package:huda/cubit/home_customization/home_customization_state.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:huda/presentation/widgets/home/home_actions.dart';
import 'package:huda/presentation/widgets/home/home_gallery.dart';
import 'package:huda/presentation/widgets/home/home_identity.dart';
import 'package:huda/presentation/widgets/home/themes/classic_home.dart';
import 'package:huda/presentation/widgets/home/themes/prayer_today_home.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey_home.dart';

/// Home in the person's chosen style. Each style has its own page: Classic
/// on the landing tier (Huda's logo in the band, the gallery below), Path
/// of Prayer on the sky (immersive, edge to edge), Quran Journey on a
/// paper page (the standard tier) that opens like a surah. Home's editor
/// lives in Settings. Content caps at [maxContentWidth] and centers.
class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.actions});

  final HomeActions actions;

  static const maxContentWidth = 1200.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCustomizationCubit, HomeCustomizationState>(
      buildWhen: (a, b) =>
          a.runtimeType != b.runtimeType ||
          (a is HomeCustomizationReady &&
              b is HomeCustomizationReady &&
              a.preferences != b.preferences),
      builder: (context, state) {
        final preferences = switch (state) {
          HomeCustomizationReady(:final preferences) => preferences,
          // The saved layout can't be read: the default one, rather than a
          // skeleton that never ends.
          HomeCustomizationError() => HomePreferences.defaults(),
          _ => null,
        };
        if (preferences == null) {
          return const HomeLanding(body: HomeSkeleton());
        }
        final theme = preferences.selectedTheme;
        final configuration = preferences.configurationFor(theme);
        final catalog = HomeFeatureCatalog.available(
          context,
          HomeFeatureActions(openQuran: actions.openQuran, openQuranKit: () {}),
        );
        final byId = {for (final feature in catalog) feature.id: feature};
        List<HomeFeatureDefinition> of(List<HomeFeatureId> ids) => [
          for (final id in ids)
            if (byId[id] != null) byId[id]!,
        ];
        final tools = of(configuration.primaryFeatures);
        final more = of(configuration.viewMoreFeatures);
        final page = switch (theme) {
          HomeThemeId.classic => ClassicHome(
            tools: tools,
            more: more,
            actions: actions,
          ),
          HomeThemeId.prayerToday => PrayerTodayHome(
            // The Quran always first; Prayer Times is the dial above.
            tools: [?byId[HomeFeatureId.quranKit], ...tools],
            more: more,
            actions: actions,
          ),
          HomeThemeId.quranJourney => QuranJourneyHome(
            configuration: configuration,
            tools: tools,
            more: more,
            actions: actions,
          ),
        };
        return KeyedSubtree(key: ValueKey(theme), child: page);
      },
    );
  }
}

/// Classic's page: the landing tier with Huda's logo in gilt as its name,
/// then [body]. On a tabletop, [tabletop]'s top sits above
/// the band with the header and its bottom below.
class HomeLanding extends StatelessWidget {
  const HomeLanding({super.key, required this.body, this.tabletop});

  final Widget body;
  final ({Widget top, Widget bottom})? tabletop;

  @override
  Widget build(BuildContext context) {
    final tabletop = this.tabletop;
    if (tabletop != null && homeSplitsAtFold(context)) {
      return TabletopSplit(
        top: _scaffold(context, tabletop.top),
        bottom: CustomScrollView(
          slivers: [homePageSliver(context, tabletop.bottom)],
        ),
      );
    }
    return _scaffold(context, body);
  }

  Widget _scaffold(BuildContext context, Widget body) => HudaLandingScaffold(
    // Huda's logo is Home's name: in gilt where a title would be (no word
    // beside it), small in the toolbar once the band collapses.
    title: AppLocalizations.of(context)!.huda,
    titleMark: const Align(
      alignment: AlignmentDirectional.centerStart,
      child: HomeLogo(height: _logoHeight),
    ),
    titleMarkHeight: _logoHeight,
    toolbarMark: const Align(
      alignment: AlignmentDirectional.centerStart,
      child: HomeLogo(height: 22),
    ),
    contentMaxWidth: HomeView.maxContentWidth,
    slivers: [homePageSliver(context, body)],
  );

  static const _logoHeight = 46.0;
}

/// Whether Home splits above and below a horizontal fold: half open on a
/// table, or two screens one above the other (the Duo held upright, whose
/// hinge would cut through whatever lies across it).
bool homeSplitsAtFold(BuildContext context) {
  final fold = FoldInfo.of(context);
  return TabletopSplit.applies(context) ||
      (fold.separatorAxis == Axis.horizontal && fold.avoided);
}

/// [body] between the page's gutters, capped and centered, ending above
/// the system bar.
Widget homePageSliver(BuildContext context, Widget body) {
  final width = MediaQuery.sizeOf(context).width;
  final space = context.tokens.space;
  final gutter = space.gutter(width);
  return SliverPadding(
    padding: context.scrollPadding(
      EdgeInsets.fromLTRB(gutter, space.lg, gutter, space.xxl),
    ),
    sliver: SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: HomeView.maxContentWidth),
          child: body,
        ),
      ),
    ),
  );
}

/// The gap between Home's blocks.
double homeBlockGap(BuildContext context) {
  final space = context.tokens.space;
  return context.windowClass.isCompact ? space.lg : space.xl;
}

/// Blocks stacked with Home's gap.
class HomeColumn extends StatelessWidget {
  const HomeColumn({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final gap = homeBlockGap(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          children[i],
        ],
      ],
    );
  }
}

/// The dashboard: the style's day ([start]) beside its tools ([end]). Split
/// exactly at a vertical fold (nothing on a half-open band), otherwise
/// about 40% for the day. Each pane sees no fold. Assumes it's centered
/// in the window, as Home's content is.
class HomePanes extends StatelessWidget {
  const HomePanes({
    super.key,
    required this.start,
    required this.end,
    this.even = false,
  });

  final Widget start;
  final Widget end;

  /// Two equal halves (a book's spread) instead of about 40% for [start].
  final bool even;

  /// Whether the window gets the dashboard: with a vertical fold (the Duo
  /// and Fold open, flat or as a book: the halves are the panes), on short
  /// windows from medium (phone landscape, the Duo closed sideways), and on
  /// expanded windows wider than they're tall. Tall tablets keep one
  /// column, the day above the tools, so the page isn't half empty.
  static bool applies(BuildContext context) {
    final window = context.windowClass;
    final size = MediaQuery.sizeOf(context);
    if (FoldInfo.of(context).splitsHorizontally) return true;
    if (window.width >= WindowWidthClass.medium && window.isCompactHeight) {
      return true;
    }
    return window.width >= WindowWidthClass.expanded &&
        size.width > size.height;
  }

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final fold = FoldInfo.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final double gap;
        final double startWidth;
        if (fold.splitsHorizontally) {
          gap = (fold.end - fold.start) + space.xxl;
          startWidth = (width - gap) / 2;
        } else if (even) {
          gap = space.huge;
          startWidth = (width - gap) / 2;
        } else {
          gap = space.xxl;
          startWidth = (width * 0.42).clamp(300.0, 520.0);
        }
        Widget pane(Widget child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(displayFeatures: const []),
          child: child,
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: startWidth, child: pane(start)),
            SizedBox(width: gap),
            Expanded(child: pane(end)),
          ],
        );
      },
    );
  }
}

/// While Home's layout loads: plates and a hero, shaped like Home.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return HudaSkeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HudaSkeletonBlock(height: 120),
          SizedBox(height: space.xl),
          HomeGrid(
            spansFold: false,
            tiles: [
              for (var i = 0; i < 8; i++)
                Column(
                  children: [
                    const AspectRatio(
                      aspectRatio: 1,
                      child: HudaSkeletonBlock(height: double.infinity),
                    ),
                    SizedBox(height: space.xs),
                    const HudaSkeletonBlock(width: 48, height: 12),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
