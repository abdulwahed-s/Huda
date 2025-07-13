import 'package:flutter/material.dart';
import 'package:huda/data/models/edition_model.dart' as edition;
import 'package:huda/data/models/tafsir_model.dart' as tafsir;

class TranslationWidget extends StatelessWidget {
  final List<edition.Data> translationSources;
  final String? selectedTranslationId;
  final String? selectedTranslationLanguage;
  final List<String> availableTranslationLanguages;
  final tafsir.TafsirModel? currentTranslation;
  final bool isLoadingTranslation;
  final int ayahNumber;
  final Function(String) onTranslationSelected;
  final Function(String?) onTranslationLanguageSelected;
  final VoidCallback? onDownloadTranslation;
  final VoidCallback? onDownloadFullTranslation;
  final bool canDownload;
  final bool isDownloadingSurah;
  final bool isDownloadingAll;
  final Future<bool> Function() checkSurahDownloaded;
  final Future<bool> Function() checkAllDownloaded;

  const TranslationWidget({
    super.key,
    required this.translationSources,
    required this.selectedTranslationId,
    required this.selectedTranslationLanguage,
    required this.availableTranslationLanguages,
    required this.currentTranslation,
    required this.isLoadingTranslation,
    required this.ayahNumber,
    required this.onTranslationSelected,
    required this.onTranslationLanguageSelected,
    this.onDownloadTranslation,
    this.onDownloadFullTranslation,
    required this.canDownload,
    required this.isDownloadingSurah,
    required this.isDownloadingAll,
    required this.checkSurahDownloaded,
    required this.checkAllDownloaded,
  });

  @override
  Widget build(BuildContext context) {
    final filteredSources = selectedTranslationLanguage != null
        ? translationSources
            .where((source) => source.language == selectedTranslationLanguage)
            .toList()
        : translationSources;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Translation',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 103, 43, 93),
          ),
        ),
        const SizedBox(height: 8),

        // Language filter for translations
        if (availableTranslationLanguages.length > 1)
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String?>(
                  value: selectedTranslationLanguage,
                  hint: const Text('Filter translation language'),
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All languages'),
                    ),
                    ...availableTranslationLanguages.map((language) {
                      return DropdownMenuItem<String?>(
                        value: language,
                        child: Text(language),
                      );
                    }),
                  ],
                  onChanged: onTranslationLanguageSelected,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),

        // Translation sources dropdown
        if (filteredSources.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String?>(
              value: selectedTranslationId,
              hint: const Text('Select translation source'),
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('None'),
                ),
                ...filteredSources.map((source) {
                  return DropdownMenuItem<String?>(
                    value: source.identifier,
                    child: Text('${source.name} (${source.language})'),
                  );
                }),
              ],
              onChanged: (value) {
                if (value != null) {
                  onTranslationSelected(value);
                }
              },
            ),
          )
        else
          const Text(
            'No translation sources available for selected language',
            style: TextStyle(color: Colors.grey),
          ),

        const SizedBox(height: 12),

        // Translation content
        if (selectedTranslationId != null) ...[
          if (isLoadingTranslation)
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
          else if (currentTranslation?.data?.surahs != null &&
              currentTranslation!.data!.surahs!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Translation:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentTranslation!.data!.surahs!.first.ayahs!
                            .firstWhere(
                                (ayah) => ayah.numberInSurah == ayahNumber,
                                orElse: () => currentTranslation!
                                    .data!.surahs!.first.ayahs!.first)
                            .text ??
                        'Translation not available',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

          // Download options for translation
          if (canDownload) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (onDownloadTranslation != null)
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
                              : onDownloadTranslation,
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
                                isDownloaded ? Colors.green : Colors.blue,
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
                if (onDownloadTranslation != null &&
                    onDownloadFullTranslation != null)
                  const SizedBox(width: 8),
                if (onDownloadFullTranslation != null)
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
                              : onDownloadFullTranslation,
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
                            backgroundColor:
                                allDownloaded ? Colors.green : Colors.indigo,
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
