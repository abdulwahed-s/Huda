import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/islamic_event/islamic_event_cubit.dart';
import 'package:huda/data/models/islamic_event_config.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/home/home_actions.dart';
import 'package:huda/presentation/widgets/home/home_event_scene.dart';

class HomeEventCard extends StatelessWidget {
  const HomeEventCard({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IslamicEventCubit, IslamicEventState>(
      builder: (context, state) {
        final event = switch (state) {
          IslamicEventActive(:final event) => event,
          _ => HomeSpecialEventPreview.selectedFixture,
        };
        return HudaStateSwitcher(
          stateKey: event?.eventKey ?? 'none',
          alignment: Alignment.topCenter,
          child: event == null
              ? const SizedBox(
                  key: ValueKey('no-active-islamic-event'),
                  width: double.infinity,
                )
              : Padding(
                  key: ValueKey('home-event-${event.eventKey}'),
                  padding: padding,
                  child: HomeEventBanner(event: event),
                ),
        );
      },
    );
  }
}

class HomeEventReveal extends StatefulWidget {
  const HomeEventReveal({
    super.key,
    required this.eventKey,
    required this.builder,
  });

  final String eventKey;
  final Widget Function(BuildContext context, Animation<double> reveal) builder;

  static const duration = Duration(milliseconds: 1600);
  static final _seen = <String>{};

