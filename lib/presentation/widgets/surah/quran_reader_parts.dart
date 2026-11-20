import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/quran_home/quran_identity.dart';
import 'package:huda/presentation/widgets/quran_home/quran_index_widgets.dart';
import 'package:huda/presentation/widgets/surah/animated_listening_waves.dart';

@immutable
class QuranPageColors {
  const QuranPageColors({
    required this.page,
    required this.ink,
    required this.accent,
    required this.muted,
    required this.tint,
    required this.backdrop,
    this.found = const Color(0xFFB08D3C),
  });

  factory QuranPageColors.of(
    BuildContext context, {
    Color? customPage,
    Color? customInk,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final page = customPage ?? scheme.surface;
    final ink = customInk ?? scheme.onSurface;
    return QuranPageColors(
      page: page,
      ink: ink,
      accent: scheme.primary,
      muted: customInk?.withValues(alpha: 0.72) ?? scheme.onSurfaceVariant,
      tint: scheme.primary,
      found: scheme.tertiary,
      backdrop: Color.alphaBlend(
        Theme.of(context).brightness == Brightness.light
            ? ink.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.35),
        page,
      ),
    );
  }

  final Color page;

  final Color backdrop;
  final Color ink;
  final Color accent;
  final Color muted;

  final Color tint;

  final Color found;
}

const quranBismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

bool quranOpensWithBismillah(int surah) => surah != 1 && surah != 9;

class QuranSurahHeader extends StatelessWidget {
  const QuranSurahHeader({
    super.key,
    required this.surah,
    required this.colors,
    required this.fontFamily,
    this.draw,
    this.compact = false,
    this.scale = 1,
  });

  final QuranSurahRef surah;

  final double scale;
  final QuranPageColors colors;
  final String fontFamily;
  final ValueListenable<double>? draw;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    final height = (compact ? 52.0 : 80.0) * scale * textScale;
    return Semantics(
      header: true,
      label: '${surah.title}, ${surah.meta(l10n)}',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.only(
          top: compact ? space.xs : space.md,
          bottom: compact ? space.sm : space.lg,
        ),
        child: Column(
          children: [
            SizedBox(
              height: height,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, height);
                  final cartouche = QuranHeadpiecePainter.cartoucheRect(size);
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: QuranHeadpiecePainter(
                              color: colors.accent,
                              panel: colors.page,
                              drawOf: draw,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fromRect(
                        rect: cartouche.deflate(cartouche.height * 0.08),
                        child: _NameIn(
                          draw: draw,
                          child: FittedBox(
                            child: QuranSurahCalligraphy(
                              number: surah.number,
                              size: cartouche.height * 0.78,
                              color: colors.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: space.sm),
            Text(
              surah.meta(l10n),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (quranOpensWithBismillah(surah.number)) ...[
              SizedBox(height: compact ? space.xs : space.lg),
              Text(
                quranBismillah,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: context.type.ayah.copyWith(
                  fontFamily: fontFamily,
                  fontSize: (context.type.ayah.fontSize ?? 28) * scale,
                  color: colors.ink,
                  height: 1.6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NameIn extends StatelessWidget {
  const _NameIn({required this.child, this.draw});

  final Widget child;
  final ValueListenable<double>? draw;

  @override
  Widget build(BuildContext context) {
    final draw = this.draw;
    if (draw == null) return child;
    return ValueListenableBuilder<double>(
      valueListenable: draw,
      child: child,
      builder: (context, t, child) =>
          Opacity(opacity: QuranGeometry.phase(t, 0.45, 0.75), child: child),
    );
  }
}

class QuranAyahBlock extends StatelessWidget {
  const QuranAyahBlock({
    super.key,
    required this.number,
    required this.text,
    required this.colors,
    required this.fontFamily,
    required this.onTap,
    this.marks,
    this.translation,
    this.translationSource,
    this.playing = false,
    this.hidden = false,
    this.listening = false,
    this.scale = 1,
    this.found,
  });

  final int number;
  final String text;

  final double scale;
  final QuranPageColors colors;
  final String fontFamily;
  final VoidCallback onTap;

  final Widget? marks;
  final String? translation;
  final String? translationSource;
  final bool playing;
  final bool hidden;
  final bool listening;

  final Animation<double>? found;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final base = context.type.ayah;
    final ayahStyle = base.copyWith(
      fontFamily: fontFamily,
      color: colors.ink,
      fontSize: (base.fontSize ?? 28) * scale,
    );
    final fontSize = ayahStyle.fontSize ?? 28;
    final rosetteSize = MediaQuery.textScalerOf(context).scale(fontSize) * 1.15;
    final translation = this.translation;
    final arabic = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$text '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: QuranAyahRosette(
              number: number,
              size: rosetteSize,
              lit: playing,
              color: colors.accent,
              background: colors.page,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.rtl,
      textAlign: scale > 1 ? TextAlign.justify : TextAlign.start,
      style: ayahStyle,
    );
    final body = Padding(
      padding: EdgeInsets.symmetric(horizontal: space.md, vertical: space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (marks != null)
            Align(alignment: AlignmentDirectional.centerEnd, child: marks),
          if (hidden)
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  QuranAyahRosette(
                    number: number,
                    size: rosetteSize,
                    color: colors.accent,
                    background: colors.page,
                  ),
                  SizedBox(width: space.sm),
                  Expanded(
                    child: AnimatedListeningWaves(isListening: listening),
                  ),
                ],
              ),
            )
          else
            arabic,
          if (!hidden && translation != null) ...[
            SizedBox(height: space.sm),
            Text(
              translation,
              style: theme.textTheme.bodyLarge?.copyWith(color: colors.ink),
            ),
            if (translationSource != null && translationSource!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: space.xxs),
                child: Text(
                  translationSource!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.muted,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
    final block = Semantics(
      key: ValueKey('quran-ayah-$number'),
      button: true,
      selected: playing,
      label:
          '${l10n.ayahNumber(number)}. ${hidden ? '' : text}'
          '${translation == null || hidden ? '' : '\n$translation'}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: tokens.motion.of(context, tokens.motion.medium),
        curve: tokens.motion.standard,
        decoration: BoxDecoration(
          color: playing
              ? colors.tint.withValues(alpha: 0.08)
              : colors.page.withValues(alpha: 0),
          borderRadius: tokens.radius.control,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: tokens.radius.control,
            onTap: onTap,
            child: body,
          ),
        ),
      ),
    );
    final found = this.found;
    if (found == null) return block;
    return CustomPaint(
      key: const ValueKey('quran-ayah-found'),
      painter: QuranFoundPainter(
        level: found,
        accent: colors.found,
        radius: tokens.radius.control.topLeft.x,
      ),
      child: block,
    );
  }
}

class QuranFoundPainter extends CustomPainter {
  QuranFoundPainter({
    required this.level,
    required this.accent,
    required this.radius,
  }) : super(repaint: level);

  final Animation<double> level;
  final Color accent;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final value = level.value.clamp(0.0, 1.0);
    if (value <= 0 || size.isEmpty) return;
    final area = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(area, Radius.circular(radius)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            accent.withValues(alpha: 0.2 * value),
            accent.withValues(alpha: 0.07 * value),
          ],
        ).createShader(area),
    );
    const width = 3.5;
    final reach = (size.height - 2 * radius) * (0.4 + 0.6 * value) / 2;
    final middle = size.height / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          size.width - width - 3,
          middle - reach,
          size.width - 3,
          middle + reach,
        ),
        const Radius.circular(width / 2),
      ),
      Paint()..color = accent.withValues(alpha: 0.9 * value),
    );
  }

  @override
  bool shouldRepaint(QuranFoundPainter old) =>
      old.level != level || old.accent != accent || old.radius != radius;
}

class QuranAyahRule extends StatelessWidget {
  const QuranAyahRule({super.key, required this.colors});

  final QuranPageColors colors;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: space.xl),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.accent.withValues(alpha: 0),
              colors.accent.withValues(alpha: 0.35),
              colors.accent.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class QuranSurahEnd extends StatelessWidget {
  const QuranSurahEnd({super.key, required this.surah, required this.onOpen});

  final int surah;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final language = Localizations.localeOf(context).languageCode;
    final next = surah < 114 ? QuranSurahRef.number(surah + 1, language) : null;
    final previous = surah > 1
        ? QuranSurahRef.number(surah - 1, language)
        : null;
    Widget label(String eyebrow, String name) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) => Text(
            eyebrow,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: DefaultTextStyle.of(context).style.color,
            ),
          ),
        ),
        Text(name),
      ],
    );
    final buttons = <Widget>[
      if (previous != null)
        OutlinedButton.icon(
          key: const ValueKey('quran-previous-surah'),
          onPressed: () => onOpen(previous.number),
          icon: const Icon(Icons.arrow_back_rounded),
          label: label(l10n.previousSurah, previous.title),
        ),
      if (next != null)
        FilledButton.icon(
          key: const ValueKey('quran-next-surah'),
          onPressed: () => onOpen(next.number),
          icon: const Icon(Icons.arrow_forward_rounded),
          iconAlignment: IconAlignment.end,
          label: label(l10n.nextSurah, next.title),
        ),
    ];
    return Padding(
      padding: EdgeInsets.only(top: space.xl, bottom: space.lg),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: space.sm,
        runSpacing: space.sm,
        children: buttons,
      ),
    );
  }
}

