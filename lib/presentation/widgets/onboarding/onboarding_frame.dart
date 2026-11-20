import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/theme/huda_lantern_border.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/cubit/onboarding/onboarding_environment.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/notifications/notification_access_controller.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_stage.dart';

class OnboardingScope extends InheritedWidget {
  const OnboardingScope({
    super.key,
    required this.environment,
    required this.access,
    required this.finish,
    required this.switchLanguage,
    required this.veil,
    required this.sheet,
    required super.child,
  });

  final OnboardingEnvironment environment;
  final NotificationAccessController access;

  final Future<void> Function() finish;

  final Future<void> Function(Locale locale) switchLanguage;

  final Animation<double> veil;

  final OnboardingSession sheet;

  static OnboardingScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OnboardingScope>()!;

  static OnboardingScope read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<OnboardingScope>()!;

  @override
  bool updateShouldNotify(OnboardingScope oldWidget) =>
      oldWidget.environment != environment ||
      oldWidget.access != access ||
      oldWidget.finish != finish ||
      oldWidget.switchLanguage != switchLanguage ||
      oldWidget.veil != veil ||
      oldWidget.sheet != sheet;
}

class OnboardingSession {
  double? top;
  bool notificationsDeclined = false;
}

enum OnboardingFrameMode { stacked, pane }

class OnboardingStepSlot extends InheritedWidget {
  const OnboardingStepSlot({
    super.key,
    required this.step,
    required this.mode,
    required this.incoming,
    required this.animation,
    required this.direction,
    required super.child,
  });

  final OnboardingStep step;
  final OnboardingFrameMode mode;
  final bool incoming;
  final Animation<double> animation;

  final int direction;

  static OnboardingStepSlot? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OnboardingStepSlot>();

  @override
  bool updateShouldNotify(OnboardingStepSlot oldWidget) =>
      oldWidget.step != step ||
      oldWidget.mode != mode ||
      oldWidget.incoming != incoming ||
      oldWidget.animation != animation ||
      oldWidget.direction != direction;
}

@immutable
class OnboardingAction {
  const OnboardingAction(
    this.label, {
    this.onPressed,
    this.busyLabel,
    this.key,
    this.advances = false,
    this.icon,
  });

  final String label;

  final IconData? icon;

  final bool advances;

  final VoidCallback? onPressed;

  final String? busyLabel;
  final Key? key;
}

const IconData onboardingSkipIcon = Icons.skip_next_rounded;

const double onboardingContentWidth = 560;

const double onboardingWideContentWidth = 720;

class OnboardingStepFrame extends StatelessWidget {
  const OnboardingStepFrame({
    super.key,
    this.message,
    required this.children,
    this.primary,
    this.quiet,
    this.veilContent = true,
  });

  final String? message;
  final List<Widget> children;
  final OnboardingAction? primary;
  final OnboardingAction? quiet;

  final bool veilContent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final scope = OnboardingScope.of(context);
    final slot = OnboardingStepSlot.maybeOf(context);
    final step = slot?.step ?? context.read<OnboardingCubit>().state.current;
    final mode = slot?.mode ?? OnboardingFrameMode.stacked;
    final reviewing = context.select<OnboardingCubit, bool>(
      (cubit) => cubit.state.reviewing,
    );
    final canGoBack = context.select<OnboardingCubit, bool>(
      (cubit) =>
          cubit.state.canGoBack &&
          !cubit.state.reviewing &&
          !cubit.state.finishing,
    );
    final VoidCallback? back = canGoBack
        ? () => context.read<OnboardingCubit>().back()
        : null;
    final l10n = AppLocalizations.of(context)!;
    final given = this.primary;
    final OnboardingAction? primary;
    final OnboardingAction? quiet;
    if (!reviewing) {
      primary = given;
      quiet = this.quiet;
    } else if (given != null && given.advances) {
      primary = OnboardingAction(
        l10n.done,
        key: given.key,
        busyLabel: given.busyLabel,
        onPressed: given.onPressed,
        advances: true,
      );
      quiet = null;
    } else {
      primary = given;
      quiet = OnboardingAction(
        l10n.done,
        icon: Icons.check_rounded,
        key: const ValueKey('onboarding-review-done'),
        onPressed: () => context.read<OnboardingCubit>().back(),
      );
    }

