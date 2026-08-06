import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdf_document/pdf_document.dart';

class Marker {
  Marker({
    required this.color,
    required this.pageIndex,
    required this.text,
    required List<PdfRect> rects,
  }) : rects = List.unmodifiable(rects);

  final Color color;
  final int pageIndex;
  final String text;
  final List<PdfRect> rects;

  int get pageNumber => pageIndex + 1;

  PdfRect? get bounds {
    if (rects.isEmpty) return null;
    var left = rects.first.left;
    var bottom = rects.first.bottom;
    var right = rects.first.right;
    var top = rects.first.top;
    for (final rect in rects.skip(1)) {
      left = math.min(left, rect.left);
      bottom = math.min(bottom, rect.bottom);
      right = math.max(right, rect.right);
      top = math.max(top, rect.top);
    }
    return PdfRect(left, bottom, right, top);
  }
}
