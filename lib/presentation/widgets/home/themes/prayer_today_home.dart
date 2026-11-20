import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:huda/presentation/widgets/home/home_actions.dart';
import 'package:huda/presentation/widgets/home/home_content.dart';
import 'package:huda/presentation/widgets/home/home_event.dart';
import 'package:huda/presentation/widgets/home/home_gallery.dart';
import 'package:huda/presentation/widgets/home/home_hero_page.dart';
import 'package:huda/presentation/widgets/home/home_identity.dart';
import 'package:huda/presentation/widgets/home/home_prayer_dial.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_identity.dart';

class PrayerTodayHome extends StatelessWidget {
  const PrayerTodayHome({
    super.key,
    required this.tools,
    required this.more,
    required this.actions,
  });

  final List<HomeFeatureDefinition> tools;
  final List<HomeFeatureDefinition> more;
  final HomeActions actions;

  @override
  Widget build(BuildContext context) {
    return HomeHeroPage(
      hero: (context, fill) => _DialHero(actions: actions, fill: fill),
      page: (context, spansFold) => Column(
        key: const ValueKey('prayer-today-root'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          HomeEventCard(
            padding: EdgeInsets.only(bottom: homeBlockGap(context)),
          ),
          HomeGallery(
            key: const ValueKey('home-tools'),
            tools: tools,
            more: more,
            actions: actions,
            medallions: true,
            showPrayerLine: false,
            spansFold: spansFold,
          ),
        ],
      ),
    );
  }
}

class _DialHero extends StatelessWidget {
  const _DialHero({required this.actions, required this.fill});

  final HomeActions actions;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      buildWhen: (a, b) => a.runtimeType != b.runtimeType,
      builder: (context, state) {
        final day = state is PrayerTimesLoaded
            ? HomePrayerDay.of(context, state)
            : null;
        return HomeHero(
          key: const ValueKey('home-prayer-sky'),
          fill: fill,
          warm: day?.daytime ?? true,
          builder: (context, dialMaxHeight) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                label: l10n.huda,
                child: const HomeLogo(height: 26),
              ),
              SizedBox(height: space.lg),
              BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
                builder: (context, state) {
                  if (state is! PrayerTimesLoaded) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: EdgeInsets.only(bottom: space.xs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: tokens.onChromeMuted,
                        ),
                        SizedBox(width: space.xxs),
                        Flexible(
                          child: Text(
                            prayerPlaceName(l10n, state),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: tokens.onChromeMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              HomePrayerDial(actions: actions, maxHeight: dialMaxHeight),
              SizedBox(height: space.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: const HomePrayerTimesRow(),
              ),
            ],
          ),
        );
      },
    );
  }
}
