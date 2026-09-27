import 'package:flutter/material.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class DownloadActionButton extends StatelessWidget {
  final String label;
  final String completedLabel;
  final IconData icon;
  final bool downloaded;
  final bool downloading;
  final bool enabled;
  final VoidCallback? onPressed;

  const DownloadActionButton({
    super.key,
    required this.label,
    required this.completedLabel,
    required this.icon,
    required this.downloaded,
    required this.downloading,
    required this.enabled,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.brightness == Brightness.dark
        ? context.accentColor
        : context.primaryColor;
    return OutlinedButton.icon(
      onPressed: enabled && !downloaded && !downloading ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        disabledForegroundColor: downloaded
            ? accent
            : theme.colorScheme.onSurface.withValues(alpha: 0.45),
        backgroundColor: accent.withValues(alpha: downloaded ? 0.08 : 0.03),
        side: BorderSide(color: accent.withValues(alpha: 0.18)),
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: downloading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: accent),
            )
          : Icon(
              downloaded ? Icons.check_circle_outline_rounded : icon,
              size: 20,
            ),
      label: Text(
        downloaded
            ? completedLabel
            : downloading
            ? AppLocalizations.of(context)!.downloading
            : label,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelLarge,
      ),
    );
  }
}

class DownloadActionsLayout extends StatelessWidget {
  final List<Widget> children;

  const DownloadActionsLayout({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < 340 ||
            MediaQuery.textScalerOf(context).scale(14) > 18;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                children[i],
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}
