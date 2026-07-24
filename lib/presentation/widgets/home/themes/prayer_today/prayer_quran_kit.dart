import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/shared/home_section_widgets.dart';
import 'package:huda/presentation/widgets/home/themes/prayer_today/prayer_today_motion.dart';
import 'package:vector_graphics/vector_graphics.dart';

class PrayerQuranKitWorkspace extends StatelessWidget {
  const PrayerQuranKitWorkspace({
    super.key,
    required this.isDark,
    required this.actions,
    required this.openLastReadSurah,
    required this.openLastReciterAudio,
    required this.openLastRadioStation,
    required this.onCollapse,
  });

  final bool isDark;
  final HomeDashboardActions actions;
  final Function(Map<String, dynamic>) openLastReadSurah;
  final Function(dynamic) openLastReciterAudio;
  final Function(dynamic) openLastRadioStation;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final data = state is HomeLoaded ? state : null;
        return _QuranKitCanvas(
          isDark: isDark,
          data: data,
          actions: actions,
          openLastReadSurah: openLastReadSurah,
          openLastReciterAudio: openLastReciterAudio,
          openLastRadioStation: openLastRadioStation,
          onCollapse: onCollapse,
        );
      },
    );
  }
}

class _QuranKitCanvas extends StatelessWidget {
  const _QuranKitCanvas({
    required this.isDark,
    required this.data,
    required this.actions,
    required this.openLastReadSurah,
    required this.openLastReciterAudio,
    required this.openLastRadioStation,
    required this.onCollapse,
  });

  final bool isDark;
  final HomeLoaded? data;
  final HomeDashboardActions actions;
  final Function(Map<String, dynamic>) openLastReadSurah;
  final Function(dynamic) openLastReciterAudio;
  final Function(dynamic) openLastRadioStation;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final summary = data?.lastReadSummary;
    final hasRead = data?.hasLastReadPosition == true && summary != null;
    final surah = hasRead ? summary['surahNumber'] as int : null;
    final ayah = hasRead ? summary['ayahNumber'] as int? ?? 1 : null;
    final audio = data?.lastQuranAudio;
    final hasAudio = data?.hasLastQuranAudio == true && audio != null;
    final radio = data?.lastRadioStation;
    final hasRadio = data?.hasLastRadioStation == true && radio != null;
    final resumes = <_ResumeItem>[
      _ResumeItem(
        icon: Icons.menu_book_rounded,
        title: l10n.continueHome,
        subtitle: hasRead
            ? '${quran.getSurahNameLocalized(surah!, locale)} · '
                '${l10n.ayahNumber(ayah!)}'
            : l10n.noRecentActivityHome,
        color: context.primaryColor,
        active: hasRead,
        onTap: hasRead ? () => openLastReadSurah(summary) : null,
      ),
      _ResumeItem(
        icon: Icons.graphic_eq_rounded,
        title: l10n.continueListening,
        subtitle: hasAudio
            ? l10n.resumeReciter(audio.reciterName)
            : l10n.noRecentActivityHome,
        color: context.primaryVariantColor,
        active: hasAudio,
        onTap: hasAudio ? () => openLastReciterAudio(audio) : null,
      ),
      _ResumeItem(
        icon: Icons.podcasts_rounded,
        title: l10n.continueRadio,
        subtitle: hasRadio ? radio.stationName : l10n.noRecentActivityHome,
        color: context.accentColor,
        active: hasRadio,
        onTap: hasRadio ? () => openLastRadioStation(radio) : null,
      ),
    ];
    final shortcuts = <_ShortcutItem>[
      _ShortcutItem(
        title: l10n.quran,
        svgAsset: 'assets/images/quranicon.svg.vec',
        onTap: actions.openQuran,
      ),
      _ShortcutItem(
        title: l10n.quranAudio,
        icon: Icons.headphones_rounded,
        onTap: actions.openAudio,
      ),
      _ShortcutItem(
        title: l10n.quranRadio,
        icon: Icons.radio_rounded,
        onTap: actions.openRadio,
      ),
      _ShortcutItem(
        title: l10n.bookmarks,
        icon: Icons.bookmarks_rounded,
        onTap: actions.openBookmarks,
      ),
    ];

