import 'package:flutter/material.dart';
import 'package:huda/data/models/chat_error.dart';
import 'package:huda/l10n/app_localizations.dart';

class ChatErrorView extends StatelessWidget {
  final ChatErrorType errorType;
  final bool isDark;
  final VoidCallback onRetry;
  final bool centered;

  const ChatErrorView({
    super.key,
    required this.errorType,
    required this.isDark,
    required this.onRetry,
    this.centered = false,
  });

  String _message(AppLocalizations l10n) {
    switch (errorType) {
      case ChatErrorType.noConnection:
        return l10n.chatErrorNoConnection;
      case ChatErrorType.rateLimit:
        return l10n.chatErrorRateLimit;
      case ChatErrorType.server:
        return l10n.chatErrorServer;
      case ChatErrorType.safetyFilter:
        return l10n.chatErrorSafety;
      case ChatErrorType.unknown:
        return l10n.chatErrorGeneric;
    }
  }

  IconData get _icon {
    switch (errorType) {
      case ChatErrorType.noConnection:
        return Icons.wifi_off_rounded;
      case ChatErrorType.rateLimit:
        return Icons.hourglass_top_rounded;
      case ChatErrorType.server:
        return Icons.cloud_off_rounded;
      case ChatErrorType.safetyFilter:
        return Icons.shield_outlined;
      case ChatErrorType.unknown:
        return Icons.error_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.error;

    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: accent, size: 40),
          const SizedBox(height: 12),
          Text(
            _message(l10n),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: Text(l10n.tryAgain),
            style: TextButton.styleFrom(
              foregroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: accent.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );

    if (!centered) return card;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: card,
        ),
      ),
    );
  }
}
