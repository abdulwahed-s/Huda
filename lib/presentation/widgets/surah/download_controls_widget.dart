import 'package:flutter/material.dart';
import 'download_action_button.dart';
import '../../../l10n/app_localizations.dart';

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

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    Widget downloadButton({
      required Future<bool> downloaded,
      required bool busy,
      required String label,
      required String completedLabel,
      required IconData icon,
      required VoidCallback? onPressed,
    }) {
      return FutureBuilder<bool>(
        future: downloaded,
        builder: (context, snapshot) {
          final complete = snapshot.data ?? false;
          final checking = snapshot.connectionState == ConnectionState.waiting;
          return DownloadActionButton(
            label: label,
            completedLabel: completedLabel,
            icon: icon,
            downloaded: complete,
            downloading: busy,
            enabled: !checking && !isDownloadingSingle && !isDownloadingAll,
            onPressed: onPressed,
          );
        },
      );
    }

    final single = downloadButton(
      downloaded: checkSingleDownloaded(),
      busy: isDownloadingSingle,
      label: l10n.downloadAyah,
      completedLabel: l10n.ayahDownloaded,
      icon: Icons.download_rounded,
      onPressed: onDownloadSingle,
    );
    final all = downloadButton(
      downloaded: checkAllDownloaded(),
      busy: isDownloadingAll,
      label: l10n.downloadSurah,
      completedLabel: l10n.surahDownloaded,
      icon: Icons.download_for_offline_outlined,
      onPressed: onDownloadAll,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DownloadActionsLayout(children: [single, all]),
        if ((isDownloadingSingle || isDownloadingAll) &&
            downloadProgressText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              downloadProgressText,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