    return Container(
      key: const ValueKey('prayer-quran-kit-workspace'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color.alphaBlend(
              context.primaryColor.withValues(alpha: isDark ? 0.13 : 0.055),
              scheme.surface,
            ),
            Color.alphaBlend(
              context.accentColor.withValues(alpha: isDark ? 0.07 : 0.025),
              scheme.surface,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: isDark ? 0.25 : 0.13),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _QuranKitThreadPainter(
          color: context.primaryColor.withValues(alpha: 0.075),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const _QuranStackMark(expanded: true),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.quranKit,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        Text(
                          l10n.quranTools,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.showLess,
                    onPressed: onCollapse,
                    style: IconButton.styleFrom(
                      backgroundColor:
                          context.primaryColor.withValues(alpha: 0.08),
                      foregroundColor: context.primaryColor,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_up_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ResumeLayout(items: resumes),
              const SizedBox(height: 16),
              _ShortcutLayout(items: shortcuts),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumeItem {
  const _ResumeItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool active;
  final VoidCallback? onTap;
}

class _ResumeLayout extends StatelessWidget {
  const _ResumeLayout({required this.items});

  final List<_ResumeItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final horizontal = constraints.maxWidth >= 720 && scale <= 1.35;
        if (!horizontal) {
          return Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) const SizedBox(height: 8),
                _KitReveal(
                  index: index,
                  child: _ResumeLane(item: items[index]),
                ),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) const SizedBox(width: 10),
              Expanded(
                child: _KitReveal(
                  index: index,
                  child: _ResumeLane(item: items[index]),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ResumeLane extends StatefulWidget {
  const _ResumeLane({required this.item});

  final _ResumeItem item;

  @override
  State<_ResumeLane> createState() => _ResumeLaneState();
}

class _ResumeLaneState extends State<_ResumeLane> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = widget.item;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: item.active,
      enabled: item.active,
      label: item.title,
      child: MouseRegion(
        cursor:
            item.active ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: item.active ? (_) => setState(() => _active = true) : null,
        onExit: item.active ? (_) => setState(() => _active = false) : null,
        child: FocusableActionDetector(
          enabled: item.active,
          onShowFocusHighlight: (value) => setState(() => _active = value),
          child: AnimatedScale(
            scale: _active && !reduceMotion ? 1.012 : 1,
            duration:
                reduceMotion ? Duration.zero : PrayerTodayMotion.interaction,
            child: AnimatedContainer(
              duration:
                  reduceMotion ? Duration.zero : PrayerTodayMotion.interaction,
              decoration: BoxDecoration(
                color: item.color.withValues(
                  alpha: item.active
                      ? _active
                          ? 0.11
                          : 0.075
                      : 0.025,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: item.color.withValues(alpha: _active ? 0.18 : 0.04),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  canRequestFocus: item.active,
                  onTap: item.onTap,
                  onHighlightChanged: item.active
                      ? (value) => setState(() => _active = value)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11, 10, 10, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.11),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon, color: item.color, size: 19),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (item.active) ...[
                          const SizedBox(width: 5),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: item.color,
                            size: 17,
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
    );
  }
}

class _ShortcutItem {
  const _ShortcutItem({
    required this.title,
    required this.onTap,
    this.icon,
    this.svgAsset,
  });

  final String title;
  final VoidCallback onTap;
  final IconData? icon;
  final String? svgAsset;
}

class _ShortcutLayout extends StatelessWidget {
  const _ShortcutLayout({required this.items});

  final List<_ShortcutItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final columns = constraints.maxWidth >= 650 && scale <= 1.4 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            mainAxisExtent: scale > 1.5 ? 88 : 72,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _KitReveal(
            index: index + 3,
            child: _ShortcutTile(item: items[index]),
          ),
        );
      },
    );
  }
}

class _ShortcutTile extends StatefulWidget {
  const _ShortcutTile({required this.item});

  final _ShortcutItem item;

  @override
  State<_ShortcutTile> createState() => _ShortcutTileState();
}

class _ShortcutTileState extends State<_ShortcutTile> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    final color = context.primaryColor;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _active = true),
      onExit: (_) => setState(() => _active = false),
      child: FocusableActionDetector(
        onShowFocusHighlight: (value) => setState(() => _active = value),
        child: AnimatedScale(
          scale: _active && !reduceMotion ? 1.02 : 1,
          duration:
              reduceMotion ? Duration.zero : PrayerTodayMotion.interaction,
          child: Material(
            color: color.withValues(alpha: _active ? 0.11 : 0.065),
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.item.onTap,
              onHighlightChanged: (value) => setState(() => _active = value),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                child: Row(
                  children: [
                    if (widget.item.svgAsset != null)
                      SvgPicture(
                        AssetBytesLoader(widget.item.svgAsset!),
                        width: 22,
                        height: 22,
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                      )
                    else
                      Icon(widget.item.icon, color: color, size: 22),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        widget.item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
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
    );
  }
}

class _QuranStackMark extends StatelessWidget {
  const _QuranStackMark({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: expanded ? 0.94 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : PrayerTodayMotion.stateChange,
      child: SizedBox(
        width: 43,
        height: 41,
        child: Stack(
          children: [
            for (var index = 2; index >= 0; index--)
              PositionedDirectional(
                start: index * 2.5,
                top: index * 1.5,
                child: Transform.rotate(
                  angle: (index + 1) * 0.018,
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        Theme.of(context).colorScheme.surface,
                        context.primaryColor,
                        0.12 + index * 0.05,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.primaryColor
                            .withValues(alpha: 0.16 + index * 0.04),
                      ),
                    ),
                  ),
                ),
              ),
            PositionedDirectional(
              start: 0,
              top: 0,
              child: Container(
                width: 35,
                height: 35,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: context.primaryColor,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KitReveal extends StatelessWidget {
  const _KitReveal({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : Duration(
              milliseconds:
                  PrayerTodayMotion.stateChange.inMilliseconds + index * 38,
            ),
      curve: PrayerTodayMotion.entranceCurve,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 9),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _QuranKitThreadPainter extends CustomPainter {
  const _QuranKitThreadPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final path = Path()
      ..moveTo(size.width * 0.62, 0)
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.22,
        size.width,
        size.height * 0.18,
      );
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(size.width * 0.91, size.height * 0.78),
      42,
      Paint()..color = color.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant _QuranKitThreadPainter oldDelegate) =>
      oldDelegate.color != color;
}
