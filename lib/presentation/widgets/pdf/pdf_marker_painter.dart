import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:huda/presentation/widgets/pdf/marker.dart';

class PdfMarkerPainter {
  final Map<int, List<Marker>> markers;

  PdfMarkerPainter(this.markers);

  void paintMarkers(Canvas canvas, Rect pageRect, PdfPage page) {
    final pageMarkers = markers[page.pageNumber];
    if (pageMarkers == null) return;

    for (final marker in pageMarkers) {
      final paint = Paint()
        ..color = marker.color.withAlpha(100)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        marker.range.bounds.toRectInDocument(page: page, pageRect: pageRect),
        paint,
      );
    }
  }
}
