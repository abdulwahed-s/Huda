import 'package:pdfrx/pdfrx.dart';

class PdfPageTextRefCount {
  PdfPageTextRefCount(this.pageText);
  final PdfPageText pageText;
  int refCount = 0;
}
