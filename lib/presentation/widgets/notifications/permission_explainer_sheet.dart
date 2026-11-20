import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';

Future<bool> showPermissionExplainer(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  String? continueLabel,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (context) => _PermissionExplainer(
      icon: icon,
      title: title,
      message: message,
      continueLabel: continueLabel,
    ),
  );
  return result ?? false;
}

class _PermissionExplainer extends StatelessWidget {
  const _PermissionExplainer({
    required this.icon,
    required this.title,
    required this.message,
    this.continueLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? continueLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.extension<HudaTokens>();
    final lantern = tokens != null;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: lantern
                ? HudaLamp(
                    size: 64,
                    child: Icon(icon, size: 30, color: tokens.gilt),
                  )
                : Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 32, color: scheme.primary),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: lantern
                ? theme.textTheme.titleLarge
                : theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: lantern ? null : 1.5,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const ValueKey('permission-explainer-continue'),
            onPressed: () => Navigator.of(context).pop(true),
            style: lantern
                ? FilledButton.styleFrom(minimumSize: const Size.fromHeight(52))
                : FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
            child: Text(continueLabel ?? l10n.permissionExplainerContinue),
          ),
          const SizedBox(height: 4),
          TextButton(
            key: const ValueKey('permission-explainer-not-now'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.permissionExplainerNotNow),
          ),
        ],
      ),
    );
  }
}
