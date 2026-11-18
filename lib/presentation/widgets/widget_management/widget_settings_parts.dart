import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/settings/settings_layout.dart';
import 'package:huda/presentation/widgets/widget_management/samsung_lock_widget_setup.dart';

/// A widget's page under the switch: the live preview and how to add it,
/// then its settings. One readable column on narrow windows; from 720 wide
/// (or a vertical fold) the preview pane stays beside the settings, so
/// every change is seen as it's made; in tabletop posture the preview sits
/// above the band and the settings scroll below it.
class WidgetSettingsLayout extends StatelessWidget {
  const WidgetSettingsLayout({
    super.key,
    required this.preview,
    required this.add,
    required this.sections,
  });

  final Widget preview;
  final Widget add;
  final List<Widget> sections;

  static const twoPaneMinWidth = 720.0;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final width = MediaQuery.sizeOf(context).width;
    final fold = FoldInfo.of(context);
    final twoPanes = AdaptivePanes.showsTwoPanes(
      width,
      fold,
      twoPaneMinWidth: twoPaneMinWidth,
    );
    var index = 0;
    Widget reveal(Widget child) => HudaReveal(index: index++, child: child);
    List<Widget> spaced(List<Widget> children) => [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) SizedBox(height: space.xl),
        reveal(children[i]),
      ],
    ];
    Widget list(List<Widget> children) => LayoutBuilder(
      builder: (context, constraints) {
        final gutter = space.gutter(constraints.maxWidth);
        return ListView(
          padding: context.scrollPadding(
            EdgeInsets.fromLTRB(gutter, space.md, gutter, space.xxl),
          ),
          children: [
            ReadableWidth(
              maxWidth: 640,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        );
      },
    );

    final head = spaced([preview, add]);
    if (fold.isTabletop) {
      return SettingsTabletop(top: list(head), bottom: list(spaced(sections)));
    }
    if (!twoPanes) {
      return list([...head, SizedBox(height: space.xl), ...spaced(sections)]);
    }
    return AdaptivePanes(
      twoPaneMinWidth: twoPaneMinWidth,
      maxPrimaryWidth: 460,
      minPrimaryWidth: 320,
      primary: list(head),
      secondary: list(spaced(sections)),
    );
  }
}