  @override
  State<HomeEventReveal> createState() => _HomeEventRevealState();
}

class _HomeEventRevealState extends State<HomeEventReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: HomeEventReveal.duration,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final seen = !HomeEventReveal._seen.add(widget.eventKey);
    if (seen || MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

class HomeEventScene extends StatelessWidget {
  const HomeEventScene({
    super.key,
    required this.eventKey,
    this.stage = HomeEventStage.end,
    this.revealKey,
  });

  final String eventKey;
  final HomeEventStage stage;

  final String? revealKey;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return RepaintBoundary(
      child: HomeEventReveal(
        eventKey: revealKey ?? eventKey,
        builder: (context, reveal) => CustomPaint(
          painter: HomeEventScenePainter(
            eventKey: eventKey,
            palette: HomeEventPalette.of(context),
            rtl: rtl,
            stage: stage,
            reveal: reveal,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class HomeEventBanner extends StatelessWidget {
  const HomeEventBanner({super.key, required this.event});

  final IslamicEventConfig event;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final title = homeEventTitle(l10n, event.eventKey);
    final subtitle = homeEventSubtitle(l10n, event.eventKey);
    final radius = BorderRadius.circular(tokens.radius.xl);
    final scale = media.textScaler.scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final short = media.size.height < 480;
        final wide = width >= 600 && !short;
        final pad = wide ? space.xl : space.lg;
        final band = scale > 1.35 || width < 300;
        Widget words(double room) => SizedBox(
          width: room,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style:
                    (wide
                            ? theme.textTheme.headlineMedium
                            : theme.textTheme.headlineSmall)
                        ?.copyWith(color: tokens.onChrome, height: 1.15),
              ),
              SizedBox(height: space.xs),
              Container(
                width: 28,
                height: 1.5,
                decoration: BoxDecoration(
                  color: tokens.gilt,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              SizedBox(height: space.xs),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.onChromeMuted,
                ),
              ),
            ],
          ),
        );
        final Widget body;
        if (band) {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    HomeEventScene(
                      eventKey: event.eventKey,
                      stage: HomeEventStage.center,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            tokens.chrome.withValues(alpha: 0),
                            tokens.chrome,
                          ],
                          stops: const [0.55, 1],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(pad),
                child: words(width - pad * 2),
              ),
            ],
          );
        } else {
          final stage = HomeEventScenePainter.endStageWidth(width);
          var room = width - stage - pad - space.xs;
          final fold = FoldInfo.of(context);
          if (fold.splitsHorizontally) {
            final left = (media.size.width - width) / 2;
            final before = rtl ? left + width - fold.end : fold.start - left;
            if (before > 0 && before < width) {
              room = math.min(room, before - pad * 2);
            }
          }
          final clear = ((width - stage) / width).clamp(0.0, 1.0);
          body = ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: short ? 132 : (wide ? 184 : 164),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: HomeEventScene(eventKey: event.eventKey),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: AlignmentDirectional.centerStart,
                        end: AlignmentDirectional.centerEnd,
                        colors: [
                          tokens.chrome.withValues(alpha: 0.7),
                          tokens.chrome.withValues(alpha: 0.4),
                          tokens.chrome.withValues(alpha: 0),
                        ],
                        stops: [0, clear * 0.75, clear],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(pad, pad, 0, pad),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: words(math.max(120, room)),
                  ),
                ),
              ],
            ),
          );
        }
        return Semantics(
          button: true,
          label: '$title. $subtitle',
          excludeSemantics: true,
          child: HudaPressable(
            child: Material(
              color: tokens.chrome,
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(color: tokens.gilt.withValues(alpha: 0.3)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const ValueKey('special-event-card-action'),
                onTap: () => showHomeEventSheet(context, event),
                splashColor: tokens.gilt.withValues(alpha: 0.12),
                highlightColor: tokens.gilt.withValues(alpha: 0.06),
                child: Stack(
                  children: [
                    body,
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                tokens.radius.xl - 5,
                              ),
                              border: Border.all(
                                color: tokens.gilt.withValues(alpha: 0.22),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

final _openSheets = <NavigatorState, bool>{};

Future<void> showHomeEventSheet(
  BuildContext context,
  IslamicEventConfig event,
) async {
  final navigator = Navigator.of(context);
  if (_openSheets[navigator] ?? false) return;
  _openSheets[navigator] = true;
  final l10n = AppLocalizations.of(context)!;
  try {
    await showHudaSheet<void>(
      context: context,
      title: homeEventTitle(l10n, event.eventKey),
      maxDialogWidth: 600,
      builder: (context) => HomeEventSheetBody(eventKey: event.eventKey),
    );
  } finally {
    _openSheets[navigator] = false;
  }
}

class HomeEventSheetBody extends StatelessWidget {
  const HomeEventSheetBody({super.key, required this.eventKey});

  final String eventKey;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final content = HomeEventContent.of(l10n, eventKey);
    Widget rule() => Row(
      children: [
        Expanded(child: Divider(color: tokens.ornament.withValues(alpha: 0.5))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: space.sm),
          child: Icon(
            Icons.star_rate_rounded,
            size: 14,
            color: tokens.ornament,
          ),
        ),
        Expanded(child: Divider(color: tokens.ornament.withValues(alpha: 0.5))),
      ],
    );
    return Column(
      key: const ValueKey('special-event-dialog'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radius.lg),
          child: SizedBox(
            height: 168,
            child: HomeEventScene(
              eventKey: eventKey,
              stage: HomeEventStage.center,
              revealKey: 'sheet-$eventKey',
            ),
          ),
        ),
        SizedBox(height: space.lg),
        Text(
          homeEventSubtitle(l10n, eventKey),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (content.arabicText.isNotEmpty) ...[
          SizedBox(height: space.lg),
          rule(),
          SizedBox(height: space.md),
          Text(
            content.arabicText,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: context.type.hadith,
          ),
          SizedBox(height: space.sm),
          Text(
            content.translation,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          SizedBox(height: space.xs),
          Text(
            content.source,
            textAlign: TextAlign.center,
            style: context.type.eyebrow.copyWith(color: tokens.ornament),
          ),
          SizedBox(height: space.md),
          rule(),
        ],
        SizedBox(height: space.lg),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: tokens.radius.control,
            border: BorderDirectional(
              start: BorderSide(color: tokens.gilt, width: 3),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(space.md),
            child: Text(content.guidance, style: theme.textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}

String homeEventTitle(AppLocalizations l10n, String eventKey) =>
    switch (eventKey) {
      'ramadan' => l10n.eventRamadan,
      'last_ten_ramadan' => l10n.eventLastTenRamadan,
      'eid_al_fitr' => l10n.eventEidAlFitr,
      'eid_al_adha' => l10n.eventEidAlAdha,
      'day_of_arafah' => l10n.eventDayOfArafah,
      'first_ten_dhul_hijjah' => l10n.eventFirstTenDhulHijjah,
      'ashura' => l10n.eventAshura,
      'days_of_tashreeq' => l10n.eventDaysTashreeq,
      'white_days_fasting' => l10n.eventWhiteDaysFasting,
      'monday_thursday_fasting' => l10n.eventMondayThursdayFasting,
      'white_days_monday_thursday_fasting' =>
        l10n.eventWhiteDaysMondayThursdayFasting,
      _ => l10n.eventSpecialOccasion,
    };

String homeEventSubtitle(AppLocalizations l10n, String eventKey) =>
    switch (eventKey) {
      'ramadan' => l10n.eventRamadanSubtitle,
      'last_ten_ramadan' => l10n.eventLastTenRamadanSubtitle,
      'eid_al_fitr' => l10n.eventEidAlFitrSubtitle,
      'eid_al_adha' => l10n.eventEidAlAdhaSubtitle,
      'day_of_arafah' => l10n.eventDayOfArafahSubtitle,
      'first_ten_dhul_hijjah' => l10n.eventFirstTenDhulHijjahSubtitle,
      'ashura' => l10n.eventAshuraSubtitle,
      'days_of_tashreeq' => l10n.eventDaysTashreeqSubtitle,
      'white_days_fasting' => l10n.eventWhiteDaysFastingSubtitle,
      'monday_thursday_fasting' => l10n.eventMondayThursdayFastingSubtitle,
      'white_days_monday_thursday_fasting' =>
        l10n.eventWhiteDaysMondayThursdayFastingSubtitle,
      _ => l10n.eventSpecialOccasionSubtitle,
    };

class HomeEventContent {
  const HomeEventContent({
    required this.arabicText,
    required this.translation,
    required this.source,
    required this.guidance,
  });

  final String arabicText;
  final String translation;
  final String source;
  final String guidance;

  static HomeEventContent of(AppLocalizations l10n, String eventKey) {
    return switch (eventKey) {
      'ramadan' => HomeEventContent(
        arabicText: l10n.eventRamadanArabic,
        translation: l10n.eventRamadanTranslation,
        source: l10n.eventRamadanSource,
        guidance: l10n.eventRamadanGuidance,
      ),
      'last_ten_ramadan' => HomeEventContent(
        arabicText: l10n.eventLastTenRamadanArabic,
        translation: l10n.eventLastTenRamadanTranslation,
        source: l10n.eventLastTenRamadanSource,
        guidance: l10n.eventLastTenRamadanGuidance,
      ),
      'eid_al_fitr' => HomeEventContent(
        arabicText: l10n.eventEidAlFitrArabic,
        translation: l10n.eventEidAlFitrTranslation,
        source: l10n.eventEidAlFitrSource,
        guidance: l10n.eventEidAlFitrGuidance,
      ),
      'eid_al_adha' => HomeEventContent(
        arabicText: l10n.eventEidAlAdhaArabic,
        translation: l10n.eventEidAlAdhaTranslation,
        source: l10n.eventEidAlAdhaSource,
        guidance: l10n.eventEidAlAdhaGuidance,
      ),
      'day_of_arafah' => HomeEventContent(
        arabicText: l10n.eventDayOfArafahArabic,
        translation: l10n.eventDayOfArafahTranslation,
        source: l10n.eventDayOfArafahSource,
        guidance: l10n.eventDayOfArafahGuidance,
      ),
      'first_ten_dhul_hijjah' => HomeEventContent(
        arabicText: l10n.eventFirstTenDhulHijjahArabic,
        translation: l10n.eventFirstTenDhulHijjahTranslation,
        source: l10n.eventFirstTenDhulHijjahSource,
        guidance: l10n.eventFirstTenDhulHijjahGuidance,
      ),
      'ashura' => HomeEventContent(
        arabicText: l10n.eventAshuraArabic,
        translation: l10n.eventAshuraTranslation,
        source: l10n.eventAshuraSource,
        guidance: l10n.eventAshuraGuidance,
      ),
      'days_of_tashreeq' => HomeEventContent(
        arabicText: l10n.eventDaysTashreeqArabic,
        translation: l10n.eventDaysTashreeqTranslation,
        source: l10n.eventDaysTashreeqSource,
        guidance: l10n.eventDaysTashreeqGuidance,
      ),
      'white_days_fasting' => HomeEventContent(
        arabicText: l10n.eventWhiteDaysFastingArabic,
        translation: l10n.eventWhiteDaysFastingTranslation,
        source: l10n.eventWhiteDaysFastingSource,
        guidance: l10n.eventWhiteDaysFastingGuidance,
      ),
      'monday_thursday_fasting' => HomeEventContent(
        arabicText: l10n.eventMondayThursdayFastingArabic,
        translation: l10n.eventMondayThursdayFastingTranslation,
        source: l10n.eventMondayThursdayFastingSource,
        guidance: l10n.eventMondayThursdayFastingGuidance,
      ),
      'white_days_monday_thursday_fasting' => HomeEventContent(
        arabicText: l10n.eventWhiteDaysMondayThursdayFastingArabic,
        translation: l10n.eventWhiteDaysMondayThursdayFastingTranslation,
        source: l10n.eventWhiteDaysMondayThursdayFastingSource,
        guidance: l10n.eventWhiteDaysMondayThursdayFastingGuidance,
      ),
      _ => HomeEventContent(
        arabicText: '',
        translation: '',
        source: '',
        guidance: l10n.eventSpecialOccasionGuidance,
      ),
    };
  }
}
