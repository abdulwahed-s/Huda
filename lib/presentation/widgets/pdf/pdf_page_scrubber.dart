import 'package:dart_pdf_editor/dart_pdf_editor.dart';
import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';

class PdfPageScrubber extends StatefulWidget {
  const PdfPageScrubber({
    super.key,
    required this.controller,
    required this.metrics,
    required this.colorScheme,
  });

  final PdfViewerController controller;
  final PdfScrollMetrics metrics;
  final ColorScheme colorScheme;

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

    return Align(
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
            final trackMain =
                horizontal ? constraints.maxWidth : constraints.maxHeight;
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
    final pageLabel =
        '${AppLocalizations.of(context)!.resumePage(pageNumber)} / ${metrics.pageCount}';
    final horizontalBubbleLimit =
        (trackMain - 136).clamp(0.0, double.infinity).toDouble();
    final verticalBubbleLimit =
        (trackMain - 36).clamp(0.0, double.infinity).toDouble();
    final thumbColor = isDragging
        ? colorScheme.primary
        : colorScheme.primary.withValues(alpha: 0.86);

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
              color: colorScheme.onSurface.withValues(alpha: 0.12),
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
            duration: const Duration(milliseconds: 120),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: thumbColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.onPrimary.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDragging ? 0.3 : 0.2),
                  blurRadius: isDragging ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '$pageNumber',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
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
              color: colorScheme.inverseSurface,
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Text(
                  pageLabel,
                  style: TextStyle(
                    color: colorScheme.onInverseSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
