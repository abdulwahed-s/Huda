import 'package:flutter/material.dart';
import 'package:huda/data/models/edition_model.dart' as edition;
import 'package:huda/data/models/tafsir_model.dart' as tafsir;

class TafsirWidget extends StatelessWidget {
  final List<edition.Data> tafsirSources;
  final String? selectedTafsirId;
  final tafsir.TafsirModel? currentTafsir;
  final bool isLoadingTafsir;
  final int ayahNumber;
  final Function(String) onTafsirSelected;
  final VoidCallback? onDownloadTafsir;
  final VoidCallback? onDownloadFullTafsir;
  final bool canDownload;
  final bool isDownloadingSurah;
  final bool isDownloadingAll;
  final Future<bool> Function() checkSurahDownloaded;
  final Future<bool> Function() checkAllDownloaded;

  const TafsirWidget({
    super.key,
    required this.tafsirSources,
    required this.selectedTafsirId,
    required this.currentTafsir,
    required this.isLoadingTafsir,
    required this.ayahNumber,
    required this.onTafsirSelected,
    this.onDownloadTafsir,
    this.onDownloadFullTafsir,
    required this.canDownload,
    required this.isDownloadingSurah,
    required this.isDownloadingAll,
    required this.checkSurahDownloaded,
    required this.checkAllDownloaded,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tafsir (Commentary)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 103, 43, 93),
          ),
        ),
        const SizedBox(height: 8),

        // Tafsir sources dropdown
        if (tafsirSources.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String?>(
              value: selectedTafsirId,
              hint: const Text('Select tafsir source'),
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('None'),
                ),
                ...tafsirSources.map((source) {
                  return DropdownMenuItem<String?>(
                    value: source.identifier,
                    child: Text('${source.name} (${source.language})'),
                  );
                }),
              ],
              onChanged: (value) {
                if (value != null) {
                  onTafsirSelected(value);
                }
              },
            ),
          )
        else
          const Text(
            'No tafsir sources available',
            style: TextStyle(color: Colors.grey),
          ),

        const SizedBox(height: 12),

        // Tafsir content
        if (selectedTafsirId != null) ...[
          if (isLoadingTafsir)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.fromARGB(255, 103, 43, 93),
                  ),
                ),
              ),
            )
          else if (currentTafsir?.data?.surahs != null &&
              currentTafsir!.data!.surahs!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tafsir:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentTafsir!.data!.surahs!.first.ayahs!
                            .firstWhere(
                                (ayah) => ayah.numberInSurah == ayahNumber,
                                orElse: () => currentTafsir!
                                    .data!.surahs!.first.ayahs!.first)
                            .text ??
                        'Tafsir not available',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

          // Download options for tafsir
          if (canDownload) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (onDownloadTafsir != null)
                  Expanded(
                    child: FutureBuilder<List<bool>>(
                      future: Future.wait([
                        checkSurahDownloaded(),
                        checkAllDownloaded(),
                      ]),
                      builder: (context, snapshot) {
                        final results = snapshot.data ?? [false, false];
                        final surahDownloaded = results[0];
                        final allDownloaded = results[1];
                        final isDownloaded = surahDownloaded || allDownloaded;

                        return ElevatedButton.icon(
                          onPressed: isDownloadingSurah ||
                                  isDownloadingAll ||
                                  isDownloaded
                              ? null
                              : onDownloadTafsir,
                          icon: isDownloaded
                              ? const Icon(Icons.check_circle, size: 16)
                              : isDownloadingSurah
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.download, size: 16),
                          label: Text(
                            isDownloaded
                                ? allDownloaded
                                    ? 'Included in All'
                                    : 'Surah Downloaded'
                                : isDownloadingSurah
                                    ? 'Downloading...'
                                    : 'Download Surah',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDownloaded ? Colors.green : Colors.amber[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (onDownloadTafsir != null && onDownloadFullTafsir != null)
                  const SizedBox(width: 8),
                if (onDownloadFullTafsir != null)
                  Expanded(
                    child: FutureBuilder<bool>(
                      future: checkAllDownloaded(),
                      builder: (context, snapshot) {
                        final allDownloaded = snapshot.data ?? false;

                        return ElevatedButton.icon(
                          onPressed: isDownloadingSurah ||
                                  isDownloadingAll ||
                                  allDownloaded
                              ? null
                              : onDownloadFullTafsir,
                          icon: allDownloaded
                              ? const Icon(Icons.check_circle, size: 16)
                              : isDownloadingAll
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.download_for_offline,
                                      size: 16),
                          label: Text(
                            allDownloaded
                                ? 'All Downloaded'
                                : isDownloadingAll
                                    ? 'Downloading...'
                                    : 'Download All',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: allDownloaded
                                ? Colors.green
                                : Colors.amber[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}
