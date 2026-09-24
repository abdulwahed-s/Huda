import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';

class CustomizationEditorTopBar extends StatelessWidget {
  const CustomizationEditorTopBar({
    super.key,
    required this.hasChanges,
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  final bool hasChanges;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 380 || textScale > 1.35;
    final saveButton = FilledButton(
      key: const ValueKey('customization-save'),
      onPressed: hasChanges && !isSaving ? onSave : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size(88, 48),
        shape: const StadiumBorder(),
      ),
      child: isSaving
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(l10n.saving),
              ],
            )
          : Text(l10n.save),
    );
    final cancelButton = TextButton(
      key: const ValueKey('customization-cancel'),
      onPressed: isSaving ? null : onCancel,
      style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
      child: Text(l10n.cancel),
    );
    final title = Text(
      l10n.editHome,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );

    return Material(
      color: scheme.surface,
      elevation: 2,
      shadowColor: scheme.shadow.withValues(alpha: 0.12),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: compact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    title,
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: cancelButton),
                        const SizedBox(width: 12),
                        Expanded(child: saveButton),
                      ],
                    ),
                  ],
                )
              : SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      cancelButton,
                      const SizedBox(width: 12),
                      Expanded(child: title),
                      const SizedBox(width: 12),
                      saveButton,
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class CustomizationSectionHeading extends StatelessWidget {
  const CustomizationSectionHeading({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
