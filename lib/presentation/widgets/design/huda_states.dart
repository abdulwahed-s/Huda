import 'package:flutter/material.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/common/app_shimmer.dart';
import 'package:huda/presentation/widgets/design/feature_identity.dart';
import 'package:huda/core/theme/huda_lantern_border.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

/// Shared states. Every screen designs loading, empty, error, offline and
/// permission with these, giving them its identity's art. Status follows
/// `CLAUDE.md`: "updating" while automatic work runs, an error after it
/// fails, and a separate "retrying" after a tap. Nothing assumes it will
/// fix itself.

// Loading -------------------------------------------------------------------

/// A loading placeholder shaped like the content: compose [HudaSkeletonBlock]
/// and [HudaSkeletonLines] in the content's layout and wrap them in this.
/// The sheen stops when the platform asks to reduce motion.
class HudaSkeleton extends StatelessWidget {
  const HudaSkeleton({
    super.key,
    required this.child,
    this.label,
    this.announce = true,
  });

  final Widget child;

  /// Read out instead of the shapes; defaults to "Loading…".
  final String? label;

  /// False for all but one skeleton in a grid, so "Loading" is read once.
  final bool announce;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: announce ? label ?? AppLocalizations.of(context)?.loading : null,
      liveRegion: announce,
      child: ExcludeSemantics(
        child: AppShimmer(
          baseColor: scheme.surfaceContainerHighest,
          highlightColor: scheme.surfaceContainerLow,
          child: child,
        ),
      ),
    );
  }
}

/// One rounded block of a skeleton (an image, an icon mark, a button).
class HudaSkeletonBlock extends StatelessWidget {
  const HudaSkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.circle = false,
  });

  final double? width;
  final double height;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle
          ? null
          : BorderRadius.circular(context.tokens.radius.sm),
    ),
  );
}

/// Lines of text in a skeleton, sized from a text role so they follow the
/// text scale. The last line is shorter.
class HudaSkeletonLines extends StatelessWidget {
  const HudaSkeletonLines({super.key, this.lines = 3, this.style});

  final int lines;

  /// Defaults to `bodyMedium`.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final role = style ?? Theme.of(context).textTheme.bodyMedium!;
    final size = MediaQuery.textScalerOf(context).scale(role.fontSize ?? 15);
    final lineHeight = size * (role.height ?? 1.4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < lines; i++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: (lineHeight - size) / 2),
            child: FractionallySizedBox(
              widthFactor: i == lines - 1 && lines > 1 ? 0.6 : 1,
              child: HudaSkeletonBlock(height: size * 0.8),
            ),
          ),
      ],
    );
  }
}

// Full states -----------------------------------------------------------------

/// The shared layout of empty, error, offline and permission states: the
/// identity's art (or an icon), a title, a message and actions, centered
/// at a readable width. Scrolls when the text is large or the space small.
class HudaStateView extends StatelessWidget {
  const HudaStateView({
    super.key,
    required this.title,
    this.message,
    this.identity,
    this.icon,
    this.mark = HudaStateMark.unlit,
    this.actions = const [],
    this.footnote,
  });

  final String title;
  final String? message;

  /// Draws the identity's state art; [icon] is used when null.
  final FeatureIdentity? identity;
  final IconData? icon;

