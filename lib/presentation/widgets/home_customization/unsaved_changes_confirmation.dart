import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';

enum HomeCustomizationCloseOutcome { discard, keepEditing }

Future<HomeCustomizationCloseOutcome> showDiscardChangesConfirmation(
  BuildContext context,
) async {
  final outcome = await showDialog<HomeCustomizationCloseOutcome>(
    context: context,
    builder: (context) => const _DiscardChangesDialog(),
  );
  return outcome ?? HomeCustomizationCloseOutcome.keepEditing;
}

Future<bool> showRestoreDefaultLayoutConfirmation(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => const _RestoreDefaultLayoutDialog(),
  );
  return confirmed ?? false;
}

class _DiscardChangesDialog extends StatelessWidget {
  const _DiscardChangesDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      icon: const Icon(Icons.edit_off_outlined),
      title: Text(l10n.discardChanges),
      content: Text(l10n.discardChangesMessage),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(
            context,
          ).pop(HomeCustomizationCloseOutcome.keepEditing),
          child: Text(l10n.keepEditing),
        ),
        FilledButton.tonal(
          onPressed: () =>
              Navigator.of(context).pop(HomeCustomizationCloseOutcome.discard),
          child: Text(l10n.discardChangesAction),
        ),
      ],
    );
  }
}

class _RestoreDefaultLayoutDialog extends StatelessWidget {
  const _RestoreDefaultLayoutDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      icon: const Icon(Icons.restart_alt_rounded),
      title: Text(l10n.restoreDefaultLayout),
      content: Text(l10n.restoreDefaultLayoutMessage),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.restoreDefaultLayout),
        ),
      ],
    );
  }
}
