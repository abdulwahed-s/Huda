import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/books/books_identity.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:locale_names/locale_names.dart';

String bookLanguageName(BuildContext context, String code) {
  if (code.isEmpty) return '';
  final name = Locale(code).displayLanguageIn(Localizations.localeOf(context));
  if (name.isEmpty) return code.toUpperCase();
  return name[0].toUpperCase() + name.substring(1);
}

const double bookAspect = 0.68;

int bookVariant(int seed) => (seed ~/ 4).abs() % 3;

class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.title,
    required this.seed,
    this.author,
    this.downloaded = false,
    this.width,
    this.onTap,
  });

  final String title;

  final int seed;
  final String? author;
  final bool downloaded;

  final double? width;

  final ValueChanged<BuildContext>? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final l10n = AppLocalizations.of(context)!;
    final variant = bookVariant(seed);
    final author = this.author;
    final (above, below) = switch (variant) {
      0 => (11, 5),
      1 => (1, 1),
      _ => (4, 3),
    };

    final width = this.width;
    final role = width == null || width < 150
        ? theme.textTheme.titleSmall
        : width < 210
        ? theme.textTheme.titleMedium
        : theme.textTheme.titleLarge;
    final stamped = Text(
      title.trim(),
      textAlign: TextAlign.center,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: role?.copyWith(
        color: tokens.gilt,
        height: 1.3,
        shadows: const [Shadow(color: Color(0x66000000), offset: Offset(0, 1))],
      ),
    );

    final cover = BookAspect(
      aspect: bookAspect,
      child: CustomPaint(
        painter: BookCoverPainter(
          style: bookTooling(context, quiet: true),
          leather: bookLeather(context, seed),
          pages: bookPaper(context).paper,
          variant: variant,
          radius: tokens.radius.sm,
          rtl: rtl,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                space.xxxl,
                space.lg,
                space.xxl - space.xxs,
                space.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Spacer(flex: above),
                  stamped,
                  Spacer(flex: below),
                ],
              ),
            ),
            if (downloaded)
              PositionedDirectional(
                top: 0,
                end: space.lg,
                child: Semantics(
                  label: l10n.downloaded,
                  child: CustomPaint(
                    size: const Size(12, 28),
                    painter: _RibbonPainter(color: tokens.gilt),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    final onTap = this.onTap;
    return Semantics(
      button: onTap != null,
      label: [
        title,
        if (author != null && author.isNotEmpty) author,
        if (downloaded) l10n.downloaded,
      ].join(', '),
      excludeSemantics: true,
      child: Builder(
        builder: (cardContext) => HudaPressable(
          enabled: onTap != null,
          child: InkWell(
            onTap: onTap == null ? null : () => onTap(cardContext),
            borderRadius: BorderRadius.circular(tokens.radius.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                cover,
                if (author != null && author.isNotEmpty) ...[
                  SizedBox(height: space.sm),
                  Text(
                    author,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height - size.width * 0.6)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawLine(
      Offset(size.width / 2, 2),
      Offset(size.width / 2, size.height - size.width * 0.9),
      Paint()
        ..color = const Color(0x33000000)
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => old.color != color;
}

class BookCoverSkeleton extends StatelessWidget {
  const BookCoverSkeleton({super.key, this.announce = false});

  final bool announce;

  @override
  Widget build(BuildContext context) {
    return HudaSkeleton(
      announce: announce,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BookAspect(
            aspect: bookAspect,
            child: HudaSkeletonBlock(height: 0),
          ),
          SizedBox(height: 8),
          HudaSkeletonBlock(width: 80, height: 12),
        ],
      ),
    );
  }
}

class BookMark extends StatelessWidget {
  const BookMark({super.key, required this.seed, this.width = 44});

  final int seed;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Ornament(
      size: Size(width, width / bookAspect),
      painter: BookCoverPainter(
        style: bookTooling(context, quiet: true),
        leather: bookLeather(context, seed),
        pages: bookPaper(context).paper,
        variant: 0,
        radius: context.tokens.radius.sm / 2,
        rtl: Directionality.of(context) == TextDirection.rtl,
      ),
    );
  }
}
