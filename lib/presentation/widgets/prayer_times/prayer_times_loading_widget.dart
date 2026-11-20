import 'package:flutter/material.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_identity.dart';

class PrayerTimesLoadingWidget extends StatelessWidget {
  const PrayerTimesLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final gutter = space.gutter(MediaQuery.sizeOf(context).width);
    return SingleChildScrollView(
      padding: context.scrollPadding(
        EdgeInsets.fromLTRB(gutter, space.xs, gutter, space.xxl),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                label: l10n.prayerCountdownLoadingText,
                excludeSemantics: true,
                child: PrayerSkyBand(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          HudaLampSpinner(size: 20, color: tokens.gilt),
                          SizedBox(width: space.sm),
                          Expanded(
                            child: Text(
                              l10n.prayerCountdownLoadingText,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: tokens.onChrome,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: space.giant + space.xxl),
                    ],
                  ),
                ),
              ),
              SizedBox(height: space.md),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(space.md),
                  child: HudaSkeleton(
                    child: Column(
                      children: [
                        for (var i = 0; i < 6; i++) ...[
                          if (i > 0) SizedBox(height: space.md),
                          Row(
                            children: [
                              const HudaSkeletonBlock(
                                width: 28,
                                height: 28,
                                circle: true,
                              ),
                              SizedBox(width: space.sm),
                              const Expanded(
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: HudaSkeletonBlock(
                                    width: 96,
                                    height: 16,
                                  ),
                                ),
                              ),
                              const HudaSkeletonBlock(width: 64, height: 16),
                            ],
                          ),
                        ],
                      ],
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
}
