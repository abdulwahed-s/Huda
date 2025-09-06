import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class Marker {
  Marker(this.color, this.range);
  final Color color;
  final PdfPageTextRange range;
}
