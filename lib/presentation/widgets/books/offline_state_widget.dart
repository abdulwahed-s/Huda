import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/books/error_state_widget.dart';

class OfflineStateWidget extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRetry;

  const OfflineStateWidget({
    super.key,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      icon: Icons.error_outline_rounded,
      title: AppLocalizations.of(context)!.noInternetConnection,
      message: AppLocalizations.of(context)!.pleaseCheckConnection,
      isDark: isDark,
      buttonText: AppLocalizations.of(context)!.tryAgain,
      onButtonPressed: onRetry,
    );
  }
}
