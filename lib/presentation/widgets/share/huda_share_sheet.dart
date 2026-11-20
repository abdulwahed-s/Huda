import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_lantern_border.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/share/share_image_frame.dart';
import 'package:huda/presentation/widgets/share/share_image_saver.dart';

Future<void> showHudaShareSheet({
  required BuildContext context,
  required String title,
  required Widget card,
  required Future<void> Function() onShareImage,
  required VoidCallback onShareText,
  double cardWidth = BrandedShareFrame.width,
}) => showHudaSheet<void>(
  context: context,
  title: title,
  maxDialogWidth: 760,
  builder: (context) => HudaShareSheetBody(
    card: card,
    cardWidth: cardWidth,
    previewLabel: title,
    onShareImage: onShareImage,
    onShareText: onShareText,
  ),
);

class HudaShareSheetBody extends StatefulWidget {
  const HudaShareSheetBody({
    super.key,
    required this.card,
    required this.onShareImage,
    required this.onShareText,
    this.cardWidth = BrandedShareFrame.width,
    this.cardAspect,
    this.previewLabel,
    this.controls,
    this.onCopyText,
    this.onSaveImage,
  });

  final Widget card;
  final double cardWidth;

  final double? cardAspect;
  final String? previewLabel;
  final Future<void> Function() onShareImage;
  final VoidCallback onShareText;

  final Widget? controls;

  final VoidCallback? onCopyText;

  final Future<ShareImageSaveResult> Function()? onSaveImage;

  @override
  State<HudaShareSheetBody> createState() => _HudaShareSheetBodyState();
}

class _HudaShareSheetBodyState extends State<HudaShareSheetBody> {
  bool _generating = false;
  bool _copied = false;
  bool _saving = false;
  ShareImageSaveResult? _saved;
  Timer? _copiedTimer;
  final _failureKey = GlobalKey();

