import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/data/models/home/home_dashboard_data.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/shared/home_section_widgets.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey/quran_journey_motion.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey/quran_journey_visual_style.dart';

class QuranJourneyFocus extends StatelessWidget {
  const QuranJourneyFocus({
    super.key,
    required this.configuration,
    required this.data,
    required this.actions,
    required this.isDark,
    required this.openLastReadSurah,
    this.entranceAnimation,
    this.reveal = 1,
  });

  final HomeThemeConfiguration configuration;
  final HomeLoaded data;
  final HomeDashboardActions actions;
  final bool isDark;
  final Function(Map<String, dynamic>) openLastReadSurah;
  final Animation<double>? entranceAnimation;
  final double reveal;

  @override
  Widget build(BuildContext context) {
    final anchor = _resolveAnchor(context);
    final dailyVisible = _sectionVisible(HomeSectionId.dailyAyah);
    final khatmaVisible = _sectionVisible(HomeSectionId.khatmaProgress);

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final wide = constraints.maxWidth >= 780 && scale <= 1.35;
        final readingBegin = dailyVisible ? 0.20 : 0.02;
        return Column(
          key: ValueKey(
            wide ? 'quran-journey-wide-layout' : 'quran-journey-narrow-layout',
          ),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (dailyVisible) ...[
              QuranJourneyEntranceReveal(
                key: const ValueKey('quran-daily-entrance'),
                animation: entranceAnimation,
                progress: reveal,
                begin: 0.02,
                end: 0.28,
                distance: 4,
                beginScale: 0.996,
                child: _OpeningAyah(
                  key: const ValueKey('quran-daily-ayah'),
                  ayah: data.dailyAyah,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    actions.openSurah(
                      data.dailyAyah.surahNumber,
                      data.dailyAyah.ayahNumber,
                    );
                  },
                ),
              ),
              const QuranJourneySectionBreak(
                key: ValueKey('quran-daily-reading-boundary'),
              ),
            ],
            QuranJourneyEntranceReveal(
              key: const ValueKey('quran-reading-entrance'),
              animation: entranceAnimation,
              progress: reveal,
              begin: readingBegin * 0.82,
              end: 0.57,
              distance: 7,
              beginScale: 0.986,
              child: _ReadingSpread(
                anchor: anchor,
                khatma: khatmaVisible ? data.khatma : null,
                isDark: isDark,
                wide: wide && khatmaVisible,
                onKhatmaTap: _openKhatma,
                entranceAnimation: entranceAnimation,
              ),
            ),
          ],
        );
      },
    );
  }

  bool _sectionVisible(HomeSectionId id) =>
      configuration.orderedSections.contains(id) &&
      !configuration.hiddenSections.contains(id);

  void _openKhatma() {
    HapticFeedback.selectionClick();
    final khatma = data.khatma;
    if (khatma.isActive &&
        !khatma.isCompleted &&
        khatma.startSurah != null &&
        khatma.startAyah != null) {
      actions.openSurah(khatma.startSurah!, khatma.startAyah!);
    } else {
      actions.openQuran();
    }
  }

  _ReadingAnchor _resolveAnchor(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final summary = data.lastReadSummary;
    final hasRead = data.hasLastReadPosition && summary != null;
    if (hasRead) {
      final surah = summary['surahNumber'] as int;
      final ayah = summary['ayahNumber'] as int? ?? 1;
      return _ReadingAnchor(
        eyebrow: l10n.continueHome,
        title: quran.getSurahNameLocalized(surah, locale),
        reference: l10n.ayahNumber(ayah),
        actionLabel: l10n.continueHome,
        actionIcon: Icons.menu_book_rounded,
        onTap: () {
          HapticFeedback.lightImpact();
          openLastReadSurah(summary);
        },
        hasReadingHistory: true,
      );
    }

    final khatma = data.khatma;
    if (_sectionVisible(HomeSectionId.khatmaProgress) &&
        khatma.isActive &&
        !khatma.isCompleted &&
        khatma.startSurah != null &&
        khatma.startAyah != null) {
      return _ReadingAnchor(
        eyebrow: l10n.khatmaProgress,
        title: quran.getSurahNameLocalized(khatma.startSurah!, locale),
        reference: l10n.ayahNumber(khatma.startAyah!),
        description: l10n.khatmaDayOf(
          _currentDay(khatma),
          _totalDays(khatma),
        ),
        actionLabel: l10n.continueHome,
        actionIcon: Icons.auto_stories_rounded,
        onTap: () {
          HapticFeedback.lightImpact();
          actions.openSurah(khatma.startSurah!, khatma.startAyah!);
        },
        hasReadingHistory: false,
      );
    }

    return _ReadingAnchor(
      eyebrow: l10n.themeQuranJourney,
      title: l10n.quran,
      reference: l10n.noRecentActivityHome,
      description: l10n.noRecentActivityDescription,
      actionLabel: l10n.quran,
      actionIcon: Icons.auto_stories_rounded,
      onTap: () {
        HapticFeedback.lightImpact();
        actions.openQuran();
      },
      hasReadingHistory: false,
    );
  }
}