class QuranPlayerBar extends StatelessWidget {
  const QuranPlayerBar({
    super.key,
    required this.ayah,
    required this.total,
    required this.playing,
    required this.position,
    required this.duration,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
    required this.onOpen,
  });

  final int ayah;
  final int total;
  final bool playing;
  final Duration position;
  final Duration duration;
  final VoidCallback? onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback onOpen;

  static String _time(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final insets = MediaQuery.paddingOf(context);
    final progress = duration.inMilliseconds <= 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    return Material(
      key: const ValueKey('quran-player'),
      color: scheme.surfaceContainer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: progress, minHeight: 2),
          Padding(
            padding: EdgeInsets.fromLTRB(
              space.sm + insets.left,
              space.xs,
              space.sm + insets.right,
              space.xs + insets.bottom,
            ),
            child: Row(
              children: [
                QuranAyahRosette(number: ayah, size: 36, lit: playing),
                SizedBox(width: space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.playingAyahOfTotal(ayah, total),
                        style: theme.textTheme.labelLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (duration > Duration.zero)
                        Text(
                          '${_time(position)} / ${_time(duration)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.previous,
                  onPressed: onPrevious,
                  icon: Icon(
                    rtl ? Icons.skip_next_rounded : Icons.skip_previous_rounded,
                  ),
                ),
                SizedBox.square(
                  dimension: 48,
                  child: Tooltip(
                    message: playing ? l10n.pause : l10n.play,
                    child: FilledButton(
                      key: const ValueKey('quran-player-play'),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      onPressed: onPlayPause,
                      child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.next,
                  onPressed: onNext,
                  icon: Icon(
                    rtl ? Icons.skip_previous_rounded : Icons.skip_next_rounded,
                  ),
                ),
                IconButton(
                  tooltip: l10n.ayahText,
                  onPressed: onOpen,
                  icon: const Icon(Icons.keyboard_arrow_up_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
