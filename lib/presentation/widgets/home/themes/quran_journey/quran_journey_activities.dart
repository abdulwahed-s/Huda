import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/shared/home_section_widgets.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey/quran_journey_motion.dart';
import 'package:huda/presentation/widgets/home/themes/quran_journey/quran_journey_visual_style.dart';
import 'package:vector_graphics/vector_graphics.dart';

class QuranJourneyActivities extends StatelessWidget {
  const QuranJourneyActivities({
    super.key,
    required this.data,
    required this.actions,
    required this.isDark,
    required this.openLastReciterAudio,
    required this.openLastRadioStation,
    this.entranceAnimation,
    this.reveal = 1,
  });

  final HomeLoaded data;
  final HomeDashboardActions actions;
  final bool isDark;
  final Function(dynamic) openLastReciterAudio;
  final Function(dynamic) openLastRadioStation;
  final Animation<double>? entranceAnimation;
  final double reveal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final audio = data.lastQuranAudio;
    final hasAudio = data.hasLastQuranAudio && audio != null;
    final radio = data.lastRadioStation;
    final hasRadio = data.hasLastRadioStation && radio != null;
    final shortcuts = [
      _QuranAction(
        keyName: 'quran',
        label: l10n.quran,
        svgAsset: 'assets/images/quranicon.svg.vec',
        onTap: actions.openQuran,
        primary: true,
      ),
      _QuranAction(
        keyName: 'audio',
        label: l10n.quranAudio,
        icon: Icons.headphones_rounded,
        onTap: actions.openAudio,
      ),
      _QuranAction(
        keyName: 'radio',
        label: l10n.quranRadio,
        icon: Icons.radio_rounded,
        onTap: actions.openRadio,
      ),
      _QuranAction(
        keyName: 'bookmarks',
        label: l10n.bookmarks,
        icon: Icons.bookmarks_rounded,
        onTap: actions.openBookmarks,
      ),
    ];
    final resumes = [
      _ResumeActionData(
        keyName: 'audio',
        icon: Icons.graphic_eq_rounded,
        title: l10n.continueListening,
        subtitle: hasAudio
            ? l10n.resumeReciter(audio.reciterName)
            : l10n.noRecentActivityHome,
        color: context.primaryVariantColor,
        enabled: hasAudio,
        onTap: hasAudio
            ? () {
                HapticFeedback.lightImpact();
                openLastReciterAudio(audio);
              }
            : null,
      ),
      _ResumeActionData(
        keyName: 'radio',
        icon: Icons.podcasts_rounded,
        title: l10n.continueRadio,
        subtitle: hasRadio ? radio.stationName : l10n.noRecentActivityHome,
        color: context.accentColor,
        enabled: hasRadio,
        onTap: hasRadio
            ? () {
                HapticFeedback.lightImpact();
                openLastRadioStation(radio);
              }
            : null,
      ),
    ];

