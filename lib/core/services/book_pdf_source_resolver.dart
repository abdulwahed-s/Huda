import 'package:huda/data/models/offline_book_model.dart';
import 'package:huda/data/services/offline_books_service.dart';

class BookPdfSource {
  const BookPdfSource({
    required this.location,
    this.remoteUrl,
    required this.isDownloaded,
  });

  final String location;
  final String? remoteUrl;
  final bool isDownloaded;
}

typedef DownloadedPdfLookup = Future<OfflineAttachment?> Function(
  int bookId, {
  String? originalUrl,
});

class BookPdfSourceResolver {
  BookPdfSourceResolver({DownloadedPdfLookup? downloadedPdfLookup})
      : _downloadedPdfLookup =
            downloadedPdfLookup ?? _lookupDownloadedPdfAttachment;

  final DownloadedPdfLookup _downloadedPdfLookup;

  Future<BookPdfSource?> resolve({
    required int bookId,
    String? remoteUrl,
  }) async {
    final normalizedRemoteUrl = _normalizedRemoteUrl(remoteUrl);
    final downloaded = await _downloadedPdfLookup(
      bookId,
      originalUrl: normalizedRemoteUrl,
    );
    if (downloaded != null && downloaded.localPath.trim().isNotEmpty) {
      return BookPdfSource(
        location: downloaded.localPath,
        remoteUrl: normalizedRemoteUrl ?? downloaded.originalUrl,
        isDownloaded: true,
      );
    }

    if (normalizedRemoteUrl == null) return null;
    return BookPdfSource(
      location: normalizedRemoteUrl,
      remoteUrl: normalizedRemoteUrl,
      isDownloaded: false,
    );
  }

  static Future<OfflineAttachment?> _lookupDownloadedPdfAttachment(
    int bookId, {
    String? originalUrl,
  }) =>
      OfflineBooksService().getDownloadedPdfAttachment(
        bookId,
        originalUrl: originalUrl,
      );

  static String? _normalizedRemoteUrl(String? value) {
    final candidate = value?.trim();
    if (candidate == null || candidate.isEmpty) return null;
    final uri = Uri.tryParse(candidate);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    return candidate;
  }
}
