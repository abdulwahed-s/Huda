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



class HudaSkeleton extends StatelessWidget {
  const HudaSkeleton({
    super.key,
    required this.child,
    this.label,
    this.announce = true,
  });

  final Widget child;

  final String? label;

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

class HudaSkeletonLines extends StatelessWidget {
  const HudaSkeletonLines({super.key, this.lines = 3, this.style});

  final int lines;

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

  final FeatureIdentity? identity;
  final IconData? icon;

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
                HudaStateMark.lit => HudaLamp(
                  size: markSize,
                  child: Icon(icon ?? Icons.info_outline_rounded),
                ),
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

enum HudaStateMark { unlit, alert, lit }

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
      return Semantics(
        liveRegion: true,
        label: l10n.stateRetrying,
        excludeSemantics: true,
        child: AnimatedContainer(
          duration: duration,
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

class HudaErrorState extends StatelessWidget {
  const HudaErrorState({
    super.key,
    this.title,
    this.message,
    this.identity,
    this.onRetry,
    this.retrying = false,
  });

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

class HudaOfflineState extends StatelessWidget {
  const HudaOfflineState({
    super.key,
    this.message,
    this.showingSaved = false,
    this.onRetry,
    this.retrying = false,
  });

  final String? message;

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


enum HudaStatus {
  updating,

  failed,

  retrying,
}

class HudaStatusBanner extends StatelessWidget {
  const HudaStatusBanner({
    super.key,
    required this.status,
    this.message,
    this.onRetry,
  });

  final HudaStatus status;

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
