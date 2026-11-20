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

/// The shared share sheet: a preview of the feature's own [card] and the
/// two ways to share, through the adaptive presenter (bottom sheet on
/// compact, dialog beside a fold on wider windows). Only this scaffold and
/// the capture pipeline (`ShareImageCapture`) are shared; every feature
/// designs its own card. See `design/LANGUAGE.md`, "Share cards".
///
/// [onShareImage] usually calls `ShareImageCapture.share` with the same
/// card; the image button shows "Generating…" until it completes.
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

  /// The card's height over its width, if the feature knows it. A card
  /// taller than 9:16 keeps a readable width in the preview and scrolls
  /// in it, under a fade (changed in `athkar`, owner round 4: a tall card
  /// fitted whole was a sliver).
  final double? cardAspect;
  final String? previewLabel;
  final Future<void> Function() onShareImage;
  final VoidCallback onShareText;

  /// The feature's own options for its card (Athkar's translation
  /// switch), above the actions (changed in `athkar`).
  final Widget? controls;

  /// Copies the text to the clipboard; the tile then says so for a moment.
  final VoidCallback? onCopyText;

  /// Saves the image to the device (photos on phones, Downloads on
  /// desktops). The tile turns busy, then says how it went (see
  /// `ShareImageSaver`).
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
    // A new card (another option, say the translation off) hasn't been saved or
    // copied yet; features key their cards by option for this.
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
        // On short sheets the failure lands below the fold: it is the
        // sheet's last line, so scroll to the end, past the bottom inset
        // the scroll view pads with.
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
    // Inside the sheet, this is the side of the fold the sheet is on.
    final window = MediaQuery.sizeOf(context);
    // A capability, not layout: Linux has no image share target.
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
      // The quieter ways in one row of compact tiles, each saying how it
      // went; full tiles, stacked, where three would squeeze their labels.
      LayoutBuilder(
        builder: (context, constraints) {
          final copy = widget.onCopyText != null;
          // Saving needs no share target: Linux saves to Downloads too.
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
                    // Desktops save to Downloads (owner round 4).
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
    // A failure leads with the lamp, as status does everywhere.
    // "Not available" can't be retried; a failed save can.
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
        // Short spaces (compact height, a horizontal fold) put the preview
        // beside the actions so both stay visible.
        final side =
            constraints.maxWidth >= 600 ||
            (constraints.maxWidth >= 420 && window.height < 600);
        // Leaves room for the sheet's title and bottom padding in short
        // windows.
        // Stacked (phones), the preview stays small enough for every action
        // to show without scrolling (changed in `athkar`, owner round 2).
        var previewHeight =
            (window.height * (side ? 0.62 : (window.height < 700 ? 0.24 : 0.3)))
                .clamp(160.0, 560.0)
                .clamp(0.0, (window.height - 220).clamp(160.0, 560.0));
        // Beside the iPhone Duo's side column a bottom sheet starts below
        // the column's cutouts: keep the preview small enough for both
        // actions to rest above the bottom inset (changed in `athkar`).
        final column = SideChrome.sideOf(context);
        // Under the column the sheet is short: the preview sits beside the
        // card's options, the actions full width below (owner round 3).
        // Large text needs the width: the preview goes above them.
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
        // Changing an option cross-fades the card and eases the preview to
        // its new height (owner round 3: it snapped).
        final preview = Semantics(
          label: widget.previewLabel,
          image: true,
          child: LayoutBuilder(
            builder: (context, room) => _EaseSize(
              duration: change,
              curve: motion.standard,
              child: AnimatedSwitcher(
                duration: change,
                // The new card sets the size at once, so the resize runs
                // with the fade; the old one fades at its own size.
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
              // Short windows give the actions more of the width.
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
                    // Under the actions it is said, and the sheet scrolls to
                    // it on short windows (critic, owner round 4: under the
                    // preview it ran past the dialog's edge).
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
              // The preview takes its own width (up to 40%), so the options
              // end where the actions do, whatever the card's shape (critic,
              // `athkar` owner round 5).
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

/// One way to share, as a tile. The primary way is lit: the chrome with a
/// lamp holding the icon (no ring on a tile this wide: it would read as a
/// double border) (a turning khatam
/// while [busy]). The other sits quietly on the sheet. At least 64 tall;
/// the label wraps instead of clipping. While [busy] the tile keeps its
/// look and ignores taps; the icon and label cross-fade to the busy ones
/// (changed in `athkar`, owner round 3: the swap used to jump).
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

  /// The mark above a centered label, for a row of small tiles.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final shape = HudaLanternBorder(
      radius: tokens.radius.lg,
      side: lit ? BorderSide.none : BorderSide(color: scheme.outline),
      // The lit tile carries the buttons' engraving in its corner.
      engraving: lit ? tokens.onChrome.withValues(alpha: 0.24) : null,
    );
    final fade = tokens.motion.of(context, tokens.motion.medium);
    Widget swap(Widget child, {AlignmentGeometry? alignment}) =>
        AnimatedSwitcher(
          duration: fade,
          // The outgoing one leaves in the first half and the incoming
          // arrives in the second, so the two never overlap.
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

/// `AnimatedSize`, or its child as is when there's nothing to animate
/// (reduce motion): at zero duration `AnimatedSize` asserts in layout.
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

/// A tall card in a window of the preview's height: it scrolls, and fades
/// at the foot while there's more below.
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
    // One tree either way, so the scroll position survives the fade's end.
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

/// An option to include or leave out, as a tile in the share sheet's
/// family: the option's mark ([icon]), its label, and a square tick box at
/// the end (filled with the primary and ticked when on, an empty box at
/// 3:1 when off). On, the tile takes a primary tint and border, so its
/// state reads at a glance. It reads as a setting, not a share action: a
/// bare mark, no fill while off, a smaller radius and height. The whole tile is the target. A share sheet's card options use
/// it (`HudaShareSheetBody.controls`). From Athkar's tick (`athkar` owner
/// round 6); a tile since `hadith` owner round 1 (the bare row looked
/// unfinished beside the share tiles).
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

  /// What the option adds (a translate mark for a translation).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final motion = tokens.motion;
    final change = motion.of(context, motion.short);
    // A setting, not a share action: a smaller radius and height, no fill
    // while off and a bare mark, unlike the action tiles below it.
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
        // Off keeps 3:1 against the page: its outline is its state.
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
                // A narrow tile (beside the preview under the iPhone Duo's
                // column) drops the mark, so the label keeps whole words.
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
