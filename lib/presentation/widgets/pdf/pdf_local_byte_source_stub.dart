import 'package:dart_pdf_editor/dart_pdf_editor.dart';

PdfByteSource createLocalPdfByteSource(String path) {
  throw UnsupportedError('Opening a local PDF path is not supported on web.');
}

PdfByteSource createLocalPdfByteSourceFromUri(Uri uri) {
  throw UnsupportedError('Opening a local PDF path is not supported on web.');
}
