import 'package:flutter/material.dart';
import 'package:huda/core/theme/app_fonts.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

/// The app font: Amiri or the device's font, each option set in its own
/// font so the choice is seen, not read.
class FontPicker extends StatelessWidget {
  final String selectedFont;
  final ValueChanged<String> onFontSelected;

  const FontPicker({
    super.key,
    required this.selectedFont,
    required this.onFontSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // The platform's own typography carries the system family (the page's
    // roles carry the app font, which may be Amiri).
    final system =
        (theme.brightness == Brightness.dark
                ? theme.typography.white
                : theme.typography.black)
            .titleSmall
            ?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
              fontFamilyFallback: const ['Amiri'],
            );
    final amiri = theme.textTheme.titleSmall?.copyWith(
      fontFamily: AppFonts.amiri,
      color: scheme.onSurface,
    );

    void choose(String font) {
      if (font == selectedFont) return;
      HudaHaptics.selection(context);
      onFontSelected(font);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HudaChoiceRow(
          key: const ValueKey('settings-font-amiri'),
          title: 'Amiri',
          subtitle: l10n.sampleTextPreview,
          titleStyle: amiri,
          selected: selectedFont == AppFonts.amiri,
          onTap: () => choose(AppFonts.amiri),
        ),
        SizedBox(height: space.xs),
        HudaChoiceRow(
          key: const ValueKey('settings-font-system'),
          title: l10n.settingsSystemFont,
          subtitle: l10n.settingsSystemFontDescription,
          titleStyle: system,
          selected: selectedFont == AppFonts.system,
          onTap: () => choose(AppFonts.system),
        ),
      ],
    );
  }
}
