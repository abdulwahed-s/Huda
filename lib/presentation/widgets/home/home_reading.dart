import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/home/home_dashboard_data.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/screens/khatma_page.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/home/home_actions.dart';
import 'package:huda/presentation/widgets/home/home_gallery.dart';
import 'package:huda/presentation/widgets/home/home_identity.dart';
import 'package:huda/presentation/widgets/quran_home/quran_identity.dart';
import 'package:intl/intl.dart' as intl;

typedef HomeReadingPlace = ({
  int surah,
  int ayah,
  String eyebrow,
  bool fresh,
  bool fromKhatma,
  VoidCallback open,
});

HomeReadingPlace homeReadingPlace(
  AppLocalizations l10n, {
  required Map<String, dynamic>? summary,
  required KhatmaSnapshot khatma,
  required HomeActions actions,
}) {
  if (summary != null) {
    return (
      surah: summary['surahNumber'] as int,
      ayah: summary['ayahNumber'] as int? ?? 1,
      eyebrow: l10n.continueHome,
      fresh: false,
      fromKhatma: false,
      open: () => actions.openLastRead(summary),
    );
  }
  if (khatma.isActive &&
      !khatma.isCompleted &&
      khatma.startSurah != null &&
      khatma.startAyah != null) {
    return (
      surah: khatma.startSurah!,
      ayah: khatma.startAyah!,
      eyebrow: l10n.continueHome,
      fresh: false,
      fromKhatma: true,
      open: () => actions.openSurah(khatma.startSurah!, khatma.startAyah!),
    );
  }
  return (
    surah: 1,
    ayah: 1,
    eyebrow: l10n.themeQuranJourney,
    fresh: true,
    fromKhatma: false,
    open: () => actions.openSurah(1, 1),
  );
}

String homeReadingWhere(BuildContext context, int surah, int ayah) {
  final l10n = AppLocalizations.of(context)!;
  final digits = intl.NumberFormat.decimalPattern(
    Localizations.localeOf(context).toString(),
  );
  String keep(String part) => part.replaceAll(' ', '\u00A0');
  try {
    return [
      l10n.ayahNumber(ayah),
      l10n.pageLabel(digits.format(quran.getPageNumber(surah, ayah))),
      l10n.mushafJuzHeader(digits.format(quran.getJuzNumber(surah, ayah))),
    ].map(keep).join(' · ');
  } catch (_) {
    return keep(l10n.ayahNumber(ayah));
  }
}

class HomeContinueCard extends StatelessWidget {
  const HomeContinueCard({super.key, required this.place, this.attachment});

  final HomeReadingPlace place;

