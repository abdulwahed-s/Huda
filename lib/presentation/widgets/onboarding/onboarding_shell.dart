import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_system_ui.dart';
import 'package:huda/core/theme/huda_theme_scope.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_frame.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_identity.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_stage.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_steps.dart';

enum _Layout { stacked, panes, tabletop }

class OnboardingShell extends StatefulWidget {
  const OnboardingShell({super.key, required this.onSkip});

  final VoidCallback onSkip;

  @override
  State<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends State<OnboardingShell> {
  final _stepsKey = GlobalKey(debugLabel: 'onboarding-steps');

  _Layout _layoutOf(BuildContext context) {
    if (TabletopSplit.applies(context)) return _Layout.tabletop;
    if (SideChrome.sideOf(context) != null) return _Layout.stacked;
    final size = MediaQuery.sizeOf(context);
    final compactHeight = context.windowClass.isCompactHeight;
    if (size.height > size.width && !FoldInfo.of(context).hasFold) {
      return _Layout.stacked;
    }
    return AdaptivePanes.showsTwoPanes(
          size.width,
          FoldInfo.of(context),
          twoPaneMinWidth: compactHeight ? 600 : 840,
        )
        ? _Layout.panes
        : _Layout.stacked;
  }

  Future<void> _confirmSkip(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final skip = await showHudaSheet<bool>(
      context: context,
      title: l10n.setupSkipAllTitle,
      maxDialogWidth: 440,
      builder: (context) => const _SkipAllSheet(
        key: ValueKey('onboarding-skip-confirm'),
      ),
    );
    if (skip == true && mounted) widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingCubit>().state;
    final cubit = context.read<OnboardingCubit>();
    final tokens = context.tokens;
    final page = Theme.of(context);
    final layout = _layoutOf(context);
    final compactHeight = context.windowClass.isCompactHeight;
    final back = !state.canGoBack || state.finishing || state.reviewing
        ? null
        : cubit.back;
    final skip = state.isLast || state.finishing || state.reviewing
        ? null
        : () => _confirmSkip(context);
    final width = MediaQuery.sizeOf(context).width;
    final veil = OnboardingScope.of(context).veil;
    final direction = Directionality.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(16) / 16 >= 1.5;

    Widget steps(OnboardingFrameMode mode) => KeyedSubtree(
      key: _stepsKey,
      child: Theme(
        data: page,
        child: _StepSwitcher(state: state, mode: mode),
      ),
    );

    final topRow = FadeTransition(
      opacity: veil,
      child: _TopRow(state: state, onSkip: skip),
    );

    Widget chromePane() => _Chrome(
      child: Builder(
        builder: (context) {
          final media = MediaQuery.of(context);
          return Padding(
            padding: EdgeInsets.only(
              top: media.padding.top,
              bottom: media.padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                topRow,
                Expanded(child: _StageSwitcher(step: state.current)),
              ],
            ),
          );
        },
      ),
    );

    final Widget body = switch (layout) {
      _Layout.tabletop => TabletopSplit(
        top: chromePane(),
        bottom: Material(
          color: page.colorScheme.surface,
          child: steps(OnboardingFrameMode.pane),
        ),
      ),
      _Layout.panes => Directionality(
        textDirection: TextDirection.ltr,
        child: AdaptivePanes(
          primary: Directionality(
            textDirection: direction,
            child: chromePane(),
          ),
          secondary: Directionality(
            textDirection: direction,
            child: Material(
              color: page.colorScheme.surface,
              child: steps(OnboardingFrameMode.pane),
            ),
          ),
          twoPaneMinWidth: compactHeight ? 600 : 840,
          primaryFraction: compactHeight || largeText
              ? 0.3
              : (width >= 1200 ? 0.5 : 0.4),
          minPrimaryWidth: compactHeight || largeText ? 220 : 320,
          maxPrimaryWidth: compactHeight || largeText
              ? 320
              : (width >= 1200 ? 820 : 460),
          divider: const SizedBox.shrink(),
        ),
      ),
      _Layout.stacked => _Chrome(
        child: Builder(
          builder: (context) {
            final media = MediaQuery.of(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: media.padding.top),
                topRow,
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: steps(OnboardingFrameMode.stacked),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    };

    final side = SideChrome.sideOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: HudaSystemUi.over(
        top: layout == _Layout.panes ? page.brightness : Brightness.dark,
        bottom: page.brightness,
      ),
      child: HudaChromeFrame(
        actions: [if (skip != null) _ColumnSkip(onPressed: skip)],
        columnForeground: tokens.onChrome,
        child: Scaffold(
          backgroundColor: tokens.chrome,
          body: GestureDetector(
            onHorizontalDragEnd: back == null
                ? null
                : (details) {
                    final v = details.primaryVelocity ?? 0;
                    final rtl = Directionality.of(context) == TextDirection.rtl;
                    if ((rtl ? -v : v) > 450) back();
                  },
            child: Stack(
              fit: StackFit.expand,
              children: [
                body,
                if (side != null && skip != null)
                  _ColumnTab(side: side, color: tokens.chrome),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chrome extends StatelessWidget {
  const _Chrome({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => HudaNight(
    child: Builder(
      builder: (context) {
        final tokens = context.tokens;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Ornament(
                  painter: StarFieldPainter(
                    style: OrnamentStyle(
                      color: tokens.gilt.withValues(alpha: 0.5),
                      stroke: tokens.stroke.hairline,
                      render: OrnamentRender.line,
                    ),
                    module: 44,
                    fade: AlignmentDirectional.bottomStart,
                  ),
                ),
              ),
            ),
            child,
          ],
        );
      },
    ),
  );
}

class _TopRow extends StatelessWidget {
  const _TopRow({required this.state, this.onSkip});

  final OnboardingState state;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final media = MediaQuery.of(context);
    final gutter = space.gutter(media.size.width);
    final inColumn = HudaChromeFrame.hasSideChrome(context);
    final onSkip = this.onSkip;
    final choices = state.steps.where((step) => step.isChoice).toList();
    final number = choices.indexOf(state.current) + 1;
    final lit = state.current == OnboardingStep.summary || state.reviewing
        ? choices.length
        : number;
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    bool fits(String text, double room) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textScaler: media.textScaler,
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width <= room;
    }

    final scale = media.textScaler.scale(16) / 16;
    final rowWidth =
        media.size.width - media.padding.horizontal - 2 * (gutter - space.xs);
    int linesFor(double room) => fits(l10n.setupSkipAll, room)
        ? 1
        : scale < 1.3 && fits(l10n.setupSkipAll, room * 2)
        ? 2
        : 0;
    final besideLines = linesFor(media.size.width * 0.4 - 58);
    final split =
        onSkip != null &&
        !inColumn &&
        (besideLines == 0 || media.size.width < 360);
    final skipLines = split ? linesFor(rowWidth - 58) : besideLines;
    final progress = OnboardingProgress(
      count: choices.length,
      lit: lit,
      semanticLabel: state.current.isChoice
          ? l10n.prayerSetupStepLabel(number, choices.length)
          : null,
    );
    final Widget? pill = onSkip == null || inColumn
        ? null
        : _SkipAllPill(onPressed: onSkip, lines: skipLines);
    final padding = EdgeInsets.only(
      left: media.padding.left + gutter - space.xs,
      right: media.padding.right + gutter - space.xs,
      top: space.xxs,
    );
    if (split) {
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(alignment: AlignmentDirectional.centerEnd, child: pill),
            SizedBox(height: space.xxs),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: space.xs),
              child: progress,
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: padding,
      child: SizedBox(
        height: kMinInteractiveDimension,
        child: Row(
          children: [
            const SizedBox(width: kMinInteractiveDimension),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: space.xs),
                child: progress,
              ),
            ),
            if (pill != null)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: media.size.width * 0.4),
                child: pill,
              )
            else
              const SizedBox(width: kMinInteractiveDimension),
          ],
        ),
      ),
    );
  }
}