class _ReadingAnchor {
  const _ReadingAnchor({
    required this.eyebrow,
    required this.title,
    required this.reference,
    required this.actionLabel,
    required this.actionIcon,
    required this.onTap,
    required this.hasReadingHistory,
    this.description,
  });

  final String eyebrow;
  final String title;
  final String reference;
  final String? description;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onTap;
  final bool hasReadingHistory;

  String get transitionKey =>
      '$eyebrow\u241f$title\u241f$reference\u241f${description ?? ''}';
}

class _OpeningAyah extends StatefulWidget {
  const _OpeningAyah({
    super.key,
    required this.ayah,
    required this.onTap,
  });

  final DailyAyah ayah;
  final VoidCallback onTap;

  @override
  State<_OpeningAyah> createState() => _OpeningAyahState();
}

class _OpeningAyahState extends State<_OpeningAyah> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _highlighted => _hovered || _focused || _pressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final color = context.primaryColor;
    final illumination = QuranJourneyVisualStyle.illumination(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return QuranJourneyFramedRegion(
      key: const ValueKey('quran-daily-region'),
      doubleFrame: true,
      tint: illumination,
      tonalStrength: 1.35,
      child: Semantics(
        button: true,
        onTap: widget.onTap,
        label:
            '${l10n.todaysAyah}, ${widget.ayah.text}, ${quran.getSurahNameLocalized(widget.ayah.surahNumber, locale)}, ${l10n.ayahNumber(widget.ayah.ayahNumber)}',
        child: ExcludeSemantics(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: FocusableActionDetector(
              onShowFocusHighlight: (value) {
                setState(() => _focused = value);
              },
              child: QuranJourneyPressTransform(
                pressed: _pressed,
                child: AnimatedContainer(
                  duration: reduceMotion
                      ? Duration.zero
                      : QuranJourneyMotion.interaction,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: _highlighted ? 0.045 : 0),
                    border: Border.all(
                      color: _focused
                          ? illumination.withValues(alpha: 0.72)
                          : Colors.transparent,
                      width: QuranJourneyVisualStyle.ruleWidth,
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: widget.onTap,
                      onHighlightChanged: (value) {
                        setState(() => _pressed = value);
                      },
                      overlayColor: WidgetStatePropertyAll(
                        color.withValues(alpha: 0.045),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          20,
                          25,
                          20,
                          22,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                _VerseSeal(color: illumination),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10n.todaysAyah,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: color,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 820),
                                child: QuranJourneyDataTransition(
                                  transitionKey:
                                      '${widget.ayah.surahNumber}:${widget.ayah.ayahNumber}:${widget.ayah.text}',
                                  axis: Axis.vertical,
                                  alignment: Alignment.center,
                                  child: Text(
                                    widget.ayah.text,
                                    maxLines: 7,
                                    overflow: TextOverflow.ellipsis,
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'uthmanic',
                                      fontSize: 26,
                                      height: 1.82,
                                      color: Color.lerp(
                                        Theme.of(context).colorScheme.onSurface,
                                        color,
                                        0.16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 13),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: QuranJourneyDataTransition(
                                    transitionKey:
                                        '${widget.ayah.surahNumber}:${widget.ayah.ayahNumber}',
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${quran.getSurahNameLocalized(widget.ayah.surahNumber, locale)} · '
                                      '${l10n.ayahNumber(widget.ayah.ayahNumber)}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: color,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                QuranJourneyDirectionalShift(
                                  active: _highlighted,
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    color: color,
                                    size: 19,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingSpread extends StatelessWidget {
  const _ReadingSpread({
    required this.anchor,
    required this.khatma,
    required this.isDark,
    required this.wide,
    required this.onKhatmaTap,
    required this.entranceAnimation,
  });

  final _ReadingAnchor anchor;
  final KhatmaSnapshot? khatma;
  final bool isDark;
  final bool wide;
  final VoidCallback onKhatmaTap;
  final Animation<double>? entranceAnimation;

  @override
  Widget build(BuildContext context) {
    final spreadContent = wide
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: _ContinuationRegion(anchor: anchor),
                ),
                const QuranJourneyDivider(
                  axis: Axis.vertical,
                  inset: 14,
                  strong: true,
                ),
                Expanded(
                  flex: 3,
                  child: KeyedSubtree(
                    key: const ValueKey('quran-journey-margin'),
                    child: _KhatmaRegion(
                      khatma: khatma!,
                      onTap: onKhatmaTap,
                      entranceAnimation: entranceAnimation,
                    ),
                  ),
                ),
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ContinuationRegion(anchor: anchor),
              if (khatma != null) ...[
                const QuranJourneyDivider(
                  inset: 14,
                  strong: true,
                ),
                KeyedSubtree(
                  key: const ValueKey('quran-journey-margin'),
                  child: _KhatmaRegion(
                    khatma: khatma!,
                    onTap: onKhatmaTap,
                    entranceAnimation: entranceAnimation,
                  ),
                ),
              ],
            ],
          );
    return QuranJourneyFramedRegion(
      key: const ValueKey('quran-reading-spread'),
      doubleFrame: true,
      tonalStrength: isDark ? 1.1 : 1,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(13, 13, 13, 15),
        child: spreadContent,
      ),
    );
  }
}

class _ContinuationRegion extends StatelessWidget {
  const _ContinuationRegion({required this.anchor});

  final _ReadingAnchor anchor;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('quran-reading-primary-region'),
      child: _ContinuationLeaf(anchor: anchor),
    );
  }
}

class _KhatmaRegion extends StatelessWidget {
  const _KhatmaRegion({
    required this.khatma,
    required this.onTap,
    required this.entranceAnimation,
  });

  final KhatmaSnapshot khatma;
  final VoidCallback onTap;
  final Animation<double>? entranceAnimation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('quran-khatma-region'),
      decoration: BoxDecoration(
        color: context.accentColor.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.04 : 0.016,
        ),
      ),
      child: _KhatmaJourney(
        khatma: khatma,
        onTap: onTap,
        entranceAnimation: entranceAnimation,
      ),
    );
  }
}

class _ContinuationLeaf extends StatelessWidget {
  const _ContinuationLeaf({required this.anchor});

  final _ReadingAnchor anchor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = context.primaryColor;
    return Semantics(
      container: true,
      label: '${anchor.eyebrow}, ${anchor.title}, ${anchor.reference}',
      child: Padding(
        key: const ValueKey('quran-reading-folio'),
        padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 15, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  anchor.hasReadingHistory
                      ? Icons.menu_book_rounded
                      : Icons.auto_stories_rounded,
                  color: ink,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    anchor.eyebrow,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.15,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            QuranJourneyDataTransition(
              transitionKey: 'title:${anchor.transitionKey}',
              excludeSemantics: true,
              child: Text(
                anchor.title,
                key: const ValueKey('quran-primary-title'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.42,
                      height: 1.08,
                    ),
              ),
            ),
            const SizedBox(height: 7),
            QuranJourneyDataTransition(
              transitionKey: 'reference:${anchor.transitionKey}',
              excludeSemantics: true,
              child: Text(
                anchor.reference,
                key: const ValueKey('quran-primary-reference'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            QuranJourneyDataTransition(
              transitionKey: 'description:${anchor.description ?? ''}',
              axis: Axis.vertical,
              excludeSemantics: true,
              child: anchor.description == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 11),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Text(
                          anchor.description!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 21),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 290),
                child: SizedBox(
                  width: double.infinity,
                  child: _PrimaryReadingAction(
                    label: anchor.actionLabel,
                    icon: anchor.actionIcon,
                    onPressed: anchor.onTap,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryReadingAction extends StatefulWidget {
  const _PrimaryReadingAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_PrimaryReadingAction> createState() => _PrimaryReadingActionState();
}

class _PrimaryReadingActionState extends State<_PrimaryReadingAction> {
  late final WidgetStatesController _statesController;

  @override
  void initState() {
    super.initState();
    _statesController = WidgetStatesController()..addListener(_handleStates);
  }

  void _handleStates() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _statesController
      ..removeListener(_handleStates)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final states = _statesController.value;
    final pressed = states.contains(WidgetState.pressed);
    final highlighted = states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused);
    final illumination = QuranJourneyVisualStyle.illumination(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final baseStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
      shape: const BeveledRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(7)),
      ),
      animationDuration:
          reduceMotion ? Duration.zero : QuranJourneyMotion.interaction,
    );

    return Semantics(
      button: true,
      label: widget.label,
      onTap: widget.onPressed,
      child: ExcludeSemantics(
        child: QuranJourneyPressTransform(
          pressed: pressed,
          child: FilledButton(
            key: const ValueKey('quran-primary-action'),
            statesController: _statesController,
            onPressed: widget.onPressed,
            style: baseStyle.copyWith(
              elevation: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.pressed)
                    ? 0
                    : states.contains(WidgetState.hovered)
                        ? 3
                        : 1,
              ),
              side: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.focused)
                    ? BorderSide(color: illumination, width: 2)
                    : BorderSide.none,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QuranJourneyDirectionalShift(
                  active: highlighted,
                  child: Icon(widget.icon, size: 20),
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: QuranJourneyDataTransition(
                    transitionKey: '${widget.label}:${widget.icon.codePoint}',
                    alignment: Alignment.center,
                    child: Text(
                      widget.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KhatmaJourney extends StatefulWidget {
  const _KhatmaJourney({
    required this.khatma,
    required this.onTap,
    required this.entranceAnimation,
  });

  final KhatmaSnapshot khatma;
  final VoidCallback onTap;
  final Animation<double>? entranceAnimation;

  @override
  State<_KhatmaJourney> createState() => _KhatmaJourneyState();
}

class _KhatmaJourneyState extends State<_KhatmaJourney> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _highlighted => _hovered || _focused || _pressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final khatma = widget.khatma;
    final progress = khatma.progress.clamp(0.0, 1.0);
    final status = khatma.isCompleted
        ? l10n.khatmaWirdCompleted
        : khatma.isActive
            ? l10n.khatmaDayOf(_currentDay(khatma), _totalDays(khatma))
            : l10n.noActiveKhatma;
    final percent = '${(progress * 100).round()}%';
    final color = context.accentColor;
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: l10n.khatmaProgress,
      value: '$status, $percent',
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: FocusableActionDetector(
            onShowFocusHighlight: (value) => setState(() => _focused = value),
            child: QuranJourneyPressTransform(
              pressed: _pressed,
              child: AnimatedContainer(
                key: const ValueKey('quran-khatma-progress'),
                duration: reduceMotion
                    ? Duration.zero
                    : QuranJourneyMotion.interaction,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: _highlighted ? 0.045 : 0),
                  border: Border.all(
                    color: _focused
                        ? QuranJourneyVisualStyle.illumination(context)
                            .withValues(alpha: 0.70)
                        : Colors.transparent,
                    width: QuranJourneyVisualStyle.ruleWidth,
                  ),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: widget.onTap,
                    onHighlightChanged: (value) =>
                        setState(() => _pressed = value),
                    overlayColor: WidgetStatePropertyAll(
                      color.withValues(alpha: 0.05),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(10, 8, 10, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.route_rounded, color: color, size: 19),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.khatmaProgress,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: color,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 19),
                          QuranJourneyDataTransition(
                            transitionKey: percent,
                            child: Text(
                              percent,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          QuranJourneyDataTransition(
                            transitionKey: status,
                            axis: Axis.vertical,
                            child: Text(
                              status,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _KhatmaPathIndicator(
                            progress: progress,
                            color: color,
                            entranceAnimation: widget.entranceAnimation,
                          ),
                          const SizedBox(height: 11),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: QuranJourneyDirectionalShift(
                              active: _highlighted,
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: color,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KhatmaPathIndicator extends StatefulWidget {
  const _KhatmaPathIndicator({
    required this.progress,
    required this.color,
    required this.entranceAnimation,
  });

  final double progress;
  final Color color;
  final Animation<double>? entranceAnimation;

  @override
  State<_KhatmaPathIndicator> createState() => _KhatmaPathIndicatorState();
}

class _KhatmaPathIndicatorState extends State<_KhatmaPathIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _changeController;
  late double _from;
  late double _to;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _from = widget.progress.clamp(0.0, 1.0);
    _to = _from;
    _changeController = AnimationController(
      vsync: this,
      duration: QuranJourneyMotion.stateChange,
      value: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _changeController
        ..stop()
        ..value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _KhatmaPathIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.progress.clamp(0.0, 1.0);
    if (next == _to) return;
    final curved = QuranJourneyMotion.stateCurve.transform(
      _changeController.value,
    );
    _from = _from + (_to - _from) * curved;
    _to = next;
    if (_reduceMotion) {
      _changeController.value = 1;
    } else {
      _changeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _changeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entrance = widget.entranceAnimation;
    final listenable = Listenable.merge([
      _changeController,
      if (entrance != null) entrance,
    ]);
    return Semantics(
      value: '${(widget.progress.clamp(0.0, 1.0) * 100).round()}%',
      child: AnimatedBuilder(
        animation: listenable,
        builder: (context, _) {
          final localProgress = _reduceMotion
              ? 1.0
              : QuranJourneyMotion.stateCurve.transform(
                  _changeController.value,
                );
          final entranceProgress = _reduceMotion || entrance == null
              ? 1.0
              : QuranJourneyMotion.phase(
                  entrance.value,
                  begin: 0.38,
                  end: 0.72,
                );
          final value = quranJourneyProgressValue(
            from: _from,
            to: _to,
            localProgress: localProgress,
            entranceProgress: entranceProgress,
          );
          return SizedBox(
            key: const ValueKey('quran-khatma-indicator'),
            height: 18,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final base = widget.color.withValues(alpha: 0.13);
                final separator = Theme.of(context).colorScheme.surface;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.color.withValues(alpha: 0.24),
                      width: QuranJourneyVisualStyle.innerRuleWidth,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: base),
                      FractionallySizedBox(
                        key: const ValueKey('quran-khatma-fill'),
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: value.clamp(0.0, 1.0),
                        child: ColoredBox(color: widget.color),
                      ),
                      Row(
                        children: [
                          for (var index = 0; index < 10; index++) ...[
                            if (index > 0)
                              SizedBox(
                                width: QuranJourneyVisualStyle.ruleWidth,
                                child: ColoredBox(
                                  color: separator.withValues(alpha: 0.72),
                                ),
                              ),
                            const Expanded(child: SizedBox.shrink()),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _VerseSeal extends StatelessWidget {
  const _VerseSeal({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: CustomPaint(painter: _VerseSealPainter(color: color)),
    );
  }
}

class _VerseSealPainter extends CustomPainter {
  const _VerseSealPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final line = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path();
    for (var index = 0; index < 16; index++) {
      final radius = index.isEven ? size.width * 0.45 : size.width * 0.32;
      final angle = -math.pi / 2 + index * math.pi / 8;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      index == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    canvas
      ..drawPath(path..close(), line)
      ..drawCircle(center, size.width * 0.19, line)
      ..drawCircle(center, 1.8, Paint()..color = color.withValues(alpha: 0.8));
  }

  @override
  bool shouldRepaint(covariant _VerseSealPainter oldDelegate) =>
      oldDelegate.color != color;
}

int _totalDays(KhatmaSnapshot khatma) => math.max(1, khatma.totalDays);

int _currentDay(KhatmaSnapshot khatma) =>
    (khatma.currentDay + 1).clamp(1, _totalDays(khatma));