    Widget words(Widget child, {bool slide = true, bool veiled = true}) =>
        veiled ? FadeTransition(opacity: scope.veil, child: child) : child;

    final message = this.message;
    var index = 0;
    Widget reveal(Widget child) => HudaReveal(index: index++, child: child);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message != null) ...[
          reveal(
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(height: space.lg),
        ],
        for (final child in children) reveal(child),
      ],
    );
    final hasActions = primary != null || quiet != null || back != null;
    final gutter = space.gutter(media.size.width);

    if (mode == OnboardingFrameMode.pane) {
      return _PaneStep(
        veilContent: veilContent,
        veil: scope.veil,
        heading: OnboardingStepHeading(step: step),
        content: content,
        primary: primary,
        quiet: quiet,
        back: back,
        words: words,
      );
    }

    const sheetWidth = double.infinity;
    final scale = (media.textScaler.scale(16) / 16).clamp(1.0, 1.6);
    final surface = theme.colorScheme.surface;
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: _StageFill(
                viewport: constraints.maxHeight,
                panelMinHeight: 0,
                surface: surface,
                radius: tokens.radius.xl,
                sheetWidth: sheetWidth,
                paintSurface: true,
                enter: kAlwaysCompleteAnimation,
                memory: scope.sheet,
                stage: OnboardingStage(
                  step: step,
                  band: constraints.maxHeight < 560 * scale,
                ),
                panel: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: sheetWidth),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        gutter + media.padding.left,
                        space.xl,
                        gutter + media.padding.right,
                        space.lg,
                      ),
                      child: ReadableWidth(
                        maxWidth: onboardingContentWidth,
                        child: words(content, veiled: veilContent),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasActions)
          OnboardingActionBar(
            primary: primary,
            quiet: quiet,
            back: back,
            surface: true,
            sheetWidth: sheetWidth,
            wrap: (child) => words(child, slide: false),
          ),
      ],
    );
  }
}

class _PaneStep extends StatefulWidget {
  const _PaneStep({
    required this.heading,
    required this.content,
    required this.primary,
    required this.quiet,
    required this.back,
    required this.words,
    required this.veilContent,
    required this.veil,
  });

  final Widget heading;
  final Widget content;
  final OnboardingAction? primary;
  final OnboardingAction? quiet;
  final VoidCallback? back;
  final Widget Function(Widget child, {bool slide, bool veiled}) words;
  final bool veilContent;
  final Animation<double> veil;

  @override
  State<_PaneStep> createState() => _PaneStepState();
}

class _PaneStepState extends State<_PaneStep> {
  static const double _maxBlockHeight = 640;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final media = MediaQuery.of(context);
    final gutter = space.gutter(media.size.width);
    final hasActions =
        widget.primary != null || widget.quiet != null || widget.back != null;
    Widget veiled(Widget child) => widget.veilContent
        ? child
        : FadeTransition(opacity: widget.veil, child: child);
    return LayoutBuilder(
      builder: (context, outer) {
        final maxWidth = outer.maxWidth >= 860
            ? onboardingWideContentWidth
            : onboardingContentWidth;
        final bounded = outer.maxHeight > _maxBlockHeight + 2 * space.xxl;
        final blockHeight = bounded ? _maxBlockHeight : outer.maxHeight;
        final scroll = SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            gutter + (bounded ? 0 : media.padding.left),
            bounded
                ? 0
                : (outer.maxHeight < 480 ? space.lg : space.xxl) +
                      media.padding.top,
            gutter + (bounded ? 0 : media.padding.right),
            space.lg,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ReadableWidth(
              maxWidth: maxWidth,
              child: widget.words(
                veiled: widget.veilContent,
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [veiled(widget.heading), widget.content],
                ),
              ),
            ),
          ),
        );
        final block = Column(
          children: [
            Expanded(child: scroll),
            if (hasActions)
              MediaQuery.removePadding(
                context: context,
                removeBottom: bounded,
                child: OnboardingActionBar(
                  primary: widget.primary,
                  quiet: widget.quiet,
                  back: widget.back,
                  sheetWidth: maxWidth + 2 * gutter,
                  contentWidth: maxWidth,
                  wrap: (child) => widget.words(child, slide: false),
                ),
              ),
          ],
        );
        if (!bounded) return block;
        return Center(
          child: SizedBox(height: blockHeight, child: block),
        );
      },
    );
  }
}

