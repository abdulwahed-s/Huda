import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

/// One option in [showSettingsChoiceSheet].
class SettingsChoice<T> {
  const SettingsChoice({
    required this.value,
    required this.title,
    this.subtitle,
    this.titleDirection,
    this.key,
  });

  final T value;
  final String title;
  final String? subtitle;

  /// The title's own direction (a language name in its script).
  final TextDirection? titleDirection;
  final Key? key;
}

/// Pick one of [choices] in the shared sheet (a bottom sheet on phones, a
/// dialog from medium width): a list of choice rows under an optional
/// [description], the current one marked. Choosing closes the sheet and
/// returns the value; closing it returns null. Used by Settings' language
/// and the home-screen widgets' languages.
Future<T?> showSettingsChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required List<SettingsChoice<T>> choices,
  required T selected,
  String? description,
}) {
  return showHudaSheet<T>(
    context: context,
    title: title,
    maxDialogWidth: 480,
    builder: (sheetContext) {
      final space = sheetContext.tokens.space;
      final theme = Theme.of(sheetContext);
      final note = description;
      return Padding(
        padding: EdgeInsets.only(bottom: space.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (note != null) ...[
              Text(
                note,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: space.md),
            ],
            for (final choice in choices) ...[
              HudaChoiceRow(
                key: choice.key,
                title: choice.title,
                // A language's local name often is its own name: say it once.
                subtitle: choice.subtitle == choice.title
                    ? null
                    : choice.subtitle,
                titleDirection: choice.titleDirection,
                selected: choice.value == selected,
                onTap: () {
                  HudaHaptics.selection(sheetContext);
                  Navigator.of(sheetContext).pop(choice.value);
                },
              ),
              if (choice != choices.last) SizedBox(height: space.xs),
            ],
          ],
        ),
      );
    },
  );
}
