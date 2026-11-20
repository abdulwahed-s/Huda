import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';

class ExitConfirmationDialog extends StatelessWidget {
  const ExitConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dialog = AlertDialog(
      scrollable: true,
      title: Text(l10n.exitDialog),
      content: Text(l10n.exitConfirmation),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.yes),
        ),
      ],
    );
    return dialog;
  }
}