  @override
  void didUpdateWidget(HudaShareSheetBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.key != widget.card.key) {
      _copiedTimer?.cancel();
      _copied = false;
      _saved = null;
    }
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  void _copy() {
    widget.onCopyText?.call();
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _save() async {
    final save = widget.onSaveImage;
    if (save == null || _saving) return;
    setState(() {
      _saving = true;
      _saved = null;
    });
    var saved = ShareImageSaveResult.failed;
    try {
      saved = await save();
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _saved = saved;
        });
        if (saved == ShareImageSaveResult.saved) HudaHaptics.light(context);
        if (saved != ShareImageSaveResult.saved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final failure = _failureKey.currentContext;
            if (!mounted || failure == null || !failure.mounted) return;
            final position = Scrollable.maybeOf(failure)?.position;
            if (position == null) return;
            final motion = context.tokens.motion;
            final duration = motion.of(context, motion.medium);
            if (duration == Duration.zero) {
              position.jumpTo(position.maxScrollExtent);
            } else {
              position.animateTo(
                position.maxScrollExtent,
                duration: duration,
                curve: motion.standard,
              );
            }
          });
        }
      }
    }
  }

  Future<void> _shareImage() async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      await widget.onShareImage();
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final window = MediaQuery.sizeOf(context);
    final canShareImage = !PlatformUtils.isLinux;
    final actions = [
      if (canShareImage) ...[
        HudaShareOption(
          icon: Icons.image_outlined,
          label: _generating ? l10n.generatingImage : l10n.shareAsImage,
          lit: true,
          busy: _generating,
          onTap: _shareImage,
        ),
        SizedBox(height: space.sm, width: space.sm),
      ],
      LayoutBuilder(
        builder: (context, constraints) {
          final copy = widget.onCopyText != null;
          final save = widget.onSaveImage != null;
          final stacked =
              constraints.maxWidth <
              (copy || save ? 280 : 0) *
                  MediaQuery.textScalerOf(context).scale(1);
          final tiles = [
            HudaShareOption(
              icon: Icons.notes_rounded,
              label: l10n.shareAsText,
              compact: !stacked && (copy || save),
              onTap: widget.onShareText,
            ),
            if (copy)
              HudaShareOption(
                icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                label: _copied ? l10n.copiedToClipboard : l10n.copyText,
                compact: !stacked,
                onTap: _copy,
              ),
            if (save)
              HudaShareOption(
                icon: _saved == ShareImageSaveResult.saved
                    ? Icons.check_rounded
                    : Icons.download_rounded,
                label: _saving
                    ? l10n.generatingImage
                    : _saved == ShareImageSaveResult.saved
                    ? (PlatformUtils.isDesktop
                          ? l10n.shareImageSavedDownloads
                          : l10n.shareImageSaved)
                    : l10n.shareSaveImage,
                busy: _saving,
                compact: !stacked,
                onTap: _save,
              ),
          ];
          if (stacked || tiles.length == 1) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) SizedBox(height: space.sm),
                  tiles[i],
                ],
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) SizedBox(width: space.sm),
                  Expanded(child: tiles[i]),
                ],
              ],
            ),
          );
        },
      ),
    ];
    final failure = switch (_saved) {
      null || ShareImageSaveResult.saved => null,
      final result => HudaStatusBanner(
        key: _failureKey,
        status: HudaStatus.failed,
        message: result == ShareImageSaveResult.unavailable
            ? l10n.shareSaveUnavailable
            : l10n.shareSaveFailed,
      ),
    };
    final controls = widget.controls;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side =
            constraints.maxWidth >= 600 ||
            (constraints.maxWidth >= 420 && window.height < 600);
        var previewHeight =
            (window.height * (side ? 0.62 : (window.height < 700 ? 0.24 : 0.3)))
                .clamp(160.0, 560.0)
                .clamp(0.0, (window.height - 220).clamp(160.0, 560.0));
        final column = SideChrome.sideOf(context);
        final besideOptions =
            column != null &&
            !side &&
            controls != null &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.3;
        if (column != null && !side) {
          final room = window.height - SideChrome.freeTop(context, column);
          previewHeight = besideOptions
              ? math.min(previewHeight, 150.0)
              : math.min(previewHeight, math.max(140.0, room - 400));
        }
        final motion = context.tokens.motion;
        final change = motion.of(context, motion.medium);
        final preview = Semantics(
          label: widget.previewLabel,
          image: true,
          child: LayoutBuilder(
            builder: (context, room) => _EaseSize(
              duration: change,
              curve: motion.standard,
              child: AnimatedSwitcher(
                duration: change,
                layoutBuilder: (current, previous) => Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    for (final old in previous)
                      Positioned.fill(
                        child: OverflowBox(
                          maxWidth: room.maxWidth,
                          maxHeight: previewHeight,
                          child: old,
                        ),
                      ),
                    ?current,
                  ],
                ),
                child: (widget.cardAspect ?? 0) > 16 / 9
                    ? SizedBox(
                        key: ValueKey(widget.card.key),
                        width: math.min(
                          room.maxWidth,
                          math.max(
                            previewHeight * 9 / 16,
                            math.min(room.maxWidth * 0.62, 260),
                          ),
                        ),
                        height: previewHeight,
                        child: _ScrollingPreview(
                          child: MediaQuery.withNoTextScaling(
                            child: SizedBox(
                              width: widget.cardWidth,
                              child: widget.card,
                            ),
                          ),
                        ),
                      )
                    : ConstrainedBox(
                        key: ValueKey(widget.card.key),
                        constraints: BoxConstraints(maxHeight: previewHeight),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: MediaQuery.withNoTextScaling(
                            child: SizedBox(
                              width: widget.cardWidth,
                              child: widget.card,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        );
        if (side) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: window.height < 600 ? 2 : 3,
                child: Center(child: preview),
              ),
              SizedBox(width: space.xl),
              Expanded(
                flex: window.height < 600 ? 3 : 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (controls != null) ...[
                      controls,
                      SizedBox(height: space.lg),
                    ],
                    ...actions,
                    if (failure != null) ...[
                      SizedBox(height: space.sm),
                      failure,
                    ],
                  ],
                ),
              ),
            ],
          );
        }
        if (besideOptions) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, row) => Row(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: row.maxWidth * 0.4),
                      child: preview,
                    ),
                    SizedBox(width: space.md),
                    Expanded(child: controls),
                  ],
                ),
              ),
              SizedBox(height: space.lg),
              ...actions,
              if (failure != null) ...[SizedBox(height: space.sm), failure],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: preview),
            SizedBox(height: space.lg),
            if (controls != null) ...[controls, SizedBox(height: space.lg)],
            ...actions,
            if (failure != null) ...[SizedBox(height: space.sm), failure],
          ],
        );
      },
    );
  }
}

