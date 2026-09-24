import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/l10n/app_localizations.dart';

class HomeEditButton extends StatelessWidget {
  const HomeEditButton({
    super.key,
    required this.onPressed,
    required this.foregroundColor,
    required this.backgroundColor,
    this.borderColor,
  });

  final VoidCallback onPressed;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    void activate() {
      HapticFeedback.lightImpact();
      onPressed();
    }

    return Semantics(
      button: true,
      label: l10n.editHome,
      onTap: activate,
      child: ExcludeSemantics(
        child: Tooltip(
          message: l10n.editHome,
          child: IconButton(
            onPressed: activate,
            style: IconButton.styleFrom(
              fixedSize: const Size.square(48),
              padding: EdgeInsets.zero,
              foregroundColor: foregroundColor,
              backgroundColor: backgroundColor,
              side: borderColor == null
                  ? null
                  : BorderSide(color: borderColor!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.tune_rounded, size: 21),
          ),
        ),
      ),
    );
  }
}
