import 'package:flutter/material.dart';
import 'download_action_button.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/edition_model.dart' as edition;
import 'package:huda/data/models/tafsir_model.dart' as tafsir;
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/surah/offline_content_banner.dart';

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

  final String? offlineMessage;

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
    this.offlineMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tafsirSources.isNotEmpty)
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
              value: selectedTafsirId,
              hint: Text(
                AppLocalizations.of(context)!.selectTafsirSource,
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
                ...tafsirSources.map((source) {
                  return DropdownMenuItem<String?>(
                    value: source.identifier,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
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
                  onTafsirSelected(value);
                }
              },
            ),
          )
        else if (offlineMessage != null)
          OfflineContentBanner(message: offlineMessage!)
        else
          Text(
            AppLocalizations.of(context)!.noTafsirAvailable,
            style: const TextStyle(color: Colors.grey),
          ),
        const SizedBox(height: 12),
        if (selectedTafsirId != null) ...[
          if (isLoadingTafsir)
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
          else if (currentTafsir?.data?.surahs != null &&
              currentTafsir!.data!.surahs!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 14,
                        color: context.primaryColor.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.tafsir,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.primaryColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      currentTafsir!.data!.surahs!.first.ayahs!
                              .firstWhere(
                                (ayah) => ayah.numberInSurah == ayahNumber,
                                orElse: () => currentTafsir!
                                    .data!
                                    .surahs!
                                    .first
                                    .ayahs!
                                    .first,
                              )
                              .text ??
                          AppLocalizations.of(context)!.tafsirNotAvailable,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2C3E50),
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (canDownload) ...[
            const SizedBox(height: 12),
            DownloadActionsLayout(
              children: [
                if (onDownloadTafsir != null)
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
                        onPressed: onDownloadTafsir,
                      );
                    },
                  ),
                if (onDownloadFullTafsir != null)
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
                        onPressed: onDownloadFullTafsir,
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
