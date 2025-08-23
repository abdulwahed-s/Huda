import 'package:flutter/material.dart';
import '../../../core/theme/theme_extension.dart';

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
    // Only show download controls when online
    if (!canDownload) {
      return const SizedBox.shrink(); // Hide completely when offline
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Download single ayah button
            Expanded(
              child: FutureBuilder<bool>(
                key: ValueKey(
                    'single_download_${DateTime.now().millisecondsSinceEpoch ~/ 1000}'), // Cache for 1 second
                future: checkSingleDownloaded(),
                builder: (context, snapshot) {
                  final singleDownloaded = snapshot.data ?? false;

                  return ElevatedButton.icon(
                    onPressed: canDownload &&
                            !isDownloadingSingle &&
                            !isDownloadingAll &&
                            !singleDownloaded
                        ? onDownloadSingle
                        : null,
                    icon: singleDownloaded
                        ? const Icon(Icons.check_circle, size: 18)
                        : isDownloadingSingle
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
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
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          singleDownloaded ? const Color(0xFF4CAF50) : null,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: singleDownloaded ? 2 : 4,
                    ).copyWith(
                      backgroundColor: !singleDownloaded
                          ? WidgetStateProperty.resolveWith<Color>((states) {
                              if (states.contains(WidgetState.pressed)) {
                                return context.primaryColor;
                              }
                              return context.primaryVariantColor;
                            })
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),

            // Download all surah button
            Expanded(
              child: FutureBuilder<bool>(
                key: ValueKey(
                    'all_download_${DateTime.now().millisecondsSinceEpoch ~/ 1000}'), // Cache for 1 second
                future: checkAllDownloaded(),
                builder: (context, snapshot) {
                  final allDownloaded = snapshot.data ?? false;

                  return ElevatedButton.icon(
                    onPressed: canDownload &&
                            !isDownloadingSingle &&
                            !isDownloadingAll &&
                            !allDownloaded
                        ? onDownloadAll
                        : null,
                    icon: allDownloaded
                        ? const Icon(Icons.check_circle, size: 18)
                        : isDownloadingAll
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
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
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          allDownloaded ? const Color(0xFF4CAF50) : null,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: allDownloaded ? 2 : 4,
                    ).copyWith(
                      backgroundColor: !allDownloaded
                          ? WidgetStateProperty.resolveWith<Color>((states) {
                              if (states.contains(WidgetState.pressed)) {
                                return context.primaryColor;
                              }
                              return context.primaryLightColor;
                            })
                          : null,
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
