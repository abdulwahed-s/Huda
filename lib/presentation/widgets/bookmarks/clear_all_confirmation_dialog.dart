import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';

class ClearAllConfirmationDialog extends StatelessWidget {
  final VoidCallback onClearAll;

  const ClearAllConfirmationDialog({
    super.key,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.clearAllBookmarks,
        style: const TextStyle(),
      ),
      content: Text(
        AppLocalizations.of(context)!.clearAllBookmarksConfirmation,
        style: const TextStyle(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: const TextStyle(),
          ),
        ),
        TextButton(
          onPressed: onClearAll,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(
            AppLocalizations.of(context)!.clearAll,
            style: const TextStyle(),
          ),
        ),
      ],
    );
  }
}
