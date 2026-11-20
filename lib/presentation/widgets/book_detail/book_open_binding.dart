import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/books/book_cover.dart';
import 'package:huda/presentation/widgets/books/books_identity.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

class BookOpenBinding extends StatefulWidget {
  const BookOpenBinding({
    super.key,
    required this.seed,
    required this.titlePage,
    this.coverTitle,
  });

  final int seed;

  final Widget titlePage;

  final String? coverTitle;

  static const Duration opening = Duration(milliseconds: 1000);

  @override
  State<BookOpenBinding> createState() => _BookOpenBindingState();
}

class _BookOpenBindingState extends State<BookOpenBinding>
    with SingleTickerProviderStateMixin {
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: BookOpenBinding.opening,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _open.value = 1;
    } else {
      _open.forward();
    }
  }

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final leather = bookLeather(context, widget.seed);
    final paper = bookPaper(context);
    final turn = CurvedAnimation(
      parent: _open,
      curve: const Interval(0.12, 1, curve: Curves.easeInOutCubic),
    );
    final radius = tokens.radius.sm;

    final titlePage = DecoratedBox(
      decoration: BoxDecoration(
        color: paper.paper,
        borderRadius: BorderRadiusDirectional.horizontal(
          end: Radius.circular(radius),
        ),
        gradient: LinearGradient(
          begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
          end: rtl ? Alignment.centerLeft : Alignment.centerRight,
          colors: [
            Color.alphaBlend(const Color(0x1F000000), paper.paper),
            paper.paper,
            paper.paper,
          ],
          stops: const [0, 0.08, 1],
        ),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: paper.ink),
        child: widget.titlePage,
      ),
    );

    Widget board({required bool inside, required double darken}) {
      if (inside) {
        return CustomPaint(
          painter: BookDoublurePainter(
            style: bookTooling(context, quiet: true),
            leather: Color.lerp(
              Color.lerp(leather, tokens.gilt, 0.08)!,
              const Color(0xFF000000),
              darken,
            )!,
            radius: radius,
            rtl: rtl,
          ),
          child: const SizedBox.expand(),
        );
      }
      final title = widget.coverTitle;
      final variant = bookVariant(widget.seed);
      return CustomPaint(
        painter: BookCoverPainter(
          style: bookTooling(context, quiet: true),
          leather: Color.lerp(leather, const Color(0xFF000000), darken)!,
          pages: paper.paper,
          variant: variant,
          radius: radius,
          rtl: rtl,
        ),
        child: SizedBox.expand(
          child: title == null
              ? null
              : Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    tokens.space.xxxl,
                    tokens.space.lg,
                    tokens.space.xxl - tokens.space.xxs,
                    tokens.space.lg,
                  ),
                  child: Column(
                    children: [
                      Spacer(flex: variant == 0 ? 11 : 4),
                      Text(
                        title.trim(),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: tokens.gilt,
                              height: 1.3,
                              shadows: const [
                                Shadow(
                                  color: Color(0x66000000),
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                      ),
                      Spacer(flex: variant == 0 ? 5 : 3),
                    ],
                  ),
                ),
        ),
      );
    }

    return BookAspect(
      aspect: bookAspect * 2,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: turn,
                builder: (context, _) {
                  final angle = turn.value * math.pi;
                  if (angle <= math.pi / 2) return const SizedBox.shrink();
                  final lift = math.pi - angle;
                  return Transform(
                    alignment: rtl
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0014)
                      ..rotateY(rtl ? -lift : lift),
                    child: board(inside: true, darken: math.sin(lift) * 0.35),
                  );
                },
              ),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  titlePage,
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: turn,
                      builder: (context, _) {
                        final angle = turn.value * math.pi;
                        if (angle >= math.pi / 2) {
                          return const SizedBox.shrink();
                        }
                        return Transform(
                          alignment: rtl
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0014)
                            ..rotateY(rtl ? angle : -angle),
                          child: board(
                            inside: false,
                            darken: math.sin(angle) * 0.35,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookTitleRule extends StatelessWidget {
  const BookTitleRule({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Ornament(
      size: const Size(72, 14),
      painter: _TitleRulePainter(
        OrnamentStyle(
          color: Color.lerp(tokens.gilt, tokens.chrome, 0.25)!,
          render: OrnamentRender.line,
          stroke: tokens.stroke.fine,
        ),
      ),
    );
  }
}

class _TitleRulePainter extends CustomPainter {
  const _TitleRulePainter(this.style);

  final OrnamentStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final a = size.height * 0.28;
    final b = size.height * 0.5;
    final almond = Path();
    for (var i = 0; i <= 32; i++) {
      final t = i / 32;
      final x = math.cos(t * 2 * math.pi);
      final w = a * (1 - x * x);
      final p = Offset(c.dx - b * 1.6 * x, c.dy + (t < 0.5 ? -w : w));
      i == 0 ? almond.moveTo(p.dx, p.dy) : almond.lineTo(p.dx, p.dy);
    }
    style.draw(canvas, almond..close());
    final rule = Path()
      ..moveTo(0, c.dy)
      ..lineTo(c.dx - b * 1.6, c.dy)
      ..moveTo(c.dx + b * 1.6, c.dy)
      ..lineTo(size.width, c.dy);
    style.draw(canvas, rule, closed: false);
  }

  @override
  bool shouldRepaint(_TitleRulePainter old) => old.style != style;
}
