import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/books/books_identity.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';

double? _fraction(int downloaded, int? total) =>
    total != null && total > 0 ? (downloaded / total).clamp(0.0, 1.0) : null;

class PdfLoadingWidget extends StatelessWidget {
  const PdfLoadingWidget({
    super.key,
    required this.bytesDownloaded,
    required this.totalBytes,
  });

  final int bytesDownloaded;
  final int? totalBytes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final space = tokens.space;
    final progress = _fraction(bytesDownloaded, totalBytes);
    return Semantics(
      liveRegion: true,
      label: l10n.booksOpening,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(space.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HudaLamp(
                  size: 56,
                  child: HudaLampSpinner(size: 28, color: tokens.gilt),
                ),
                SizedBox(height: space.md),
                Text(
                  l10n.booksOpening,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                SizedBox(height: space.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(value: progress, minHeight: 4),
                ),
                if (progress != null) ...[
                  SizedBox(height: space.xs),
                  Text(
                    '${(progress * 100).round()}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PdfPreparingDocumentOverlay extends StatelessWidget {
  const PdfPreparingDocumentOverlay({
    super.key,
    required this.bytesDownloaded,
    required this.totalBytes,
  });

  final int bytesDownloaded;
  final int? totalBytes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final space = tokens.space;
    final progress = _fraction(bytesDownloaded, totalBytes);
    final label = progress == null
        ? l10n.booksOpening
        : '${l10n.booksOpening} ${(progress * 100).round()}%';
    return AbsorbPointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.all(space.md),
          child: Semantics(
            liveRegion: true,
            label: label,
            excludeSemantics: true,
            child: Material(
              color: tokens.chrome,
              shape: const StadiumBorder(),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  space.sm,
                  space.xs,
                  space.md,
                  space.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HudaLampSpinner(size: 18, color: tokens.gilt),
                    SizedBox(width: space.sm),
                    Flexible(
                      child: Text(
                        label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: tokens.onChrome,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PdfErrorWidget extends StatelessWidget {
  const PdfErrorWidget({
    super.key,
    required this.onRetry,
    this.retrying = false,
  });

  final VoidCallback? onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HudaErrorState(
      identity: booksIdentity,
      title: l10n.booksReaderError,
      message: l10n.booksReaderErrorMessage,
      onRetry: onRetry,
      retrying: retrying,
    );
  }
}
