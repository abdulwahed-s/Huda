import 'package:flutter/material.dart';

import 'package:huda/core/theme/huda_theme_scope.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/radio_station_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/quran_player/player_bar_widget.dart';
import 'package:huda/presentation/widgets/quran_player/quran_audio_identity.dart';

enum RadioStatus { connecting, live, paused }

class RadioStationTile extends StatelessWidget {
  const RadioStationTile({
    super.key,
    required this.station,
    required this.status,
    required this.onTap,
  });

  final RadioStation station;

  final RadioStatus? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final motion = tokens.motion;
    final status = this.status;
    final on = status != null;

    final Widget mark = switch (status) {
      RadioStatus.connecting => const HudaLampSpinner(
        key: ValueKey('busy'),
        size: 22,
      ),
      RadioStatus.live || RadioStatus.paused => QuranVoiceGlyph(
        key: const ValueKey('voice'),
        playing: status == RadioStatus.live,
      ),
      null => Icon(
        Icons.radio_rounded,
        key: const ValueKey('radio'),
        color: scheme.onSurfaceVariant,
      ),
    };

    return Semantics(
      button: true,
      selected: on,
      child: AnimatedContainer(
        duration: motion.of(context, motion.medium),
        curve: motion.standard,
        decoration: BoxDecoration(
          color: on
              ? scheme.primary.withValues(alpha: 0.08)
              : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(tokens.radius.md),
          border: Border.all(
            color: on
                ? scheme.primary.withValues(alpha: 0.5)
                : scheme.outlineVariant,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(tokens.radius.md),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  space.xs,
                  space.sm,
                  space.md,
                  space.sm,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: motion.of(context, motion.short),
                          child: mark,
                        ),
                      ),
                    ),
                    SizedBox(width: space.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            station.name.toString(),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: on ? scheme.primary : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (status != null)
                            Text(
                              radioStatusLabel(l10n, status),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      status == RadioStatus.live
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: on ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String radioStatusLabel(AppLocalizations l10n, RadioStatus status) =>
    switch (status) {
      RadioStatus.connecting => l10n.radioConnecting,
      RadioStatus.live => l10n.radioLive,
      RadioStatus.paused => l10n.radioPaused,
    };

class RadioBar extends StatelessWidget {
  const RadioBar({
    super.key,
    required this.station,
    required this.status,
    required this.onPlayPause,
    required this.onStop,
  });

  final RadioStation station;
  final RadioStatus status;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return HudaNight(child: Builder(builder: _build));
  }

  Widget _build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final insets = MediaQuery.paddingOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Material(
      key: const ValueKey('radio-bar'),
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 3,
            color: status == RadioStatus.live
                ? tokens.gilt
                : tokens.onChromeMuted.withValues(alpha: 0.18),
          ),
          SizedBox(height: space.xxs),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              space.sm + (rtl ? insets.right : insets.left),
              0,
              space.xs + (rtl ? insets.left : insets.right),
              space.xs + insets.bottom,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Center(
                      child: status == RadioStatus.connecting
                          ? HudaLampSpinner(size: 20, color: tokens.gilt)
                          : QuranVoiceGlyph(
                              playing: status == RadioStatus.live,
                              color: tokens.gilt,
                            ),
                    ),
                  ),
                  SizedBox(width: space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HudaEyebrow(
                          radioStatusLabel(l10n, status),
                          color: tokens.gilt,
                        ),
                        Text(
                          station.name.toString(),
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: space.xs),
                  QuranPlayButton(
                    playing: status == RadioStatus.live,
                    busy: status == RadioStatus.connecting,
                    onPressed: onPlayPause,
                  ),
                  IconButton(
                    tooltip: l10n.stop,
                    onPressed: onStop,
                    icon: const Icon(Icons.stop_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RadioStationSkeleton extends StatelessWidget {
  const RadioStationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: EdgeInsets.all(tokens.space.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.radius.md),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: HudaSkeleton(
        announce: false,
        child: Row(
          children: [
            const HudaSkeletonBlock(width: 24, height: 24, circle: true),
            SizedBox(width: tokens.space.md),
            Expanded(
              child: HudaSkeletonLines(
                lines: 1,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
