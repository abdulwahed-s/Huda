import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/whats_new_content.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key, required this.content});

  final WhatsNewContent content;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dialog = Builder(
      builder: (context) {
        final tokens = context.tokens;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return HudaRevealScope(
          child: AlertDialog(
            scrollable: true,
            icon: HudaLamp(
              size: 56,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: tokens.gilt,
                size: 24,
              ),
            ),
            title: Text(content.title(context)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: HudaEyebrow(l10n.whatsNewVersion(content.version)),
                ),
                SizedBox(height: tokens.space.md),
                for (var i = 0; i < content.features.length; i++)
                  HudaReveal(
                    index: i,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i == content.features.length - 1
                            ? 0
                            : tokens.space.sm,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            content.features[i].icon,
                            size: 20,
                            color: scheme.primary,
                          ),
                          SizedBox(width: tokens.space.sm),
                          Expanded(
                            child: Text(
                              content.features[i].title(context),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(content.buttonText(context)),
              ),
            ],
          ),
        );
      },
    );
    return dialog;
  }
}
