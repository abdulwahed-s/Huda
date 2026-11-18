import 'package:flutter/material.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

/// The color theme choice: a swatch per palette with its name under it.
/// One implementation for Settings (with its header and note) and
/// onboarding's Look step ([showHeader] false). Restyled for Lantern by
/// the `onboarding` run.
class ColorThemePicker extends StatelessWidget {
  final AppColorTheme selectedTheme;
  final Function(AppColorTheme) onThemeSelected;

  /// Settings' title, description and note around the swatches.
  final bool showHeader;

  const ColorThemePicker({
    super.key,
    required this.selectedTheme,
    required this.onThemeSelected,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return _ColorThemePickerBody(
      selectedTheme: selectedTheme,
      onThemeSelected: onThemeSelected,
      showHeader: showHeader,
    );
  }
}

class _ColorThemePickerBody extends StatelessWidget {
  const _ColorThemePickerBody({
    required this.selectedTheme,
    required this.onThemeSelected,
    required this.showHeader,
  });

  final AppColorTheme selectedTheme;
  final Function(AppColorTheme) onThemeSelected;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fold = FoldInfo.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final grid = LayoutBuilder(
      builder: (context, constraints) {
        // Swatches stay swatch-sized: 4 across a phone, more on wider
        // columns, never a row of giant tiles (changed in `settings`).
        final minTile = 64 * scale;
        var columns = ((constraints.maxWidth + space.sm) / (minTile + space.sm))
            .floor()
            .clamp(3, 8);
        // Divide evenly across a fold.
        if (fold.hasFold && columns.isOdd && columns > 3) columns--;
        final themes = AppColors.availableThemes;
        final rows = <Widget>[];
        for (var i = 0; i < themes.length; i += columns) {
          if (i > 0) rows.add(SizedBox(height: space.sm));
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < columns; j++) ...[
                  if (j > 0) SizedBox(width: space.sm),
                  Expanded(
                    child: i + j < themes.length
                        ? _Swatch(
                            theme: themes[i + j],
                            selected: themes[i + j] == selectedTheme,
                            onTap: () => onThemeSelected(themes[i + j]),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        }
        return Column(children: rows);
      },
    );
    if (!showHeader) return grid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const HudaIconMark(Icons.palette_outlined),
            SizedBox(width: space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chooseThemeColor,
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: space.xxs),
                  Text(
                    l10n.themeDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: space.xl),
        grid,
        SizedBox(height: space.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
            SizedBox(width: space.sm),
            Expanded(
              child: Text(
                l10n.themeInfo,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One palette: a rounded swatch of its primary and accent, ringed in the
/// palette's own color with a check when chosen, its name below.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final AppColorTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final page = Theme.of(context);
    final palette = AppColors.getColorScheme(theme);
    final name = AppColors.getThemeName(theme, context);
    final duration = tokens.motion.of(context, tokens.motion.short);
    final radius = BorderRadius.circular(tokens.radius.md + 4);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: name,
      excludeSemantics: true,
      child: HudaPressable(
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.all(space.xxs),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: AnimatedContainer(
                    duration: duration,
                    padding: EdgeInsets.all(selected ? 3 : 0),
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                        color: selected
                            ? palette.primary
                            : page.colorScheme.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(tokens.radius.md),
                        gradient: LinearGradient(
                          begin: AlignmentDirectional.topStart,
                          end: AlignmentDirectional.bottomEnd,
                          colors: [palette.primary, palette.primaryVariant],
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: duration,
                        child: selected
                            ? Center(
                                key: const ValueKey('check'),
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: palette.primary,
                                  ),
                                ),
                              )
                            : const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: space.xs),
                // One line, scaled down if a long name needs it: words
                // never break mid-way (changed in `settings`).
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: page.textTheme.labelMedium?.copyWith(
                      color: selected
                          ? page.colorScheme.onSurface
                          : page.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
