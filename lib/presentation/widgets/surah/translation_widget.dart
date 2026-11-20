import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'download_action_button.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
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
    this.loadingSources = false,
    this.retrying = false,
    this.onRetry,
  });

  final String? offlineMessage;

  final bool loadingSources;
  final bool retrying;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final filteredSources = selectedTranslationLanguage != null
        ? translationSources
              .where((source) => source.language == selectedTranslationLanguage)
              .toList()
        : translationSources;
    String languageName(String code) {
      try {
        return Locale.fromSubtags(languageCode: code).nativeDisplayLanguage;
      } catch (_) {
        return code;
      }
    }

    Widget picker<T>({
      required Key key,
      required IconData icon,
      required T value,
      required String hint,
      required List<DropdownMenuItem<T>> items,
      required ValueChanged<T?> onChanged,
    }) => InputDecorator(
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        contentPadding: EdgeInsets.symmetric(horizontal: space.sm),
        border: OutlineInputBorder(borderRadius: tokens.radius.control),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          key: key,
          value: value,
          isExpanded: true,
          hint: Text(hint),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );

    String? text;
    final surahs = currentTranslation?.data?.surahs;
    if (surahs != null && surahs.isNotEmpty) {
      final ayat = surahs.first.ayahs ?? const [];
      for (final ayah in ayat) {
        if (ayah.numberInSurah == ayahNumber) text = ayah.text;
      }
      text ??= ayat.isEmpty ? null : ayat.first.text;
      text ??= l10n.translationNotAvailable;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (availableTranslationLanguages.length > 1) ...[
          picker<String?>(
            key: const ValueKey('quran-translation-language'),
            icon: Icons.language_rounded,
            value: selectedTranslationLanguage,
            hint: l10n.filterTranslationLanguage,
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(l10n.allLanguages),
              ),
              for (final language in availableTranslationLanguages)
                DropdownMenuItem<String?>(
                  value: language,
                  child: Text(languageName(language)),
                ),
            ],
            onChanged: onTranslationLanguageSelected,
          ),
          SizedBox(height: space.sm),
        ],
        if (filteredSources.isNotEmpty)
          picker<String?>(
            key: const ValueKey('quran-translation-source'),
            icon: Icons.translate_rounded,
            value: selectedTranslationId,
            hint: l10n.selectTranslationSource,
            items: [
              DropdownMenuItem<String?>(value: null, child: Text(l10n.none)),
              for (final source in filteredSources)
                DropdownMenuItem<String?>(
                  value: source.identifier,
                  child: Text(
                    '${source.name}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) onTranslationSelected(value);
            },
          )
        else if (offlineMessage != null)
          OfflineContentBanner(message: offlineMessage!)
        else
          HudaStatusBanner(
            status: loadingSources
                ? (retrying ? HudaStatus.retrying : HudaStatus.updating)
                : HudaStatus.failed,
            message: l10n.noTranslationAvailable,
            onRetry: onRetry,
          ),
        if (selectedTranslationId != null) ...[
          SizedBox(height: space.sm),
          if (isLoadingTranslation)
            Padding(
              padding: EdgeInsets.all(space.md),
              child: const Center(child: HudaLampSpinner(size: 28)),
            )
          else if (text != null)
            DecoratedBox(
              key: const ValueKey('quran-translation-text'),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: tokens.radius.control,
              ),
              child: Padding(
                padding: EdgeInsets.all(space.md),
                child: Text(text, style: theme.textTheme.bodyLarge),
              ),
            ),
          if (canDownload) ...[
            SizedBox(height: space.sm),
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
