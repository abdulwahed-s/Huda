import 'package:flutter/material.dart';
import 'download_action_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/edition_model.dart' as edition;
import 'package:huda/data/models/tafsir_model.dart' as tafsir;
import 'package:locale_names/locale_names.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/surah/offline_content_banner.dart';

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
    this.offlineMessage,
  });

  final String? offlineMessage;

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
                              color: context.primaryColor.withValues(
                                alpha: 0.7,
                              ),
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
                                color: context.primaryColor.withValues(
                                  alpha: 0.7,
                                ),
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
        else if (offlineMessage != null)
          OfflineContentBanner(message: offlineMessage!)
        else
          Text(
            AppLocalizations.of(context)!.noTranslationAvailable,
            style: const TextStyle(color: Colors.grey),
          ),
        const SizedBox(height: 12),
        if (selectedTranslationId != null) ...[
          if (isLoadingTranslation)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.accentColor,
                  ),
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
                                  .data!
                                  .surahs!
                                  .first
                                  .ayahs!
                                  .first,
                            )
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
          if (canDownload) ...[
            const SizedBox(height: 12),
            DownloadActionsLayout(
              children: [
                if (onDownloadTranslation != null)
                  FutureBuilder<List<bool>>(
                    future: Future.wait([
                      checkSurahDownloaded(),
                      checkAllDownloaded(),
                    ]),
                    builder: (context, snapshot) {
                      final results = snapshot.data ?? [false, false];
                      final l10n = AppLocalizations.of(context)!;
                      return DownloadActionButton(
                        label: l10n.downloadSurah,
                        completedLabel: results[1]
                            ? l10n.includedInAll
                            : l10n.surahDownloaded,
                        icon: Icons.download_rounded,
                        downloaded: results[0] || results[1],
                        downloading: isDownloadingSurah,
                        enabled:
                            !isDownloadingSurah &&
                            !isDownloadingAll &&
                            snapshot.connectionState != ConnectionState.waiting,
                        onPressed: onDownloadTranslation,
                      );
                    },
                  ),
                if (onDownloadFullTranslation != null)
                  FutureBuilder<bool>(
                    future: checkAllDownloaded(),
                    builder: (context, snapshot) {
                      final l10n = AppLocalizations.of(context)!;
                      return DownloadActionButton(
                        label: l10n.downloadAll,
                        completedLabel: l10n.allDownloaded,
                        icon: Icons.download_for_offline_outlined,
                        downloaded: snapshot.data ?? false,
                        downloading: isDownloadingAll,
                        enabled:
                            !isDownloadingSurah &&
                            !isDownloadingAll &&
                            snapshot.connectionState != ConnectionState.waiting,
                        onPressed: onDownloadFullTranslation,
                      );
                    },
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}
