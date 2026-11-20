import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

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

  final TextDirection? titleDirection;
  final Key? key;
}

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
