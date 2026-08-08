import 'package:dart_pdf_editor/dart_pdf_editor.dart';

import 'pdf_local_byte_source_stub.dart'
    if (dart.library.io) 'pdf_local_byte_source_io.dart' as local;

PdfByteSource createPdfByteSource(String location) {
  final uri = Uri.tryParse(location);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return PdfHttpByteSource(uri);
  }

  if (uri != null && uri.scheme == 'file') {
    return local.createLocalPdfByteSourceFromUri(uri);
  }

  if (uri != null && uri.hasScheme) {
    throw ArgumentError.value(
      location,
      'location',
      'Only HTTP(S) URLs and local file paths are supported for PDFs.',
    );
  }

  return local.createLocalPdfByteSource(location);
}
