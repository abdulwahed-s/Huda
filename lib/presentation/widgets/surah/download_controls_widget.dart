import 'package:flutter/material.dart';

class DownloadControlsWidget extends StatelessWidget {
  final bool canDownload;
  final bool isDownloadingSingle;
  final bool isDownloadingAll;
  final String downloadProgressText;
  final VoidCallback? onDownloadSingle;
  final VoidCallback? onDownloadAll;
  final Future<bool> Function() checkAllDownloaded;
  final Future<bool> Function() checkSingleDownloaded;

  const DownloadControlsWidget({
    super.key,
    required this.canDownload,
    required this.isDownloadingSingle,
    required this.isDownloadingAll,
    required this.downloadProgressText,
    this.onDownloadSingle,
    this.onDownloadAll,
    required this.checkAllDownloaded,
    required this.checkSingleDownloaded,
  });

  @override
  Widget build(BuildContext context) {
    if (!canDownload) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Download Options',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 103, 43, 93),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Download single ayah button
            Expanded(
              child: FutureBuilder<bool>(
                future: checkSingleDownloaded(),
                builder: (context, snapshot) {
                  final singleDownloaded = snapshot.data ?? false;

                  return ElevatedButton.icon(
                    onPressed: isDownloadingSingle ||
                            isDownloadingAll ||
                            singleDownloaded
                        ? null
                        : onDownloadSingle,
                    icon: singleDownloaded
                        ? const Icon(Icons.check_circle, size: 18)
                        : isDownloadingSingle
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download, size: 18),
                    label: Text(
                      singleDownloaded
                          ? 'Ayah Downloaded'
                          : isDownloadingSingle
                              ? downloadProgressText.isNotEmpty
                                  ? downloadProgressText
                                  : 'Downloading...'
                              : 'Download Ayah',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: singleDownloaded
                          ? Colors.green
                          : const Color.fromARGB(255, 103, 43, 93),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),

            // Download all surah button
            Expanded(
              child: FutureBuilder<bool>(
                future: checkAllDownloaded(),
                builder: (context, snapshot) {
                  final allDownloaded = snapshot.data ?? false;

                  return ElevatedButton.icon(
                    onPressed:
                        isDownloadingSingle || isDownloadingAll || allDownloaded
                            ? null
                            : onDownloadAll,
                    icon: allDownloaded
                        ? const Icon(Icons.check_circle, size: 18)
                        : isDownloadingAll
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download_for_offline, size: 18),
                    label: Text(
                      allDownloaded
                          ? 'All Downloaded'
                          : isDownloadingAll
                              ? downloadProgressText.isNotEmpty
                                  ? downloadProgressText
                                  : 'Downloading...'
                              : 'Download Surah',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allDownloaded
                          ? Colors.green
                          : const Color.fromARGB(255, 103, 43, 93),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