class HudaShareOption extends StatelessWidget {
  const HudaShareOption({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.lit = false,
    this.busy = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool lit;
  final bool busy;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final shape = HudaLanternBorder(
      radius: tokens.radius.lg,
      side: lit ? BorderSide.none : BorderSide(color: scheme.outline),
      engraving: lit ? tokens.onChrome.withValues(alpha: 0.24) : null,
    );
    final fade = tokens.motion.of(context, tokens.motion.medium);
    Widget swap(Widget child, {AlignmentGeometry? alignment}) =>
        AnimatedSwitcher(
          duration: fade,
          transitionBuilder: (child, animation) {
            final half = CurvedAnimation(
              parent: animation,
              curve: Interval(0.5, 1, curve: tokens.motion.standard),
            );
            return FadeTransition(
              opacity: half,
              child: ScaleTransition(
                scale: Tween(begin: 0.85, end: 1.0).animate(half),
                child: child,
              ),
            );
          },
          layoutBuilder: (current, previous) => Stack(
            alignment: alignment ?? Alignment.center,
            children: [...previous, ?current],
          ),
          child: child,
        );
    Widget spinner() => HudaLampSpinner(
      key: const ValueKey('busy'),
      size: 18,
      color: tokens.gilt,
    );
    final mark = lit
        ? HudaLamp(
            child: swap(busy ? spinner() : Icon(icon, key: ValueKey(icon))),
          )
        : HudaIconMark(icon);
    return Semantics(
      button: true,
      enabled: onTap != null && !busy,
      label: label,
      excludeSemantics: true,
      child: HudaPressable(
        enabled: onTap != null && !busy,
        child: Material(
          color: lit ? tokens.lit : scheme.surface,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: busy || onTap == null ? null : onTap,
            customBorder: shape,
            splashColor: lit ? tokens.onChrome.withValues(alpha: 0.12) : null,
            highlightColor: lit
                ? tokens.onChrome.withValues(alpha: 0.06)
                : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: compact
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          swap(
                            busy
                                ? SizedBox.square(
                                    key: const ValueKey('busy'),
                                    dimension: 38,
                                    child: Center(child: spinner()),
                                  )
                                : HudaIconMark(icon, key: ValueKey(icon)),
                          ),
                          const SizedBox(height: 6),
                          swap(
                            Text(
                              label,
                              key: ValueKey(label),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        12,
                        12,
                        16,
                        12,
                      ),
                      child: Row(
                        children: [
                          mark,
                          const SizedBox(width: 12),
                          Expanded(
                            child: swap(
                              Text(
                                label,
                                key: ValueKey(label),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: lit
                                      ? tokens.onChrome
                                      : scheme.onSurface,
                                ),
                              ),
                              alignment: AlignmentDirectional.centerStart,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EaseSize extends StatelessWidget {
  const _EaseSize({
    required this.duration,
    required this.curve,
    required this.child,
  });

  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  Widget build(BuildContext context) => duration == Duration.zero
      ? child
      : AnimatedSize(duration: duration, curve: curve, child: child);
}

class _ScrollingPreview extends StatefulWidget {
  const _ScrollingPreview({required this.child});

  final Widget child;

  @override
  State<_ScrollingPreview> createState() => _ScrollingPreviewState();
}

class _ScrollingPreviewState extends State<_ScrollingPreview> {
  final _controller = ScrollController();
  bool _more = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onMetrics(ScrollMetricsNotification notification) {
    final more = notification.metrics.extentAfter > 1;
    if (more != _more) setState(() => _more = more);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final list = NotificationListener<ScrollMetricsNotification>(
      onNotification: _onMetrics,
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: (n) => _onMetrics(
          ScrollMetricsNotification(metrics: n.metrics, context: context),
        ),
        child: SingleChildScrollView(
          controller: _controller,
          child: FittedBox(fit: BoxFit.fitWidth, child: widget.child),
        ),
      ),
    );
    return ClipRect(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.white,
            _more ? Colors.transparent : Colors.white,
          ],
          stops: const [0, 0.82, 1],
        ).createShader(bounds),
        child: list,
      ),
    );
  }
}

class HudaTickOption extends StatelessWidget {
  const HudaTickOption({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final motion = tokens.motion;
    final change = motion.of(context, motion.short);
    final radius = BorderRadius.circular(tokens.radius.md);
    final icon = this.icon;
    final tick = AnimatedContainer(
      duration: change,
      curve: motion.standard,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: value ? scheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(tokens.radius.sm),
        border: Border.all(
          color: value ? scheme.primary : scheme.onSurfaceVariant,
          width: 2,
        ),
      ),
      child: AnimatedSwitcher(
        duration: change,
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: value
            ? Icon(
                Icons.check_rounded,
                key: const ValueKey('ticked'),
                size: 18,
                color: scheme.onPrimary,
              )
            : const SizedBox.shrink(),
      ),
    );
    return Semantics(
      checked: value,
      label: label,
      excludeSemantics: true,
      child: HudaPressable(
        child: AnimatedContainer(
          duration: change,
          curve: motion.standard,
          decoration: BoxDecoration(
            color: value
                ? scheme.primary.withValues(alpha: 0.07)
                : Colors.transparent,
            borderRadius: radius,
            border: Border.all(
              color: value
                  ? scheme.primary.withValues(alpha: 0.55)
                  : scheme.outline,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => onChanged(!value),
              borderRadius: radius,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: LayoutBuilder(
                  builder: (context, constraints) => Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 16, 8),
                    child: Row(
                      children: [
                        if (icon != null && constraints.maxWidth >= 240) ...[
                          Icon(
                            icon,
                            size: 20,
                            color: value
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                        ] else
                          const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            label,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        tick,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