  final Widget? attachment;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final title = place.fresh
        ? l10n.khatmaFromBeginningSubtitle
        : quran.getSurahNameLocalized(place.surah, locale);
    final where = place.fresh
        ? null
        : homeReadingWhere(context, place.surah, place.ayah);
    int page;
    try {
      page = quran.getPageNumber(place.surah, place.ayah);
    } catch (_) {
      page = 1;
    }
    final corner = Radius.circular(tokens.radius.lg);
    final radius = attachment == null
        ? BorderRadius.all(corner)
        : BorderRadius.vertical(top: corner);
    const ribbon = Size(16, 44);
    final card = Semantics(
      button: true,
      label: [place.eyebrow, title, ?where].join(', '),
      excludeSemantics: true,
      child: Material(
        key: const ValueKey('quran-reading-card'),
        color: tokens.chrome,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: tokens.gilt.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(gradient: tokens.chromeGradient),
          child: InkWell(
            key: const ValueKey('quran-primary-action'),
            onTap: place.open,
            splashColor: tokens.gilt.withValues(alpha: 0.12),
            highlightColor: tokens.gilt.withValues(alpha: 0.06),
            child: Stack(
              children: [
                PositionedDirectional(
                  start: space.lg,
                  top: 0,
                  child: CustomPaint(
                    size: ribbon,
                    painter: _BookmarkPainter(gilt: tokens.gilt),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    space.lg + ribbon.width + space.md,
                    space.md,
                    space.md,
                    space.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                HudaEyebrow(place.eyebrow, color: tokens.gilt),
                                SizedBox(height: space.xxs),
                                Text(
                                  title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: tokens.onChrome,
                                    height: 1.2,
                                  ),
                                ),
                                if (where != null)
                                  Text(
                                    where,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: tokens.onChromeMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: space.sm),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tokens.onChrome,
                              boxShadow: [
                                BoxShadow(
                                  color: tokens.gilt.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: SizedBox.square(
                              dimension: 44,
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 22,
                                color: tokens.chrome,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: space.sm),
                      SizedBox(
                        height: 10,
                        child: CustomPaint(
                          painter: _MushafPlacePainter(
                            place: (page - 1) / 603,
                            gilt: tokens.gilt,
                            quiet: tokens.onChromeMuted,
                            rtl: rtl,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final tab = attachment;
    if (tab == null) return HudaPressable(child: card);
    return HudaPressable(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [card, tab],
      ),
    );
  }
}

class _BookmarkPainter extends CustomPainter {
  const _BookmarkPainter({required this.gilt});

  final Color gilt;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final notch = w * 0.5;
    final ribbon = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(w / 2, h - notch)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      ribbon.shift(const Offset(1.5, 2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    final rect = Offset.zero & size;
    canvas.drawPath(
      ribbon,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(gilt, Colors.white, 0.18)!,
            gilt,
            Color.lerp(gilt, Colors.black, 0.2)!,
          ],
          stops: const [0, 0.45, 1],
        ).createShader(rect),
    );
    final stitch = Paint()
      ..color = Color.lerp(gilt, Colors.black, 0.35)!.withValues(alpha: 0.7)
      ..strokeWidth = 0.8;
    for (final x in [w * 0.2, w * 0.8]) {
      final end = h - notch * (x < w / 2 ? x / (w / 2) : (w - x) / (w / 2));
      for (var y = 2.0; y < end - 4; y += 4) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 2), stitch);
      }
    }
  }

  @override
  bool shouldRepaint(_BookmarkPainter old) => old.gilt != gilt;
}

class _MushafPlacePainter extends CustomPainter {
  const _MushafPlacePainter({
    required this.place,
    required this.gilt,
    required this.quiet,
    required this.rtl,
  });

  final double place;
  final Color gilt;
  final Color quiet;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    double x(double f) => rtl ? size.width * (1 - f) : size.width * f;
    final at = place.clamp(0.0, 1.0);
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = quiet.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );
    final tick = Paint()..strokeWidth = 1;
    for (var i = 1; i < 30; i++) {
      final f = i / 30;
      final major = i % 5 == 0;
      tick.color = f <= at
          ? gilt.withValues(alpha: 0.8)
          : quiet.withValues(alpha: major ? 0.45 : 0.25);
      final half = major ? 3.5 : 2.0;
      canvas.drawLine(Offset(x(f), y - half), Offset(x(f), y + half), tick);
    }
    canvas.drawLine(
      Offset(x(0), y),
      Offset(x(at), y),
      Paint()
        ..color = gilt
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    final mark = Offset(x(at), y);
    canvas.drawCircle(
      mark,
      7,
      Paint()
        ..shader = RadialGradient(
          colors: [gilt.withValues(alpha: 0.55), gilt.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: mark, radius: 7)),
    );
    canvas.drawCircle(mark, 2.6, Paint()..color = gilt);
  }

  @override
  bool shouldRepaint(_MushafPlacePainter old) =>
      old.place != place ||
      old.gilt != gilt ||
      old.quiet != quiet ||
      old.rtl != rtl;
}

Color homePaper(BuildContext context) => Color.lerp(
  Theme.of(context).colorScheme.surfaceContainerLowest,
  context.tokens.gilt,
  Theme.of(context).brightness == Brightness.dark ? 0.04 : 0.07,
)!;

class HomeAyahCard extends StatelessWidget {
  const HomeAyahCard({
    super.key,
    required this.ayah,
    required this.actions,
    this.lines = 3,
    this.large = false,
  });

  final DailyAyah ayah;
  final HomeActions actions;
  final int lines;

  final bool large;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final surah = quran.getSurahNameLocalized(ayah.surahNumber, locale);
    final paper = homePaper(context);
    final style = context.type.ayah.copyWith(
      color: scheme.onSurface,
      fontSize: large ? 26 : 22,
      height: 1.95,
    );
    final verse = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${ayah.text} '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: QuranAyahRosette(
              number: ayah.ayahNumber,
              size: 30,
              background: paper,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      style: style,
    );
    return Semantics(
      button: true,
      label: '${l10n.todaysAyah}, $surah, ${l10n.ayahNumber(ayah.ayahNumber)}',
      excludeSemantics: true,
      child: HudaPressable(
        child: Material(
          color: paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radius.lg),
            side: BorderSide(color: tokens.ornament.withValues(alpha: 0.32)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey('quran-daily-ayah'),
            onTap: () => actions.openSurah(ayah.surahNumber, ayah.ayahNumber),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                space.lg,
                space.md,
                space.lg,
                space.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: space.sm,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomPaint(
                            size: const Size.square(12),
                            painter: _StarPainter(color: tokens.ornament),
                          ),
                          SizedBox(width: space.xs),
                          Flexible(child: HudaEyebrow(l10n.todaysAyah)),
                        ],
                      ),
                      Text(
                        surah,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: space.xs),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final scaler = MediaQuery.textScalerOf(context);
                          final line =
                              scaler.scale(style.fontSize!) * style.height!;
                          final room = line * lines;
                          final painter = TextPainter(
                            text: TextSpan(
                              text: '${ayah.text} ۝۝',
                              style: style,
                            ),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            textScaler: scaler,
                          )..layout(maxWidth: constraints.maxWidth);
                          final fits = painter.height <= room + 1;
                          painter.dispose();
                          if (fits) return verse;
                          return SizedBox(
                            height: room,
                            child: ClipRect(
                              child: ShaderMask(
                                blendMode: BlendMode.dstIn,
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black,
                                        Colors.black,
                                        Colors.transparent,
                                      ],
                                      stops: [0, 0.6, 1],
                                    ).createShader(bounds),
                                child: SingleChildScrollView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: verse,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final a = -math.pi / 2 + i * math.pi / 8;
      final d = i.isEven ? r : r * 0.5;
      final p = c + Offset(math.cos(a), math.sin(a)) * d;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}

class HomeKhatmaRibbon extends StatelessWidget {
  const HomeKhatmaRibbon({
    super.key,
    required this.khatma,
    required this.actions,
    this.showStart = true,
    this.attached = false,
  });

  final KhatmaSnapshot khatma;
  final HomeActions actions;
  final bool showStart;

  final bool attached;

  Widget _frame(
    BuildContext context, {
    required VoidCallback onTap,
    required EdgeInsetsGeometry padding,
    required Widget child,
  }) {
    if (!attached) {
      return HudaCard(
        key: const ValueKey('quran-khatma-region'),
        onTap: onTap,
        padding: padding,
        child: child,
      );
    }
    final tokens = context.tokens;
    return Material(
      key: const ValueKey('quran-khatma-region'),
      color: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(tokens.radius.lg),
        ),
        side: BorderSide(color: tokens.gilt.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final active =
        khatma.isActive && !khatma.isCompleted && khatma.totalDays > 0;
    if (!active) {
      return _frame(
        context,
        onTap: () => showKhatmaSheet(context),
        padding: EdgeInsets.zero,
        child: HudaContentRow(
          leading: HudaLamp(
            size: 40,
            child: Icon(Icons.route_rounded, size: 20, color: tokens.gilt),
          ),
          title: l10n.khatmaProgress,
          meta: l10n.noActiveKhatma,
          onTap: () => showKhatmaSheet(context),
        ),
      );
    }
    final days = khatma.totalDays;
    final day = khatma.currentDay.clamp(0, days - 1);
    final percent = (khatma.progress * 100).round();
    final dayOf = l10n.khatmaDayOf(day + 1, days);
    final start =
        showStart && khatma.startSurah != null && khatma.startAyah != null
        ? l10n.khatmaFromSurah(
            quran.getSurahNameLocalized(khatma.startSurah!, locale),
            khatma.startAyah!,
          )
        : null;
    void open() {
      if (khatma.startSurah != null && khatma.startAyah != null) {
        actions.openSurah(khatma.startSurah!, khatma.startAyah!);
      } else {
        showKhatmaSheet(context);
      }
    }

    return Semantics(
      button: true,
      label: [l10n.khatmaProgress, dayOf, '$percent%', ?start].join(', '),
      excludeSemantics: true,
      child: _frame(
        context,
        onTap: open,
        padding: EdgeInsets.fromLTRB(space.lg, space.md, space.lg, space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HudaEyebrow(l10n.khatmaProgress),
                      Text(
                        [dayOf, ?start].join(' · '),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: space.sm),
                Text(
                  '$percent%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: tokens.ornament,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            SizedBox(height: space.sm),
            SizedBox(
              height: 14,
              child: CustomPaint(
                painter: _RibbonPainter(
                  segments: math.min(days, 30),
                  read: days <= 30 ? day : (khatma.progress * 30).floor(),
                  lit: tokens.ornament,
                  quiet: scheme.onSurfaceVariant,
                  rtl: rtl,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter({
    required this.segments,
    required this.read,
    required this.lit,
    required this.quiet,
    required this.rtl,
  });

  final int segments;
  final int read;
  final Color lit;
  final Color quiet;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments <= 0) return;
    final gap = size.width / segments * 0.22;
    final w = (size.width - gap * (segments - 1)) / segments;
    for (var i = 0; i < segments; i++) {
      final index = rtl ? segments - 1 - i : i;
      final x = i * (w + gap);
      final today = index == read;
      final done = index < read;
      final h = today ? size.height : size.height * 0.5;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - h) / 2, w, h),
        Radius.circular(math.min(w, h) / 2),
      );
      if (today) {
        canvas.drawRRect(
          rect.inflate(2.5),
          Paint()..color = lit.withValues(alpha: 0.2),
        );
      }
      canvas.drawRRect(
        rect,
        Paint()
          ..color = done || today
              ? lit.withValues(alpha: today ? 1 : 0.75)
              : quiet.withValues(alpha: 0.2),
      );
    }
  }

  @override
  bool shouldRepaint(_RibbonPainter old) =>
      old.segments != segments ||
      old.read != read ||
      old.lit != lit ||
      old.quiet != quiet ||
      old.rtl != rtl;
}

List<Widget> homeQuranToolTiles(BuildContext context, HomeActions actions) {
  final l10n = AppLocalizations.of(context)!;
  final tools = [
    (HomeQuranTool.quran, l10n.quran, actions.openQuran),
    (HomeQuranTool.audio, l10n.quranAudio, actions.openAudio),
    (HomeQuranTool.radio, l10n.quranRadio, actions.openRadio),
    (HomeQuranTool.bookmarks, l10n.bookmarks, actions.openBookmarks),
  ];
  return [
    for (var i = 0; i < tools.length; i++)
      HomeToolTile(
        key: ValueKey('home-quran-${tools[i].$1.name}'),
        title: tools[i].$2,
        plate: HomePlate(
          art: homeQuranToolArt(tools[i].$1),
          index: i,
          round: true,
        ),
        medallion: true,
        onTap: tools[i].$3,
      ),
  ];
}