class _SkipAllPill extends StatelessWidget {
  const _SkipAllPill({required this.onPressed, required this.lines});

  final VoidCallback onPressed;
  final int lines;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final style = TextButton.styleFrom(
      foregroundColor: tokens.onChromeMuted,
      overlayColor: tokens.gilt,
      minimumSize: const Size(48, 40),
      tapTargetSize: MaterialTapTargetSize.padded,
      padding: lines == 0
          ? EdgeInsets.zero
          : EdgeInsetsDirectional.only(
              start: tokens.space.sm,
              end: tokens.space.xs,
            ),
      shape: const StadiumBorder(),
    );
    final mark = Transform.flip(
      flipX: Directionality.of(context) == TextDirection.rtl,
      child: Icon(
        Icons.keyboard_double_arrow_right_rounded,
        size: lines == 0 ? 20 : 16,
        color: tokens.gilt,
      ),
    );
    if (lines == 0) {
      return Tooltip(
        message: l10n.setupSkipAll,
        child: TextButton(
          key: const ValueKey('onboarding-skip'),
          onPressed: onPressed,
          style: style,
          child: Semantics(label: l10n.setupSkipAll, child: mark),
        ),
      );
    }
    return TextButton.icon(
      key: const ValueKey('onboarding-skip'),
      onPressed: onPressed,
      iconAlignment: IconAlignment.end,
      style: style.copyWith(iconSize: const WidgetStatePropertyAll(16)),
      icon: mark,
      label: Text(
        l10n.setupSkipAll,
        maxLines: lines,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(height: 1.1),
      ),
    );
  }
}

class _ColumnSkip extends StatelessWidget {
  const _ColumnSkip({required this.onPressed});

  final VoidCallback onPressed;

