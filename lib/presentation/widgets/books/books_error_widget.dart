import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/books/error_state_widget.dart';

class BooksErrorWidget extends StatelessWidget {
  final String message;
  final bool isDark;
  final VoidCallback onRetry;

  const BooksErrorWidget({
    super.key,
    required this.message,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      icon: Icons.error_outline_rounded,
      title: AppLocalizations.of(context)!.oopsSomethingWentWrong,
      message: message,
      isDark: isDark,
      buttonText: AppLocalizations.of(context)!.tryAgain,
      onButtonPressed: onRetry,
    );
  }
}
