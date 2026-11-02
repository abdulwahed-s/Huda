import 'package:flutter/material.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';

/// What a toast reports.
enum HudaToastKind {
  /// Done: a saved setting, a copied verse.
  done,

  /// Work running in the background.
  working,

  /// Something failed; offer an action.
  failed,
}

/// Huda's transient status: a floating capsule of the deep chrome, led by a
/// lamp (lit and turning while working, a still gilt khatam when done, an
/// unlit red one when something failed), warm text, and a warm action.
/// It rises from the bottom edge above the system bars and goes after a
/// while. Shown with [showHudaToast].
class HudaToast extends StatelessWidget {
  const HudaToast({
    super.key,
    required this.message,
    this.kind = HudaToastKind.done,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final HudaToastKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    final lamp = switch (kind) {
      HudaToastKind.working => HudaLamp(
        size: 34,
        child: HudaLampSpinner(size: 16, color: tokens.gilt),
      ),
      HudaToastKind.done => HudaLamp(
        size: 34,
        child: HudaKhatamMark(color: tokens.gilt, size: 16),
      ),
      HudaToastKind.failed => HudaLamp(
        size: 34,
        ring: error.withValues(alpha: 0.7),
        child: HudaKhatamMark(
          color: Color.lerp(error, Colors.white, 0.35)!,
          size: 16,
        ),
      ),
    };
    final actionLabel = this.actionLabel;
    return Semantics(
      liveRegion: true,
      container: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, minHeight: 56),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            gradient: tokens.chromeGradient,
            shape: const StadiumBorder(),
            shadows: [
              BoxShadow(
                color: tokens.chrome.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 12, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(child: lamp),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.onChrome,
                    ),
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onAction,
                    // Warm text, not gold: no gold on controls.
                    style: TextButton.styleFrom(
                      foregroundColor: tokens.onChrome,
                      overlayColor: tokens.onChrome,
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: tokens.onChromeMuted,
                      ),
                    ),
                    child: Text(actionLabel),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a [HudaToast] through the nearest `ScaffoldMessenger`, floating
/// above the system bars, replacing the current one.
void showHudaToast(
  BuildContext context, {
  required String message,
  HudaToastKind kind = HudaToastKind.done,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.of(context);
  // A half-open vertical fold (book) splits the screen: the toast keeps to
  // the trailing side, like sheets, never on the crease (changed in
  // `athkar`). A horizontal one already has it at the bottom.
  final fold = FoldInfo.of(context);
  var margin = const EdgeInsets.fromLTRB(16, 0, 16, 12);
  if (fold.avoided && fold.splitsHorizontally) {
    final width = MediaQuery.sizeOf(context).width;
    margin = Directionality.of(context) == TextDirection.rtl
        ? margin.copyWith(right: width - fold.start + 16)
        : margin.copyWith(left: fold.end + 16);
  }
  const motion = HudaMotion();
  final instant = motion.of(context, motion.medium) == Duration.zero;
  messenger
    ..removeCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: margin,
        duration: duration,
        content: Center(
          child: HudaToast(
            message: message,
            kind: kind,
            actionLabel: actionLabel,
            onAction: onAction == null
                ? null
                : () {
                    messenger.hideCurrentSnackBar(
                      reason: SnackBarClosedReason.action,
                    );
                    onAction();
                  },
          ),
        ),
      ),
      snackBarAnimationStyle: instant
          ? AnimationStyle.noAnimation
          : AnimationStyle(duration: motion.medium),
    );
}
