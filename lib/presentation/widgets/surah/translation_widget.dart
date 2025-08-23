import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/edition_model.dart' as edition;
import 'package:huda/data/models/tafsir_model.dart' as tafsir;
import 'package:locale_names/locale_names.dart';
import 'package:huda/l10n/app_localizations.dart';

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
        Text(
          AppLocalizations.of(context)!.translation,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? context.accentColor
                : context.primaryColor,
          ),
        ),
        SizedBox(height: 6.h),

        // Language filter for translations
        if (availableTranslationLanguages.length > 1)
          Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 3.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.primaryColor.withValues(alpha: 0.1),
                      context.primaryColor.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: DropdownButton<String?>(
                  value: selectedTranslationLanguage,
                  hint: Text(
                    AppLocalizations.of(context)!.filterTranslationLanguage,
                    style: TextStyle(
                      color: context.primaryColor.withValues(alpha: 0.7),
                      fontSize: 12.sp,
                    ),
                  ),
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  dropdownColor: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).cardColor
                      : Colors.white,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: context.primaryColor,
                    size: 18.sp,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.translate,
                              size: 20,
                              color:
                                  context.primaryColor.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.allLanguages,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ...availableTranslationLanguages.map((language) {
                      Locale locale = Locale.fromSubtags(
                        languageCode: language,
                      );
                      return DropdownMenuItem<String?>(
                        value: language,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.translate,
                                size: 20,
                                color:
                                    context.primaryColor.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                locale.nativeDisplayLanguage,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  onChanged: onTranslationLanguageSelected,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

        // Translation sources dropdown
        if (filteredSources.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primaryColor.withValues(alpha: 0.1),
                  context.primaryColor.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: context.primaryColor.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButton<String?>(
              value: selectedTranslationId,
              hint: Text(
                AppLocalizations.of(context)!.selectTranslationSource,
                style: TextStyle(
                  color: context.primaryColor.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A1A1A)
                  : Colors.white,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: context.primaryColor,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.none,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                ...filteredSources.map((source) {
                  return DropdownMenuItem<String?>(
                    value: source.identifier,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.translate_rounded,
                            size: 20,
                            color: context.primaryColor.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${source.name}',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
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
          Text(
            AppLocalizations.of(context)!.noTranslationAvailable,
            style: const TextStyle(color: Colors.grey),
          ),

        const SizedBox(height: 12),

        // Translation content
        if (selectedTranslationId != null) ...[
          if (isLoadingTranslation)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(context.accentColor),
                ),
              ),
            )
          else if (currentTranslation?.data?.surahs != null &&
              currentTranslation!.data!.surahs!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1A1A1A)
                    : Colors.grey[50],
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? context.accentColor.withValues(alpha: 0.2)
                      : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.translation}:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? context.accentColor
                          : Colors.grey[700],
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
                        AppLocalizations.of(context)!.translationNotAvailable,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFF8FAFC)
                          : null,
                    ),
                  ),
                ],
              ),
            ),

          // Download options for translation - only show when online
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
                          onPressed: canDownload &&
                                  !isDownloadingSurah &&
                                  !isDownloadingAll &&
                                  !isDownloaded
                              ? onDownloadTranslation
                              : null,
                          icon: isDownloaded
                              ? const Icon(Icons.check_circle, size: 16)
                              : isDownloadingSurah
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.download, size: 16),
                          label: Text(
                            isDownloaded
                                ? allDownloaded
                                    ? AppLocalizations.of(context)!
                                        .includedInAll
                                    : AppLocalizations.of(context)!
                                        .surahDownloaded
                                : isDownloadingSurah
                                    ? AppLocalizations.of(context)!.downloading
                                    : AppLocalizations.of(context)!
                                        .downloadSurah,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDownloaded
                                ? const Color(0xFF4CAF50)
                                : canDownload
                                    ? null
                                    : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: isDownloaded ? 2 : 4,
                          ).copyWith(
                            backgroundColor: canDownload && !isDownloaded
                                ? WidgetStateProperty.resolveWith<Color>(
                                    (states) {
                                    if (states
                                        .contains(WidgetState.pressed)) {
                                      return context.primaryColor;
                                    }
                                    return context.primaryColor
                                        .withValues(alpha: 0.8);
                                  })
                                : null,
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
                          onPressed: canDownload &&
                                  !isDownloadingSurah &&
                                  !isDownloadingAll &&
                                  !allDownloaded
                              ? onDownloadFullTranslation
                              : null,
                          icon: allDownloaded
                              ? const Icon(Icons.check_circle, size: 16)
                              : isDownloadingAll
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.download_for_offline,
                                      size: 16),
                          label: Text(
                            allDownloaded
                                ? AppLocalizations.of(context)!.allDownloaded
                                : isDownloadingAll
                                    ? AppLocalizations.of(context)!.downloading
                                    : AppLocalizations.of(context)!.downloadAll,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: allDownloaded
                                ? const Color(0xFF4CAF50)
                                : canDownload
                                    ? null
                                    : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: allDownloaded ? 2 : 4,
                          ).copyWith(
                            backgroundColor: canDownload && !allDownloaded
                                ? WidgetStateProperty.resolveWith<Color>(
                                    (states) {
                                    if (states
                                        .contains(WidgetState.pressed)) {
                                      return context.primaryColor;
                                    }
                                    return context.primaryColor
                                        .withValues(alpha: 0.7);
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
        ],
      ],
    );
  }
}