enum _FillSlot { stage, panel }

class _StageFill
    extends SlottedMultiChildRenderObjectWidget<_FillSlot, RenderBox> {
  const _StageFill({
    required this.stage,
    required this.panel,
    required this.viewport,
    this.panelMinHeight = 0,
    required this.surface,
    required this.radius,
    required this.sheetWidth,
    required this.paintSurface,
    required this.enter,
    required this.memory,
  });

  final Widget stage;
  final Widget panel;
  final double viewport;
  final double panelMinHeight;
  final Color surface;
  final double radius;
  final double sheetWidth;
  final bool paintSurface;
  final Animation<double> enter;
  final OnboardingSession memory;

  @override
  Iterable<_FillSlot> get slots => _FillSlot.values;

  @override
  Widget? childForSlot(_FillSlot slot) => switch (slot) {
    _FillSlot.stage => stage,
    _FillSlot.panel => panel,
  };

  @override
  _RenderStageFill createRenderObject(BuildContext context) => _RenderStageFill(
    viewport: viewport,
    panelMinHeight: panelMinHeight,
    surface: surface,
    radius: radius,
    sheetWidth: sheetWidth,
    paintSurface: paintSurface,
    enter: enter,
    memory: memory,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderStageFill render) {
    render
      ..viewport = viewport
      ..panelMinHeight = panelMinHeight
      ..surface = surface
      ..radius = radius
      ..sheetWidth = sheetWidth
      ..paintSurface = paintSurface
      ..enter = enter
      ..memory = memory;
  }
}

