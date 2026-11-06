import 'package:flutter/material.dart';
import 'download_action_button.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
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

  /// The sources are being fetched, and whether after a tap on Retry.
  final bool loadingSources;
  final bool retrying;
  final VoidCallback? onRetry;

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
    this.loadingSources = false,
    this.retrying = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    String? text;
    final surahs = currentTafsir?.data?.surahs;
    if (surahs != null && surahs.isNotEmpty) {
      final ayat = surahs.first.ayahs ?? const [];
      for (final ayah in ayat) {
        if (ayah.numberInSurah == ayahNumber) text = ayah.text;
      }
      text ??= ayat.isEmpty ? null : ayat.first.text;
      text ??= l10n.tafsirNotAvailable;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tafsirSources.isNotEmpty)
          InputDecorator(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.menu_book_rounded),
              contentPadding: EdgeInsets.symmetric(horizontal: space.sm),
              border: OutlineInputBorder(borderRadius: tokens.radius.control),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                key: const ValueKey('quran-tafsir-source'),
                value: selectedTafsirId,
                isExpanded: true,
                hint: Text(l10n.selectTafsirSource),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.none),
                  ),
                  for (final source in tafsirSources)
                    DropdownMenuItem<String?>(
                      value: source.identifier,
                      child: Text(
                        '${source.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) onTafsirSelected(value);
                },
              ),
            ),
          )
        else if (offlineMessage != null)
          OfflineContentBanner(message: offlineMessage!)
        else
          // Honest status: updating on its own, then the failure with
          // Retry, then "Retrying…" after a tap.
          HudaStatusBanner(
            status: loadingSources
                ? (retrying ? HudaStatus.retrying : HudaStatus.updating)
                : HudaStatus.failed,
            message: l10n.noTafsirAvailable,
            onRetry: onRetry,
          ),
        if (selectedTafsirId != null) ...[
          SizedBox(height: space.sm),
          if (isLoadingTafsir)
            Padding(
              padding: EdgeInsets.all(space.md),
              child: const Center(child: HudaLampSpinner(size: 28)),
            )
          else if (text != null)
            DecoratedBox(
              key: const ValueKey('quran-tafsir-text'),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: tokens.radius.control,
              ),
              child: Padding(
                padding: EdgeInsets.all(space.md),
                child: Text(
                  text,
                  textDirection: TextDirection.rtl,
                  style: context.type.arabicLabel.copyWith(
                    fontSize: 18,
                    height: 1.8,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          if (canDownload) ...[
            SizedBox(height: space.sm),
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