/// The preview, set on a quiet stand-in for a home screen: the widget at
/// a phone's widget width, labeled "Preview" for screen readers.
class WidgetPreviewStage extends StatelessWidget {
  const WidgetPreviewStage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HudaSectionHeader(l10n.widgetPreview),
        Semantics(
          label: l10n.widgetPreview,
          image: true,
          child: ExcludeSemantics(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: space.lg,
                vertical: space.xl,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(tokens.radius.lg),
                border: Border.all(color: scheme.outlineVariant),
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [
                    Color.alphaBlend(
                      scheme.primary.withValues(alpha: 0.10),
                      scheme.surfaceContainerLow,
                    ),
                    scheme.surfaceContainerLow,
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// How to put a widget on the home screen: Android launchers that can pin
/// get one lit button; everywhere else, the platform's numbered steps.
/// Samsung's One UI 9 lock-screen guidance follows where it applies.
class WidgetAddSection extends StatefulWidget {
  const WidgetAddSection({
    super.key,
    required this.androidName,
    required this.qualifiedAndroidName,
    required this.addLabel,
  });

  final String androidName;
  final String qualifiedAndroidName;
  final String addLabel;

  @override
  State<WidgetAddSection> createState() => _WidgetAddSectionState();
}

class _WidgetAddSectionState extends State<WidgetAddSection> {
  bool _checking = Platform.isAndroid;
  bool _canPin = false;

  @override
  void initState() {
    super.initState();
    if (_checking) _checkPin();
  }

  Future<void> _checkPin() async {
    var supported = false;
    try {
      supported = await HomeWidget.isRequestPinWidgetSupported() == true;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _canPin = supported;
      _checking = false;
    });
  }

  Future<void> _pin() async {
    try {
      await HomeWidget.requestPinWidget(
        androidName: widget.androidName,
        qualifiedAndroidName: widget.qualifiedAndroidName,
      );
    } catch (e) {
      debugPrint('requestPinWidget(${widget.androidName}) failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final Widget body;
    if (_checking) {
      body = const SizedBox(
        height: 48,
        child: Center(child: HudaLampSpinner(size: 24)),
      );
    } else if (_canPin) {
      body = FilledButton.icon(
        key: const ValueKey('widgets-pin'),
        onPressed: _pin,
        icon: const Icon(Icons.add_to_home_screen_rounded),
        label: Text(widget.addLabel),
      );
    } else {
      body = HudaCard(
        padding: EdgeInsets.all(space.md),
        child: _Steps(steps: _steps(l10n)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HudaSectionHeader(
          Platform.isMacOS ? l10n.addWidget : l10n.addWidgetToHomeScreen,
        ),
        HudaStateSwitcher(stateKey: (_checking, _canPin), child: body),
        const SamsungLockWidgetSetup(),
      ],
    );
  }

  List<String> _steps(AppLocalizations l10n) {
    if (Platform.isIOS) {
      return [
        l10n.iosWidgetStep1,
        l10n.iosWidgetStep2,
        l10n.iosWidgetStep3,
        l10n.iosWidgetStep4,
      ];
    }
    if (Platform.isMacOS) {
      return [l10n.macWidgetStep1, l10n.macWidgetStep2, l10n.macWidgetStep3];
    }
    if (Platform.isAndroid) {
      return [
        l10n.androidWidgetStep1,
        l10n.androidWidgetStep2,
        l10n.androidWidgetStep3,
        l10n.androidWidgetStep4,
      ];
    }
    return [l10n.genericWidgetStep1, l10n.genericWidgetStep2];
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.howToAddWidget, style: theme.textTheme.titleSmall),
        SizedBox(height: space.sm),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : space.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      height: 1,
                    ),
                    textScaler: TextScaler.noScaling,
                  ),
                ),
                SizedBox(width: space.sm),
                Expanded(
                  child: Text(
                    steps[i],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One choosable widget theme: its own colors, a glyph in the content
/// color, the name under it.
class WidgetThemeSwatch {
  const WidgetThemeSwatch({
    required this.id,
    required this.label,
    required this.background,
    required this.foreground,
    required this.selected,
    required this.onTap,
    this.automatic = false,
  });

  final String id;
  final String label;
  final Color background;
  final Color foreground;
  final bool selected;
  final VoidCallback onTap;

  /// "Automatic" follows the app's colors: drawn as the palette's
  /// gradient from [background] to [foreground] with a sparkle.
  final bool automatic;
}

/// The widget themes as a grid of swatches (as many columns as fit, 4–8,
/// even across a fold), the chosen one ringed with a check.
class WidgetThemeGrid extends StatelessWidget {
  const WidgetThemeGrid({super.key, required this.swatches, this.glyph});

  final List<WidgetThemeSwatch> swatches;

  /// What each swatch shows in its content color ("Aa", or an Arabic
  /// letter for the Quran widget).
  final Widget Function(Color color)? glyph;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final fold = FoldInfo.of(context);
    final scale = math.min(MediaQuery.textScalerOf(context).scale(16) / 16, 2);
    return LayoutBuilder(
      builder: (context, constraints) {
        final minTile = 64 * math.max(1.0, scale * 0.85);
        var columns = ((constraints.maxWidth + space.sm) / (minTile + space.sm))
            .floor()
            .clamp(3, 8);
        if (fold.hasFold && columns.isOdd && columns > 3) columns--;
        final rows = <Widget>[];
        for (var i = 0; i < swatches.length; i += columns) {
          if (i > 0) rows.add(SizedBox(height: space.sm));
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < columns; j++) ...[
                  if (j > 0) SizedBox(width: space.sm),
                  Expanded(
                    child: i + j < swatches.length
                        ? _SwatchTile(swatch: swatches[i + j], glyph: glyph)
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        }
        return Column(mainAxisSize: MainAxisSize.min, children: rows);
      },
    );
  }
}

class _SwatchTile extends StatelessWidget {
  const _SwatchTile({required this.swatch, required this.glyph});

  final WidgetThemeSwatch swatch;
  final Widget Function(Color color)? glyph;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final duration = tokens.motion.of(context, tokens.motion.short);
    final radius = BorderRadius.circular(tokens.radius.md);
    final selected = swatch.selected;
    final glyph = this.glyph;
    return Semantics(
      key: ValueKey('widgets-theme-${swatch.id}'),
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: swatch.label,
      excludeSemantics: true,
      child: HudaPressable(
        child: InkWell(
          onTap: () {
            if (selected) return;
            HudaHaptics.selection(context);
            swatch.onTap();
          },
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
                      borderRadius: BorderRadius.circular(tokens.radius.md + 3),
                      border: Border.all(
                        color: selected
                            ? scheme.primary
                            : scheme.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: radius,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: swatch.background,
                              gradient: swatch.automatic
                                  ? LinearGradient(
                                      begin: AlignmentDirectional.topStart,
                                      end: AlignmentDirectional.bottomEnd,
                                      colors: [
                                        swatch.background,
                                        swatch.foreground,
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                          if (!swatch.automatic && glyph != null)
                            Center(child: glyph(swatch.foreground)),
                          if (swatch.automatic)
                            Center(
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                size: 22,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          if (selected)
                            PositionedDirectional(
                              top: 4,
                              end: 4,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 13,
                                  color: scheme.onPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: space.xxs),
                Text(
                  swatch.label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
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

/// A widget text size: its label and value (or "Automatic" while the
/// widget fits the text itself), and a slider in steps of 5%.
class WidgetSizeControl extends StatelessWidget {
  const WidgetSizeControl({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
    this.automaticLabel,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  /// Shown instead of the value while the slider is off (auto fit).
  final String? automaticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = automaticLabel == null;
    final muted = scheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
            SizedBox(width: space.sm),
            Text(
              automaticLabel ?? '$value%',
              style: theme.textTheme.labelLarge?.copyWith(
                color: enabled ? scheme.primary : muted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Row(
          children: [
            ExcludeSemantics(
              child: Text(
                'A',
                textDirection: TextDirection.ltr,
                style: theme.textTheme.labelMedium?.copyWith(color: muted),
              ),
            ),
            Expanded(
              child: Slider(
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: (max - min) ~/ 5,
                value: value.clamp(min, max).toDouble(),
                label: '$value%',
                semanticFormatterCallback: (v) => '${v.round()}%',
                onChanged: enabled
                    ? (next) {
                        HudaHaptics.selection(context);
                        onChanged(next.round());
                      }
                    : null,
                onChangeEnd: enabled
                    ? (next) => onChangeEnd(next.round())
                    : null,
              ),
            ),
            ExcludeSemantics(
              child: Text(
                'A',
                textDirection: TextDirection.ltr,
                style: theme.textTheme.titleLarge?.copyWith(color: muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A switch as a compact row inside a card (no icon mark): the label and
/// the switch; the whole row toggles.
class WidgetSwitchRow extends StatelessWidget {
  const WidgetSwitchRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final theme = Theme.of(context);
    void toggle(bool next) {
      HudaHaptics.selection(context);
      onChanged(next);
    }

    return MergeSemantics(
      child: InkWell(
        onTap: () => toggle(!value),
        borderRadius: BorderRadius.circular(context.tokens.radius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
              SizedBox(width: space.sm),
              Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
              SizedBox(width: space.sm),
              Switch(value: value, onChanged: toggle),
            ],
          ),
        ),
      ),
    );
  }
}

/// Update the widget now, and Reset to the defaults (confirmed). Updating
/// shows the lamp spinner and its label until it finishes.
class WidgetAdvancedSection extends StatelessWidget {
  const WidgetAdvancedSection({
    super.key,
    required this.refreshLabel,
    required this.refreshingLabel,
    required this.refreshing,
    required this.onRefresh,
    required this.onReset,
  });

  final String refreshLabel;
  final String refreshingLabel;
  final bool refreshing;
  final VoidCallback onRefresh;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HudaSectionHeader(l10n.advanced),
        OutlinedButton.icon(
          key: const ValueKey('widgets-refresh'),
          onPressed: refreshing ? null : onRefresh,
          icon: refreshing
              ? const HudaLampSpinner(size: 20)
              : const Icon(Icons.refresh_rounded),
          label: Text(refreshing ? refreshingLabel : refreshLabel),
        ),
        SizedBox(height: space.xs),
        TextButton.icon(
          key: const ValueKey('widgets-reset'),
          onPressed: onReset,
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text(l10n.resetWidgetCustomization),
        ),
      ],
    );
  }
}

/// Asks before putting a widget's settings back to the defaults.
Future<bool> confirmWidgetReset(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.resetWidgetCustomization),
      content: Text(l10n.widgetResetConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('widgets-reset-confirm'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.reset),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) HudaHaptics.light(context);
  return confirmed == true;
}