class _RenderStageFill extends RenderBox
    with SlottedContainerRenderObjectMixin<_FillSlot, RenderBox> {
  _RenderStageFill({
    required double viewport,
    required double panelMinHeight,
    required Color surface,
    required double radius,
    required double sheetWidth,
    required bool paintSurface,
    required Animation<double> enter,
    required this.memory,
  }) : _viewport = viewport,
       _panelMinHeight = panelMinHeight,
       _surface = surface,
       _radius = radius,
       _sheetWidth = sheetWidth,
       _paintSurface = paintSurface,
       _enter = enter;

  double _viewport;
  set viewport(double value) {
    if (value == _viewport) return;
    _viewport = value;
    markNeedsLayout();
  }

  double _panelMinHeight;
  set panelMinHeight(double value) {
    if (value == _panelMinHeight) return;
    _panelMinHeight = value;
    markNeedsLayout();
  }

  Color _surface;
  set surface(Color value) {
    if (value == _surface) return;
    _surface = value;
    markNeedsPaint();
  }

  double _radius;
  set radius(double value) {
    if (value == _radius) return;
    _radius = value;
    markNeedsPaint();
  }

  double _sheetWidth;
  set sheetWidth(double value) {
    if (value == _sheetWidth) return;
    _sheetWidth = value;
    markNeedsPaint();
  }

  bool _paintSurface;
  set paintSurface(bool value) {
    if (value == _paintSurface) return;
    _paintSurface = value;
    markNeedsPaint();
  }

  Animation<double> _enter;
  set enter(Animation<double> value) {
    if (value == _enter) return;
    if (attached) _enter.removeListener(markNeedsPaint);
    _enter = value;
    if (attached) _enter.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  OnboardingSession memory;

  double? _from;
  bool _captured = false;
  double _top = 0;

  RenderBox? get _stage => childForSlot(_FillSlot.stage);
  RenderBox? get _panel => childForSlot(_FillSlot.panel);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _enter.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _enter.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) child.parentData = BoxParentData();
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final panel = _panel;
    final stage = _stage;
    var panelHeight = 0.0;
    if (panel != null) {
      panel.layout(
        BoxConstraints(
          minWidth: width,
          maxWidth: width,
          minHeight: _panelMinHeight,
        ),
        parentUsesSize: true,
      );
      panelHeight = panel.size.height;
    }
    var stageHeight = 0.0;
    if (stage != null) {
      stage.layout(
        BoxConstraints(
          minWidth: width,
          maxWidth: width,
          minHeight: math.max(0, _viewport - panelHeight),
        ),
        parentUsesSize: true,
      );
      stageHeight = stage.size.height;
      (stage.parentData! as BoxParentData).offset = Offset.zero;
    }
    if (panel != null) {
      (panel.parentData! as BoxParentData).offset = Offset(0, stageHeight);
    }
    _top = stageHeight;
    if (_paintSurface) {
      if (!_captured) {
        _from = memory.top;
        _captured = true;
      }
      memory.top = _top;
    }
    size = constraints.constrain(Size(width, stageHeight + panelHeight));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_paintSurface) {
      final from = _from ?? _top;
      final top = from + (_top - from) * _enter.value;
      final width = math.min(size.width, _sheetWidth);
      final left = offset.dx + (size.width - width) / 2;
      final radius = Radius.circular(_radius);
      context.canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(
            left,
            offset.dy + top,
            left + width,
            offset.dy + math.max(size.height, top + _viewport),
          ),
          topLeft: radius,
          topRight: radius,
        ),
        Paint()..color = _surface,
      );
    }
    for (final child in [_stage, _panel]) {
      if (child == null) continue;
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in [_panel, _stage]) {
      if (child == null) continue;
      final hit = result.addWithPaintOffset(
        offset: (child.parentData! as BoxParentData).offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;
  @override
  double computeMaxIntrinsicWidth(double height) => 0;
  @override
  double computeMinIntrinsicHeight(double width) => 0;
  @override
  double computeMaxIntrinsicHeight(double width) => 0;
}

class OnboardingActionBar extends StatelessWidget {
  const OnboardingActionBar({
    super.key,
    this.primary,
    this.quiet,
    this.back,
    this.inline = false,
    this.surface = true,
    this.sheetWidth = double.infinity,
    this.contentWidth = onboardingContentWidth,
    this.wrap,
  });

  final OnboardingAction? primary;
  final OnboardingAction? quiet;

  final VoidCallback? back;
  final bool inline;

  final bool surface;
  final double sheetWidth;

  final double contentWidth;

  final Widget Function(Widget child)? wrap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final gutter = space.gutter(media.size.width);
    final primary = this.primary;
    final quiet = this.quiet;
    final l10n = AppLocalizations.of(context)!;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final lit = primary == null ? null : _LitButton(action: primary);
    Widget quietButton({
      Key? key,
      required String label,
      required IconData icon,
      required VoidCallback? onPressed,
      bool flip = false,
    }) => TextButton.icon(
      key: key,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(64, 52),
        padding: EdgeInsets.symmetric(horizontal: space.sm),
      ),
      icon: flip && rtl
          ? Transform.flip(flipX: true, child: Icon(icon, size: 20))
          : Icon(icon, size: 20),
      label: Text(label, textAlign: TextAlign.center),
    );
    final back = this.back;
    final body = theme.textTheme.labelLarge?.fontSize ?? 15;
    final scale = media.textScaler.scale(body) / body;
    final available = math.min(
      math.min(media.size.width, sheetWidth) - 2 * gutter,
      contentWidth,
    );
    final largeText = scale >= 1.5;
    final backLabeled =
        !largeText &&
        l10n.back.length * body * 0.55 * scale + 56 <= available / 3;
    Widget backControl(VoidCallback? onPressed) => backLabeled
        ? quietButton(
            key: onPressed == null ? null : const ValueKey('onboarding-back'),
            label: l10n.back,
            icon: Icons.arrow_back_rounded,
            onPressed: onPressed,
          )
        : IconButton(
            key: onPressed == null ? null : const ValueKey('onboarding-back'),
            tooltip: l10n.back,
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_back_rounded),
          );
    final backSlot = back == null ? null : backControl(back);
    final soft = quiet == null
        ? null
        : quiet.icon == null
        ? TextButton(
            key: quiet.key,
            onPressed: quiet.onPressed,
            style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
            child: Text(quiet.label, textAlign: TextAlign.center),
          )
        : quietButton(
            key: quiet.key,
            label: quiet.label,
            icon: quiet.icon!,
            onPressed: quiet.onPressed,
            flip: quiet.icon == onboardingSkipIcon,
          );
    final litWidth = (available * 0.5).clamp(160.0, 280.0);
    Widget buttons = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (soft != null) ...[
          Align(alignment: AlignmentDirectional.centerEnd, child: soft),
          SizedBox(height: space.xxs),
        ],
        Row(
          children: [
            ?backSlot,
            if (largeText && lit != null) ...[
              if (backSlot != null) SizedBox(width: space.sm),
              Expanded(child: lit),
            ] else ...[
              const Spacer(),
              if (lit != null)
                SizedBox(width: math.min(litWidth, available), child: lit),
            ],
          ],
        ),
      ],
    );
    buttons = wrap?.call(buttons) ?? buttons;
    if (inline) return buttons;
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: sheetWidth),
        child: ColoredBox(
          color: surface ? theme.colorScheme.surface : Colors.transparent,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              gutter + media.padding.left,
              space.xs,
              gutter + media.padding.right,
              space.sm + context.bottomInset,
            ),
            child: ReadableWidth(maxWidth: contentWidth, child: buttons),
          ),
        ),
      ),
    );
  }
}

