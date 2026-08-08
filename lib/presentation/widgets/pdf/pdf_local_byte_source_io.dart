import 'dart:io';
import 'dart:typed_data';

import 'package:dart_pdf_editor/dart_pdf_editor.dart';

PdfByteSource createLocalPdfByteSource(String path) =>
    FilePdfByteSource(File(path));

PdfByteSource createLocalPdfByteSourceFromUri(Uri uri) =>
    FilePdfByteSource(File.fromUri(uri));

class FilePdfByteSource implements PdfByteSource {
  FilePdfByteSource(this._file);

  final File _file;

  @override
  Future<int?> get length async => _file.length();

  @override
  Future<Uint8List> readRange(int start, int endExclusive) async {
    final fileLength = await _file.length();
    final safeStart = start.clamp(0, fileLength).toInt();
    final safeEnd = endExclusive.clamp(safeStart, fileLength).toInt();
    if (safeEnd == safeStart) return Uint8List(0);

    final handle = await _file.open(mode: FileMode.read);
    try {
      await handle.setPosition(safeStart);
      return await handle.read(safeEnd - safeStart);
    } finally {
      await handle.close();
    }
  }

  @override
  Future<void> close() async {}
}
