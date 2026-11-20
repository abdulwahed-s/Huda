import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_system_ui.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:huda/presentation/widgets/home/home_actions.dart';
import 'package:huda/presentation/widgets/home/home_content.dart';
import 'package:huda/presentation/widgets/home/home_event.dart';
import 'package:huda/presentation/widgets/home/home_gallery.dart';
import 'package:huda/presentation/widgets/home/home_identity.dart';
import 'package:huda/presentation/widgets/home/home_reading.dart';

class QuranJourneyHome extends StatelessWidget {
  const QuranJourneyHome({
    super.key,
    required this.configuration,
    required this.tools,
    required this.more,
    required this.actions,
  });

  final HomeThemeConfiguration configuration;
  final List<HomeFeatureDefinition> tools;
  final List<HomeFeatureDefinition> more;
  final HomeActions actions;

  @override
  Widget build(BuildContext context) {
    final page = Theme.of(context).brightness;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: HudaSystemUi.over(top: page, bottom: page),
      child: Scaffold(
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) => _page(context, state),
        ),
      ),
    );
  }

  Widget _page(BuildContext context, HomeState state) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final gap = homeBlockGap(context);
    final split = homeSplitsAtFold(context);
    final panes = !split && HomePanes.applies(context);
    final short = context.windowClass.isCompactHeight;
    final roomy = !short && (panes || !context.windowClass.isCompact);
    final logo = Center(
      child: Semantics(
        header: true,
        label: l10n.huda,
        child: const HomeLogo(height: 26, ink: true),
      ),
    );

    Widget reading;
    final sections = <Widget>[];
    if (state is HomeLoaded) {
      final place = homeReadingPlace(
        l10n,
        summary: state.hasLastReadPosition ? state.lastReadSummary : null,
        khatma: state.khatma,
        actions: actions,
      );
      final khatma = configuration.orderedSections.contains(
        HomeSectionId.khatmaProgress,
      );
      reading = HomeContinueCard(
        place: place,
        attachment: khatma
            ? HomeKhatmaRibbon(
                khatma: state.khatma,
                actions: actions,
                showStart: !place.fromKhatma,
                attached: true,
              )
            : null,
      );
      for (final section in configuration.orderedSections) {
        switch (section) {
          case HomeSectionId.dailyAyah:
            sections.add(
              HomeAyahCard(
                ayah: state.dailyAyah,
                actions: actions,
                large: roomy,
                lines: panes && !short ? 4 : 3,
              ),
            );
          default:
            break;
        }
      }
    } else if (state is HomeError) {
      reading = HudaStatusBanner(
        key: const ValueKey('quran-journey-error'),
        status: HudaStatus.failed,
        message: l10n.unexpectedError,
        onRetry: actions.retry,
      );
    } else {
      reading = const _ReadingSkeleton();
    }
    reading = HudaStateSwitcher(stateKey: state.runtimeType, child: reading);

    final event = HomeEventCard(padding: EdgeInsets.only(bottom: gap));
    final listened =
        state is HomeLoaded &&
        (state.hasLastQuranAudio || state.hasLastRadioStation);
    final listening = [
      if (listened)
        HomeContinueRows(
          actions: actions,
          showReading: false,
          eyebrow: l10n.continueListening,
          hideWhenEmpty: true,
        ),
    ];
    Widget gallery({required bool spansFold}) => HomeGallery(
      key: const ValueKey('home-tools'),
      lead: homeQuranToolTiles(context, actions),
      tools: tools,
      more: more,
      actions: actions,
      medallions: true,
      spansFold: spansFold,
    );
    Widget column(List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
    Widget scroll(Widget child) => CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          sliver: homePageSliver(context, child),
        ),
      ],
    );

    if (split) {
      return TabletopSplit(
        top: scroll(
          column([
            logo,
            SizedBox(height: space.lg),
            HomeColumn(children: [reading, ...sections.take(1)]),
          ]),
        ),
        bottom: scroll(
          column([
            event,
            HomeColumn(
              children: [
                ...sections.skip(1),
                gallery(spansFold: false),
                ...listening,
              ],
            ),
          ]),
        ),
      );
    }
    if (panes) {
      return scroll(
        KeyedSubtree(
          key: const ValueKey('quran-journey-root'),
          child: HomePanes(
            start: column([
              logo,
              SizedBox(height: space.lg),
              reading,
              SizedBox(height: gap),
              event,
              HomeColumn(children: sections),
            ]),
            end: HomeColumn(
              children: [gallery(spansFold: false), ...listening],
            ),
          ),
        ),
      );
    }
    return scroll(
      KeyedSubtree(
        key: const ValueKey('quran-journey-root'),
        child: column([
          logo,
          SizedBox(height: space.lg),
          reading,
          SizedBox(height: gap),
          event,
          HomeColumn(
            children: [
              ...sections.take(1),
              gallery(spansFold: true),
              ...sections.skip(1),
              ...listening,
            ],
          ),
        ]),
      ),
    );
  }
}

class _ReadingSkeleton extends StatelessWidget {
  const _ReadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return HudaSkeleton(
      child: Column(
        key: const ValueKey('quran-journey-loading'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const HudaSkeletonBlock(height: 104),
          SizedBox(height: space.lg),
          const HudaSkeletonBlock(height: 168),
        ],
      ),
    );
  }
}
