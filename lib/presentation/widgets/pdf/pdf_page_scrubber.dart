import 'package:dart_pdf_editor/dart_pdf_editor.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';

class PdfPageScrubber extends StatefulWidget {
  const PdfPageScrubber({
    super.key,
    required this.controller,
    required this.metrics,
    required this.colorScheme,
    this.bottomClearance = 0,
  });

  final PdfViewerController controller;
  final PdfScrollMetrics metrics;
  final ColorScheme colorScheme;

  /// Room kept free at the foot (the reader's capsule, the bottom inset).
  final double bottomClearance;

  @override
  State<PdfPageScrubber> createState() => _PdfPageScrubberState();
}

class _PdfPageScrubberState extends State<PdfPageScrubber> {
  static const _trackBreadth = 50.0;
  static const _minimumThumbExtent = 44.0;

  bool _isDragging = false;

  void _scrubTo(double localMain, double trackMain, double thumbMain) {
    final availableTrack = trackMain - thumbMain;
    final position = availableTrack <= 0
        ? 0.0
        : ((localMain - thumbMain / 2) / availableTrack).clamp(0.0, 1.0);
    widget.controller.jumpToNormalized(position);
  }

  @override
  Widget build(BuildContext context) {
    final metrics = widget.metrics;
    final horizontal = metrics.scrollAxis == Axis.horizontal;

    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomClearance),
      child: Align(
        key: ValueKey(
          horizontal
              ? 'pdf-page-scrubber-horizontal'
              : 'pdf-page-scrubber-vertical',
        ),
        alignment: horizontal ? Alignment.bottomCenter : Alignment.centerRight,
        child: SizedBox(
          width: horizontal ? null : _trackBreadth,
          height: horizontal ? _trackBreadth : null,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackMain = horizontal
                  ? constraints.maxWidth
                  : constraints.maxHeight;
              final thumbMain = (metrics.extent * trackMain)
                  .clamp(_minimumThumbExtent, trackMain)
                  .toDouble();
              final thumbLead = metrics.position * (trackMain - thumbMain);

              void begin(DragStartDetails details) {
                setState(() => _isDragging = true);
                _scrubTo(
                  horizontal
                      ? details.localPosition.dx
                      : details.localPosition.dy,
                  trackMain,
                  thumbMain,
                );
              }

              void update(DragUpdateDetails details) => _scrubTo(
                horizontal
                    ? details.localPosition.dx
                    : details.localPosition.dy,
                trackMain,
                thumbMain,
              );

              void end() {
                if (mounted) setState(() => _isDragging = false);
              }

              void tap(TapDownDetails details) => _scrubTo(
                horizontal
                    ? details.localPosition.dx
                    : details.localPosition.dy,
                trackMain,
                thumbMain,
              );

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: tap,
                onVerticalDragStart: horizontal ? null : begin,
                onVerticalDragUpdate: horizontal ? null : update,
                onVerticalDragEnd: horizontal ? null : (_) => end(),
                onVerticalDragCancel: horizontal ? null : end,
                onHorizontalDragStart: horizontal ? begin : null,
                onHorizontalDragUpdate: horizontal ? update : null,
                onHorizontalDragEnd: horizontal ? (_) => end() : null,
                onHorizontalDragCancel: horizontal ? end : null,
                child: _ScrubberTrack(
                  horizontal: horizontal,
                  thumbLead: thumbLead,
                  thumbMain: thumbMain,
                  trackMain: trackMain,
                  metrics: metrics,
                  colorScheme: widget.colorScheme,
                  isDragging: _isDragging,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ScrubberTrack extends StatelessWidget {
  const _ScrubberTrack({
    required this.horizontal,
    required this.thumbLead,
    required this.thumbMain,
    required this.trackMain,
    required this.metrics,
    required this.colorScheme,
    required this.isDragging,
  });

  final bool horizontal;
  final double thumbLead;
  final double thumbMain;
  final double trackMain;
  final PdfScrollMetrics metrics;
  final ColorScheme colorScheme;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final pageNumber = metrics.currentPage + 1;
    final pageLabel = AppLocalizations.of(
      context,
    )!.booksPageOf(pageNumber, metrics.pageCount);
    final horizontalBubbleLimit = (trackMain - 136)
        .clamp(0.0, double.infinity)
        .toDouble();
    final verticalBubbleLimit = (trackMain - 36)
        .clamp(0.0, double.infinity)
        .toDouble();
    final tokens = context.tokens;
    final thumbColor = isDragging
        ? tokens.lit
        : tokens.lit.withValues(alpha: 0.88);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: horizontal ? null : 0,
          right: horizontal ? null : 8,
          bottom: horizontal ? 8 : 0,
          left: horizontal ? 0 : null,
          width: horizontal ? null : 5,
          height: horizontal ? 5 : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        Positioned(
          top: horizontal ? null : thumbLead,
          right: horizontal ? null : 4,
          bottom: horizontal ? 4 : null,
          left: horizontal ? thumbLead : null,
          width: horizontal ? thumbMain : 42,
          height: horizontal ? 42 : thumbMain,
          child: AnimatedContainer(
            duration: tokens.motion.of(context, tokens.motion.short),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: thumbColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tokens.onChrome.withValues(alpha: 0.24),
              ),
            ),
            // The capsule shows the page; the thumb is a grip (the number shows
            // in the bubble while dragging).
            child: Icon(
              Icons.drag_handle_rounded,
              size: 18,
              color: tokens.onChrome,
            ),
          ),
        ),
        if (isDragging)
          Positioned(
            right: horizontal ? null : 48,
            bottom: horizontal ? 50 : null,
            left: horizontal
                ? (thumbLead + thumbMain / 2 - 68)
                      .clamp(0.0, horizontalBubbleLimit)
                      .toDouble()
                : null,
            top: horizontal
                ? null
                : (thumbLead + thumbMain / 2 - 18)
                      .clamp(0.0, verticalBubbleLimit)
                      .toDouble(),
            child: Material(
              color: tokens.chrome,
              elevation: tokens.elevation.overlay,
              borderRadius: BorderRadius.circular(tokens.radius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Text(
                  pageLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: tokens.onChrome),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
