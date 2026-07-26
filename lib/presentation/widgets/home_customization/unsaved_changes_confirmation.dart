import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

enum HomeCustomizationCloseOutcome { save, discard, keepEditing }

Future<HomeCustomizationCloseOutcome> showUnsavedChangesConfirmation(
  BuildContext context,
) async {
  final outcome = await showDialog<HomeCustomizationCloseOutcome>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => const _UnsavedChangesDialog(),
  );
  return outcome ?? HomeCustomizationCloseOutcome.keepEditing;
}

class _UnsavedChangesDialog extends StatelessWidget {
  const _UnsavedChangesDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final primary = context.primaryColor;

    void finish(HomeCustomizationCloseOutcome outcome) {
      Navigator.of(context).pop(outcome);
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          finish(HomeCustomizationCloseOutcome.keepEditing);
        },
      },
      child: Dialog(
        key: const ValueKey('unsaved-home-changes-dialog'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Icon(
                      Icons.edit_note_rounded,
                      color: primary,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.saveHomeChangesTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.18,
                      ),
                ),
                const SizedBox(height: 9),
                Text(
                  l10n.homeChangesNotApplied,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.42,
                      ),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final stack = constraints.maxWidth < 560 || textScale > 1.3;
                    final actions = [
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(1),
                        child: FilledButton.icon(
                          key: const ValueKey('save-home-changes-action'),
                          onPressed: () => finish(
                            HomeCustomizationCloseOutcome.save,
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded),
                          label: Text(l10n.saveChanges),
                        ),
                      ),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(2),
                        child: OutlinedButton.icon(
                          key: const ValueKey('discard-home-changes-action'),
                          onPressed: () => finish(
                            HomeCustomizationCloseOutcome.discard,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: scheme.error,
                            minimumSize: const Size(0, 50),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            side: BorderSide(
                              color: scheme.error.withValues(alpha: 0.62),
                            ),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text(l10n.discardChangesAction),
                        ),
                      ),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(3),
                        child: TextButton(
                          key: const ValueKey('keep-editing-action'),
                          autofocus: true,
                          onPressed: () => finish(
                            HomeCustomizationCloseOutcome.keepEditing,
                          ),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: Text(l10n.keepEditing),
                        ),
                      ),
                    ];
                    final styled = [
                      for (final action in actions)
                        Expanded(
                          child: action,
                        ),
                    ];
                    if (!stack) {
                      return Row(
                        children: [
                          styled[0],
                          const SizedBox(width: 8),
                          styled[1],
                          const SizedBox(width: 8),
                          styled[2],
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var index = 0;
                            index < actions.length;
                            index++) ...[
                          SizedBox(
                            width: double.infinity,
                            child: actions[index],
                          ),
                          if (index != actions.length - 1)
                            const SizedBox(height: 8),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
