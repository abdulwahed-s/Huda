import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

/// A new version is out (shown by `UpdateService`): led by the lit lamp
/// (an invitation), the version, its notes (or a line about it), Later
/// (quiet) and Update (lit), which closes the dialog and opens the store.
class UpdateDialog extends StatelessWidget {
  const UpdateDialog({
    super.key,
    required this.version,
    required this.onUpdate,
    this.releaseNotes,
  });

  final String version;
  final String? releaseNotes;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notes = releaseNotes?.trim();
    final hasNotes = notes != null && notes.isNotEmpty;
    final dialog = Builder(
      builder: (context) {
        final tokens = context.tokens;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return AlertDialog(
          scrollable: true,
          icon: HudaLamp(
            size: 56,
            child: Icon(
              Icons.system_update_alt_rounded,
              color: tokens.gilt,
              size: 26,
            ),
          ),
          title: Text(l10n.updateAvailableTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: HudaEyebrow(l10n.whatsNewVersion(version))),
              SizedBox(height: tokens.space.md),
              if (hasNotes)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: tokens.radius.control,
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(tokens.space.md),
                    child: Text(notes, style: theme.textTheme.bodyMedium),
                  ),
                )
              else
                Text(
                  l10n.updateAvailableBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.updateLater),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                onUpdate();
              },
              child: Text(l10n.updateNow),
            ),
          ],
        );
      },
    );
    return dialog;
  }
}
