import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';

class PdfLoadingWidget extends StatelessWidget {
  final int bytesDownloaded;
  final int? totalBytes;
  final ColorScheme colorScheme;

  const PdfLoadingWidget({
    super.key,
    required this.bytesDownloaded,
    required this.totalBytes,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value:
                    totalBytes != null ? bytesDownloaded / totalBytes! : null,
                strokeWidth: 4,
                backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.loadingPdf,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${(bytesDownloaded / (totalBytes ?? 1) * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
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
    required this.colorScheme,
  });

  final int bytesDownloaded;
  final int? totalBytes;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final total = totalBytes;
    final progress = total != null && total > 0
        ? (bytesDownloaded / total).clamp(0.0, 1.0)
        : null;
    final l10n = AppLocalizations.of(context)!;
    return AbsorbPointer(
      child: Semantics(
        label: l10n.loadingPdf,
        liveRegion: true,
        child: ColoredBox(
          color: colorScheme.scrim.withValues(alpha: 0.36),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 38,
                    width: 38,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.loadingPdf,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor:
                          colorScheme.outline.withValues(alpha: 0.18),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PdfErrorWidget extends StatelessWidget {
  final dynamic error;
  final ColorScheme colorScheme;

  const PdfErrorWidget({
    super.key,
    required this.error,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.failedToLoadPdf,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