  static double height(BuildContext context) =>
      kMinInteractiveDimension +
      2 * MediaQuery.textScalerOf(context).scale(12) * 1.3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    return Tooltip(
      message: l10n.setupSkipAll,
      child: InkWell(
        key: const ValueKey('onboarding-skip-column'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(tokens.radius.md),
        child: SizedBox(
          width: 72,
          height: height(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.flip(
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: Icon(
                  Icons.keyboard_double_arrow_right_rounded,
                  color: tokens.gilt,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.setupSkipAll,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tokens.onChromeMuted,
                  letterSpacing: 0,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColumnTab extends StatelessWidget {
  const _ColumnTab({required this.side, required this.color});

  final AxisDirection side;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final padding = MediaQuery.paddingOf(context);
    final left = side == AxisDirection.left;
    final height =
        SideChrome.freeTop(context, side) +
        tokens.space.xs +
        _ColumnSkip.height(context) +
        tokens.space.sm;
    final radius = Radius.circular(tokens.radius.lg);
    return Positioned(
      top: 0,
      height: height,
      left: left ? 0 : null,
      right: left ? null : 0,
      width: left ? padding.left : padding.right,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              bottomLeft: left ? Radius.zero : radius,
              bottomRight: left ? radius : Radius.zero,
            ),
          ),
        ),
      ),
    );
  }
}

class _StageSwitcher extends StatelessWidget {
  const _StageSwitcher({required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AnimatedSwitcher(
      duration: tokens.motion.of(context, tokens.motion.long),
      switchInCurve: tokens.motion.standard,
      switchOutCurve: tokens.motion.standard,
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      child: KeyedSubtree(
        key: ValueKey(step),
        child: OnboardingStage(step: step, artOnly: true),
      ),
    );
  }
}

class _SkipAllSheet extends StatelessWidget {
  const _SkipAllSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final skip = TextButton.icon(
      key: const ValueKey('onboarding-skip-confirmed'),
      onPressed: () => Navigator.of(context).pop(true),
      style: TextButton.styleFrom(minimumSize: const Size(48, 52)),
      iconAlignment: IconAlignment.end,
      icon: Transform.flip(
        flipX: rtl,
        child: const Icon(Icons.keyboard_double_arrow_right_rounded, size: 20),
      ),
      label: Text(l10n.setupSkipAll),
    );
    final keep = FilledButton(
      key: const ValueKey('onboarding-skip-keep'),
      onPressed: () => Navigator.of(context).pop(false),
      style: FilledButton.styleFrom(minimumSize: const Size(64, 52)),
      child: Text(l10n.setupKeepSettingUp, textAlign: TextAlign.center),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (scale < 1.5) ...[
              Ornament(
                size: Size(space.xxxl, space.huge),
                painter: OnboardingDoorwayPainter(
                  step: OnboardingStep.summary,
                  style: OrnamentStyle.of(context),
                  ground: scheme.surfaceContainerLow,
                ),
              ),
              SizedBox(width: space.md),
            ],
            Expanded(
              child: Text(
                l10n.setupSkipAllMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: space.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 300 * scale) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [keep, SizedBox(height: space.xs), skip],
              );
            }
            return Row(
              children: [
                Flexible(child: skip),
                SizedBox(width: space.sm),
                Expanded(child: keep),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PageBackdrop extends StatelessWidget {
  const _PageBackdrop({required this.mode, required this.child});

  final OnboardingFrameMode mode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (mode == OnboardingFrameMode.pane) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: child,
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: _Chrome(child: SizedBox.expand())),
        child,
      ],
    );
  }
}

class _StepSwitcher extends StatelessWidget {
  const _StepSwitcher({required this.state, required this.mode});

  final OnboardingState state;
  final OnboardingFrameMode mode;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final key = ValueKey(state.current);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final shift = state.direction * (rtl ? -1.0 : 1.0);
    final curve = tokens.motion.emphasized;
    return ClipRect(
      child: AnimatedSwitcher(
        duration: tokens.motion.of(context, tokens.motion.long),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
        layoutBuilder: (current, previous) =>
            Stack(fit: StackFit.expand, children: [...previous, ?current]),
        transitionBuilder: (child, animation) {
          final step = (child.key! as ValueKey<OnboardingStep>).value;
          final incoming = child.key == key;
          final position = Tween<Offset>(
            begin: Offset(incoming ? shift : -shift, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve));
          return IgnorePointer(
            ignoring: !incoming,
            child: SlideTransition(
              position: position,
              child: _PageBackdrop(
                mode: mode,
                child: OnboardingStepSlot(
                  step: step,
                  mode: mode,
                  incoming: incoming,
                  animation: animation,
                  direction: state.direction,
                  child: child,
                ),
              ),
            ),
          );
        },
        child: KeyedSubtree(key: key, child: state.current.build()),
      ),
    );
  }
}