class _LitButton extends StatelessWidget {
  const _LitButton({required this.action});

  final OnboardingAction action;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final busy = action.busyLabel;
    final duration = tokens.motion.of(context, tokens.motion.short);
    final Widget child;
    if (busy != null) {
      child = Semantics(
        key: const ValueKey('busy'),
        liveRegion: true,
        label: busy,
        excludeSemantics: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: ShapeDecoration(
            color: tokens.lit,
            shape: HudaLanternBorder(
              radius: tokens.radius.md,
              engraving: tokens.onChrome.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HudaLampSpinner(
                size: MediaQuery.textScalerOf(context).scale(18),
                color: tokens.gilt,
              ),
              SizedBox(width: tokens.space.sm),
              Flexible(
                child: Text(
                  busy,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: tokens.onChrome),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      child = action.advances
          ? FilledButton.icon(
              key: action.key ?? ValueKey(action.label),
              onPressed: action.onPressed,
              style: FilledButton.styleFrom(minimumSize: const Size(64, 52)),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: Text(action.label, textAlign: TextAlign.center),
            )
          : FilledButton(
              key: action.key ?? ValueKey(action.label),
              onPressed: action.onPressed,
              style: FilledButton.styleFrom(minimumSize: const Size(64, 52)),
              child: Text(action.label, textAlign: TextAlign.center),
            );
    }
    return AnimatedSwitcher(
      duration: duration,
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.center,
        children: [...previous, ?current],
      ),
      child: child,
    );
  }
}

class OnboardingOption extends StatelessWidget {
  const OnboardingOption({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.preview,
    this.previewWidth = 88,
    this.badge,
    this.detail,
    this.previewAbove = false,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  final Widget? leading;

  final Widget? preview;
  final double previewWidth;

  final String? badge;

  final bool previewAbove;

  final String? detail;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final duration = tokens.motion.of(context, tokens.motion.short);
    final fill = selected
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: dark ? 0.16 : 0.07),
            scheme.surface,
          )
        : scheme.surface;
    final subtitle = this.subtitle;
    final badge = this.badge;
    final detail = this.detail;
    final radio = AnimatedContainer(
      duration: duration,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
          width: selected ? 6.5 : 1.5,
        ),
      ),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: space.xs,
          runSpacing: space.xxs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            if (badge != null)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: space.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: scheme.tertiary.withValues(alpha: dark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(tokens.radius.sm),
                ),
                child: Text(
                  badge,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.tertiary,
                  ),
                ),
              ),
          ],
        ),
        if (subtitle != null) ...[
          SizedBox(height: space.xxs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        if (detail != null) ...[
          SizedBox(height: space.xs),
          Text(
            detail,
            style: theme.textTheme.titleSmall?.copyWith(
              color: selected ? scheme.primary : scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
    final preview = this.preview;
    final inGrid = (_OptionColumns.of(context) ?? 1) > 1 || previewAbove;
    final leading =
        this.leading ??
        (preview != null && !inGrid
            ? SizedBox(width: previewWidth, child: preview)
            : null);
    final content = preview != null && inGrid
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  preview,
                  PositionedDirectional(
                    top: space.xs,
                    end: space.xs,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.surface,
                        border: Border.all(color: scheme.surface, width: 3),
                      ),
                      child: radio,
                    ),
                  ),
                ],
              ),
              SizedBox(height: space.sm),
              text,
            ],
          )
        : Row(
            children: [
              if (leading != null) ...[leading, SizedBox(width: space.sm)],
              Expanded(child: text),
              SizedBox(width: space.sm),
              radio,
            ],
          );
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: HudaPressable(
        child: Material(
          color: fill,
          shape: RoundedRectangleBorder(
            borderRadius: tokens.radius.card,
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (!selected) HudaHaptics.selection(context);
              onTap();
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: EdgeInsets.all(inGrid ? space.sm : space.md),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingOptionGrid extends StatelessWidget {
  const OnboardingOptionGrid({
    super.key,
    required this.children,
    this.minTileWidth = 240,
    this.maxColumns = 2,
    this.columnChoices,
  });

  final List<Widget> children;
  final double minTileWidth;
  final int maxColumns;

  final List<int>? columnChoices;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return LayoutBuilder(
      builder: (context, constraints) {
        final fit =
            ((constraints.maxWidth + space.sm) /
                    (minTileWidth * scale + space.sm))
                .floor()
                .clamp(1, maxColumns);
        final choices = columnChoices;
        final columns = choices == null
            ? fit
            : choices.where((count) => count <= fit).fold(1, math.max);
        if (columns == 1) {
          return _OptionColumns(
            columns: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) SizedBox(height: space.sm),
                  children[i],
                ],
              ],
            ),
          );
        }
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += columns) {
          if (i > 0) rows.add(SizedBox(height: space.sm));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) SizedBox(width: space.sm),
                    Expanded(
                      child: i + j < children.length
                          ? children[i + j]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return _OptionColumns(
          columns: columns,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          ),
        );
      },
    );
  }
}