    return Column(
      key: const ValueKey('quran-journey-activities'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuranJourneyEntranceReveal(
          key: const ValueKey('quran-actions-entrance'),
          animation: entranceAnimation,
          progress: reveal,
          begin: 0.48,
          end: 0.76,
          axis: Axis.horizontal,
          directional: true,
          distance: 8,
          beginScale: 0.996,
          startOpacity: 0.78,
          child: Column(
            key: const ValueKey('quran-tools-region'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const QuranJourneySectionBreak(
                key: ValueKey('quran-reading-tools-boundary'),
              ),
              _ManuscriptCaption(title: l10n.quranTools),
              _QuranActionRail(
                actions: shortcuts,
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: QuranJourneyVisualStyle.regionGap),
        QuranJourneyEntranceReveal(
          key: const ValueKey('quran-resume-entrance'),
          animation: entranceAnimation,
          progress: reveal,
          begin: 0.64,
          end: 0.88,
          axis: Axis.horizontal,
          directional: true,
          distance: 6,
          beginScale: 0.996,
          startOpacity: 0.80,
          child: _ResumeRibbon(
            items: resumes,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _ManuscriptCaption extends StatelessWidget {
  const _ManuscriptCaption({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final color = context.primaryColor;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 2, 6, 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 22,
            color: QuranJourneyVisualStyle.illumination(context)
                .withValues(alpha: 0.72),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          Container(
            width: 44,
            height: 1,
            color: color.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }
}

class _QuranAction {
  const _QuranAction({
    required this.keyName,
    required this.label,
    required this.onTap,
    this.icon,
    this.svgAsset,
    this.primary = false,
  });

  final String keyName;
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final String? svgAsset;
  final bool primary;
}

class _QuranActionRail extends StatelessWidget {
  const _QuranActionRail({required this.actions, required this.isDark});

  final List<_QuranAction> actions;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final wide = constraints.maxWidth >= 760 && scale <= 1.35;
        final compactTabs = constraints.maxWidth >= 350 && scale <= 1.25;
        final content = wide
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < actions.length; index++) ...[
                      if (index > 0)
                        const QuranJourneyDivider(
                          axis: Axis.vertical,
                          inset: 8,
                        ),
                      Expanded(
                        flex: index == 0 ? 2 : 1,
                        child: _RailAction(
                          action: actions[index],
                          horizontal: true,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : compactTabs
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RailAction(action: actions.first, horizontal: true),
                      const QuranJourneyDivider(),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var index = 1;
                                index < actions.length;
                                index++) ...[
                              if (index > 1)
                                const QuranJourneyDivider(
                                  axis: Axis.vertical,
                                  inset: 8,
                                ),
                              Expanded(
                                child: _RailAction(
                                  action: actions[index],
                                  horizontal: false,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < actions.length; index++) ...[
                        if (index > 0) const QuranJourneyDivider(),
                        _RailAction(
                          action: actions[index],
                          horizontal: true,
                        ),
                      ],
                    ],
                  );
        return QuranJourneyFramedRegion(
          key: const ValueKey('quran-shortcuts-workspace'),
          tint: context.primaryColor,
          tonalStrength: isDark ? 1.15 : 1,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
            child: content,
          ),
        );
      },
    );
  }
}

class _RailAction extends StatefulWidget {
  const _RailAction({required this.action, required this.horizontal});

  final _QuranAction action;
  final bool horizontal;

  @override
  State<_RailAction> createState() => _RailActionState();
}

class _RailActionState extends State<_RailAction> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _highlighted => _hovered || _focused || _pressed;

  void _activate() {
    HapticFeedback.selectionClick();
    widget.action.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.primaryColor;
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final glyph = _ActionGlyph(
      action: widget.action,
      color: widget.action.primary ? color : scheme.onSurfaceVariant,
    );
    final label = Text(
      widget.action.label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: widget.horizontal ? TextAlign.start : TextAlign.center,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: widget.action.primary ? color : null,
            fontWeight:
                widget.action.primary ? FontWeight.w900 : FontWeight.w700,
            height: 1.16,
          ),
    );
    final content = widget.horizontal
        ? Row(
            children: [
              glyph,
              const SizedBox(width: 10),
              Expanded(child: label),
              if (widget.action.primary) ...[
                const SizedBox(width: 8),
                QuranJourneyDirectionalShift(
                  active: _highlighted,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: color,
                    size: 19,
                  ),
                ),
              ],
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              glyph,
              const SizedBox(height: 8),
              Flexible(child: label),
            ],
          );
    return Semantics(
      button: true,
      label: widget.action.label,
      onTap: _activate,
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
                key: ValueKey('quran-shortcut-${widget.action.keyName}'),
                duration: reduceMotion
                    ? Duration.zero
                    : QuranJourneyMotion.interaction,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.textScalerOf(context).scale(1) > 1.4
                      ? 98
                      : widget.horizontal
                          ? 74
                          : 91,
                ),
                decoration: BoxDecoration(
                  color: _highlighted
                      ? color.withValues(alpha: 0.055)
                      : widget.action.primary
                          ? color.withValues(alpha: 0.025)
                          : Colors.transparent,
                  border: Border.all(
                    color: _focused
                        ? QuranJourneyVisualStyle.illumination(context)
                            .withValues(alpha: 0.68)
                        : Colors.transparent,
                    width: QuranJourneyVisualStyle.ruleWidth,
                  ),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: _activate,
                    onHighlightChanged: (value) =>
                        setState(() => _pressed = value),
                    overlayColor: WidgetStatePropertyAll(
                      color.withValues(alpha: 0.045),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 11,
                      ),
                      child: content,
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

class _ActionGlyph extends StatelessWidget {
  const _ActionGlyph({required this.action, required this.color});

  final _QuranAction action;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = action.primary ? 27.0 : 22.0;
    if (action.svgAsset != null) {
      return SvgPicture(
        AssetBytesLoader(action.svgAsset!),
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Icon(action.icon, color: color, size: size);
  }
}

class _ResumeActionData {
  const _ResumeActionData({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;
}

class _ResumeRibbon extends StatelessWidget {
  const _ResumeRibbon({required this.items, required this.isDark});

  final List<_ResumeActionData> items;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final horizontal = constraints.maxWidth >= 640 && scale <= 1.5;
        final content = horizontal
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _ResumeAction(item: items[0])),
                    const QuranJourneyDivider(
                      axis: Axis.vertical,
                      inset: 8,
                    ),
                    Expanded(child: _ResumeAction(item: items[1])),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ResumeAction(item: items[0]),
                  const QuranJourneyDivider(),
                  _ResumeAction(item: items[1]),
                ],
              );
        return KeyedSubtree(
          key: const ValueKey('quran-resume-group'),
          child: QuranJourneyFramedRegion(
            key: const ValueKey('quran-resume-ribbon'),
            tint: QuranJourneyVisualStyle.illumination(context),
            tonalStrength: isDark ? 1.2 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        color: context.primaryColor,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.continueButton,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: context.primaryColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const QuranJourneyDivider(inset: 10, strong: true),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(10, 7, 10, 10),
                  child: content,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResumeAction extends StatefulWidget {
  const _ResumeAction({required this.item});

  final _ResumeActionData item;

  @override
  State<_ResumeAction> createState() => _ResumeActionState();
}

class _ResumeActionState extends State<_ResumeAction> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _highlighted => _hovered || _focused || _pressed;

  @override
  void didUpdateWidget(covariant _ResumeAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.item.enabled) {
      _hovered = false;
      _pressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: item.enabled,
      label: item.title,
      value: item.subtitle,
      onTap: item.onTap,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: item.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: item.enabled ? (_) => setState(() => _hovered = true) : null,
          onExit: item.enabled ? (_) => setState(() => _hovered = false) : null,
          child: FocusableActionDetector(
            enabled: item.enabled,
            onShowFocusHighlight: (value) => setState(() => _focused = value),
            child: QuranJourneyPressTransform(
              pressed: _pressed,
              child: AnimatedContainer(
                key: ValueKey('quran-resume-${item.keyName}'),
                duration: reduceMotion
                    ? Duration.zero
                    : QuranJourneyMotion.interaction,
                decoration: BoxDecoration(
                  color: _highlighted
                      ? item.color.withValues(alpha: 0.055)
                      : Colors.transparent,
                  border: Border.all(
                    color: _focused
                        ? item.color.withValues(alpha: 0.62)
                        : Colors.transparent,
                    width: QuranJourneyVisualStyle.ruleWidth,
                  ),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: item.onTap,
                    onHighlightChanged: item.enabled
                        ? (value) => setState(() => _pressed = value)
                        : null,
                    overlayColor: WidgetStatePropertyAll(
                      item.color.withValues(alpha: 0.045),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 11,
                      ),
                      child: QuranJourneyDataTransition(
                        transitionKey:
                            '${item.enabled}:${item.title}:${item.subtitle}',
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: item.color.withValues(
                                alpha: item.enabled ? 1 : 0.45,
                              ),
                              size: 22,
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: item.enabled
                                              ? null
                                              : scheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          height: 1.25,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (item.enabled) ...[
                              const SizedBox(width: 7),
                              QuranJourneyDirectionalShift(
                                active: _highlighted,
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: item.color,
                                  size: 18,
                                ),
                              ),
                            ],
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