  /// The lamp the state leads with when it has no identity art.
  final HudaStateMark mark;
  final List<Widget> actions;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final identity = this.identity;
    final message = this.message;
    final footnote = this.footnote;
    final view = LayoutBuilder(
      builder: (context, constraints) {
        final artSize = (constraints.maxHeight * 0.22).clamp(72.0, 144.0);
        final markSize = artSize * 0.7;
        final art = identity != null
            ? Ornament(
                size: Size.square(artSize),
                semanticLabel: identity.semanticLabel,
                painter: identity.stateArt(OrnamentStyle.of(context)),
              )
            : switch (mark) {
                // An invitation: a lit lamp.
                HudaStateMark.lit => HudaLamp(
                  size: markSize,
                  child: Icon(icon ?? Icons.info_outline_rounded),
                ),
                // A failure: the lamp unlit and red, a still khatam.
                HudaStateMark.alert => _UnlitLamp(
                  size: markSize,
                  tint: scheme.error,
                  child: HudaKhatamMark(
                    color: scheme.error,
                    size: markSize * 0.42,
                  ),
                ),
                HudaStateMark.unlit => _UnlitLamp(
                  size: markSize,
                  tint: tokens.ornament,
                  child: Icon(
                    icon ?? Icons.info_outline_rounded,
                    size: markSize * 0.42,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              };
        return SingleChildScrollView(
          // Edge to edge: the insets are end padding inside the scroll.
          padding: context.scrollPadding(
            EdgeInsets.all(space.gutter(constraints.maxWidth)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - space.xxl * 2).clamp(
                0.0,
                double.infinity,
              ),
            ),
            child: Align(
              child: ReadableWidth(
                maxWidth: 480,
                avoidFlatFolds: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    art,
                    SizedBox(height: space.xl),
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    if (message != null) ...[
                      SizedBox(height: space.xs),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (actions.isNotEmpty) ...[
                      SizedBox(height: space.xl),
                      Wrap(
                        alignment: WrapAlignment.center,
                        // Buttons of different heights share one line.
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: space.sm,
                        runSpacing: space.sm,
                        children: actions,
                      ),
                    ],
                    if (footnote != null) ...[
                      SizedBox(height: space.md),
                      Text(
                        footnote,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    // A horizontal fold that content must stay off (a band, or tabletop):
    // the state takes the top half. Assumes the view reaches the window's
    // bottom, as a screen body does.
    final fold = FoldInfo.of(context);
    if (fold.separatorAxis != Axis.horizontal || !fold.avoided) return view;
    return LayoutBuilder(
      builder: (context, box) {
        final top =
            fold.start - (MediaQuery.sizeOf(context).height - box.maxHeight);
        if (top < 160 || top >= box.maxHeight) return view;
        return Column(
          children: [
            SizedBox(height: top, child: view),
            const Spacer(),
          ],
        );
      },
    );
  }
}

/// The lamp a state leads with: unlit (nothing is wrong, nothing to do
/// yet), alert (a failure) or lit (an invitation, like a permission).
enum HudaStateMark { unlit, alert, lit }

/// An unlit lamp: a disc softly tinted by [tint], with a fine ring.
class _UnlitLamp extends StatelessWidget {
  const _UnlitLamp({
    required this.size,
    required this.tint,
    required this.child,
  });

  final double size;
  final Color tint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.alphaBlend(
          tint.withValues(alpha: dark ? 0.16 : 0.08),
          surface,
        ),
        border: Border.all(
          color: Color.alphaBlend(
            tint.withValues(alpha: dark ? 0.4 : 0.3),
            surface,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// Nothing here yet: the feature's motif and a next step.
class HudaEmptyState extends StatelessWidget {
  const HudaEmptyState({
    super.key,
    required this.identity,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final FeatureIdentity identity;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final actionLabel = this.actionLabel;
    return HudaStateView(
      identity: identity,
      title: title,
      message: message,
      actions: [
        if (actionLabel != null && onAction != null)
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

/// A retry button with the separate "retrying" state: after a tap it
/// shows a spinner and "Retrying…" and can't be tapped again until the
/// caller sets [retrying] back to false.
class HudaRetryButton extends StatelessWidget {
  const HudaRetryButton({
    super.key,
    required this.onRetry,
    this.retrying = false,
    this.filled = true,
  });

  final VoidCallback onRetry;
  final bool retrying;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final duration = tokens.motion.of(context, tokens.motion.short);
    if (retrying) {
      // Not a disabled button: a readable "in progress" pill in the
      // button's place, that can't be tapped again.
      return Semantics(
        liveRegion: true,
        label: l10n.stateRetrying,
        excludeSemantics: true,
        child: AnimatedContainer(
          duration: duration,
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          // The lit button itself, working: the chrome, its engraving, a
          // turning khatam. Readable, and it can't be tapped again.
          decoration: ShapeDecoration(
            color: tokens.lit,
            shape: HudaLanternBorder(
              radius: tokens.radius.md,
              engraving: tokens.onChrome.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HudaLampSpinner(
                size: MediaQuery.textScalerOf(context).scale(18),
                color: tokens.gilt,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  l10n.stateRetrying,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: tokens.onChrome),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final label = Text(l10n.retry);
    return filled
        ? FilledButton(onPressed: onRetry, child: label)
        : OutlinedButton(onPressed: onRetry, child: label);
  }
}

/// Something failed: what happened, and a retry with its own "retrying"
/// state.
class HudaErrorState extends StatelessWidget {
  const HudaErrorState({
    super.key,
    this.title,
    this.message,
    this.identity,
    this.onRetry,
    this.retrying = false,
  });

  /// Defaults to "Something went wrong".
  final String? title;
  final String? message;
  final FeatureIdentity? identity;
  final VoidCallback? onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onRetry = this.onRetry;
    return HudaStateView(
      identity: identity,
      mark: HudaStateMark.alert,
      title: title ?? l10n.somethingWentWrong,
      message: message,
      actions: [
        if (onRetry != null)
          HudaRetryButton(onRetry: onRetry, retrying: retrying),
      ],
    );
  }
}

/// No connection. Says whether saved content is still shown, and offers a
/// retry with its own "retrying" state.
class HudaOfflineState extends StatelessWidget {
  const HudaOfflineState({
    super.key,
    this.message,
    this.showingSaved = false,
    this.onRetry,
    this.retrying = false,
  });

  /// Defaults to the network-settings hint.
  final String? message;

  /// True when the screen behind still shows saved content.
  final bool showingSaved;
  final VoidCallback? onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onRetry = this.onRetry;
    return HudaStateView(
      icon: Icons.cloud_off_rounded,
      title: l10n.noInternetConnection,
      message: message ?? l10n.noInternetSettings,
      footnote: showingSaved ? l10n.stateOfflineSaved : null,
      actions: [
        if (onRetry != null)
          HudaRetryButton(onRetry: onRetry, retrying: retrying),
      ],
    );
  }
}

/// A permission is needed: explain why before the system prompt, then
/// ask. [secondaryLabel] offers a way out ("Not now", "Open settings").
class HudaPermissionState extends StatelessWidget {
  const HudaPermissionState({
    super.key,
    required this.icon,
    required this.title,
    required this.explanation,
    required this.allowLabel,
    required this.onAllow,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String explanation;
  final String allowLabel;
  final VoidCallback onAllow;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final secondaryLabel = this.secondaryLabel;
    return HudaStateView(
      icon: icon,
      mark: HudaStateMark.lit,
      title: title,
      message: explanation,
      actions: [
        FilledButton(onPressed: onAllow, child: Text(allowLabel)),
        if (secondaryLabel != null && onSecondary != null)
          TextButton(onPressed: onSecondary, child: Text(secondaryLabel)),
      ],
    );
  }
}

// Inline status ---------------------------------------------------------------

enum HudaStatus {
  /// Automatic work is running (a refresh, a sync).
  updating,

  /// It failed; the content shown may be stale.
  failed,

  /// The person tapped retry and it's running.
  retrying,
}

/// A banner over content that is still usable. Its lead is a lamp: lit
/// (the turning khatam on the chrome) while work runs, unlit and red with
/// a still khatam after a failure. "Updating…" (automatic) sits on a quiet
/// surface; "Retrying…" (after a tap) is warmed with the gilt; the failure
/// is tinted with the error color and offers a retry.
class HudaStatusBanner extends StatelessWidget {
  const HudaStatusBanner({
    super.key,
    required this.status,
    this.message,
    this.onRetry,
  });

  final HudaStatus status;

  /// What failed (for [HudaStatus.failed]); defaults to "Something went
  /// wrong".
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final failed = status == HudaStatus.failed;
    Color tint(Color color, double light, double night) => Color.alphaBlend(
      color.withValues(alpha: dark ? night : light),
      scheme.surface,
    );
    final (surface, border) = switch (status) {
      HudaStatus.updating => (
        tint(scheme.primary, 0.05, 0.10),
        scheme.outlineVariant,
      ),
      HudaStatus.retrying => (
        tint(scheme.tertiary, 0.10, 0.16),
        tint(scheme.tertiary, 0.32, 0.4),
      ),
      HudaStatus.failed => (
        tint(scheme.error, 0.06, 0.12),
        tint(scheme.error, 0.2, 0.28),
      ),
    };
    final text = switch (status) {
      HudaStatus.updating => l10n.stateUpdating,
      HudaStatus.retrying => l10n.stateRetrying,
      HudaStatus.failed => message ?? l10n.somethingWentWrong,
    };
    final onRetry = this.onRetry;
    final lamp = failed
        ? Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint(scheme.error, 0.14, 0.24),
            ),
            alignment: Alignment.center,
            child: HudaKhatamMark(color: scheme.error, size: 18),
          )
        : HudaLamp(
            size: 36,
            child: HudaLampSpinner(size: 18, color: tokens.gilt),
          );
    return Semantics(
      liveRegion: true,
      container: true,
      label: text,
      excludeSemantics: !(failed && onRetry != null),
      child: Material(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: tokens.radius.card,
          side: BorderSide(color: border),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 8, 10),
          // At large text in a narrow window, Retry takes its own row under
          // the message instead of squeezing it into a column of a few
          // words per line (changed in `zakat`). Decided from the window
          // and text scale, not a LayoutBuilder, so the banner still sizes
          // under intrinsic layouts (dialog content).
          child: Builder(
            builder: (context) {
              final message = Row(
                children: [
                  ExcludeSemantics(child: lamp),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ExcludeSemantics(
                      child: Text(
                        text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              );
              if (!failed || onRetry == null) return message;
              final retry = TextButton(
                onPressed: onRetry,
                child: Text(l10n.retry),
              );
              final size = theme.textTheme.bodyMedium?.fontSize ?? 15;
              final scale =
                  MediaQuery.textScalerOf(context).scale(size) / size;
              if (MediaQuery.sizeOf(context).width < 360 * scale) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    message,
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: retry,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: message),
                  const SizedBox(width: 8),
                  retry,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