class _OptionColumns extends InheritedWidget {
  const _OptionColumns({required this.columns, required super.child});

  final int columns;

  static int? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_OptionColumns>()?.columns;

  @override
  bool updateShouldNotify(_OptionColumns oldWidget) =>
      oldWidget.columns != columns;
}

class OnboardingNotice extends StatelessWidget {
  const OnboardingNotice({
    super.key,
    required this.message,
    this.title,
    this.problem = false,
    this.icon,
    this.trailing,
  });

  final String? title;
  final String message;
  final bool problem;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    Color tint(Color color, double light, double night) => Color.alphaBlend(
      color.withValues(alpha: dark ? night : light),
      scheme.surface,
    );
    final title = this.title;
    final trailing = this.trailing;
    final lamp = problem
        ? Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint(scheme.error, 0.12, 0.22),
            ),
            alignment: Alignment.center,
            child: HudaKhatamMark(color: scheme.error, size: 20),
          )
        : HudaLamp(
            size: 40,
            child: Icon(
              icon ?? Icons.check_rounded,
              size: 20,
              color: tokens.gilt,
            ),
          );
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: problem
              ? tint(scheme.error, 0.05, 0.1)
              : tint(scheme.primary, 0.04, 0.08),
          borderRadius: tokens.radius.card,
          border: Border.all(
            color: problem
                ? tint(scheme.error, 0.22, 0.3)
                : scheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(space.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: lamp),
              SizedBox(width: space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[
                      Text(title, style: theme.textTheme.titleSmall),
                      SizedBox(height: space.xxs),
                    ],
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (trailing != null) ...[
                      SizedBox(height: space.xs),
                      trailing,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingLink extends StatelessWidget {
  const OnboardingLink({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
  );
}
