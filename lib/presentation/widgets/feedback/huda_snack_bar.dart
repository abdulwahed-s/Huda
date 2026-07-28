import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';

enum HudaSnackBarKind { success, error, warning, info, neutral }

class HudaSnackBarAction {
  const HudaSnackBarAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

abstract final class HudaSnackBar {
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    HudaSnackBarKind kind = HudaSnackBarKind.neutral,
    String? title,
    HudaSnackBarAction? action,
    Duration? duration,
    bool? dismissible,
    bool replaceCurrent = true,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    if (replaceCurrent) {
      messenger.removeCurrentSnackBar(reason: SnackBarClosedReason.remove);
    }

    final media = MediaQuery.of(context);
    final shouldDismiss = dismissible ?? kind == HudaSnackBarKind.error;
    final accessibleNavigation = media.accessibleNavigation;
    final effectiveDuration = duration ??
        defaultDurationFor(
          kind,
          message: message,
          hasAction: action != null,
        );

    return messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
        duration: effectiveDuration,
        persist: action != null && accessibleNavigation,
        dismissDirection: DismissDirection.horizontal,
        clipBehavior: Clip.none,
        content: _HudaSnackBarSurface(
          message: message,
          kind: kind,
          title: title,
          action: action,
          dismissible: shouldDismiss,
        ),
      ),
      snackBarAnimationStyle: media.disableAnimations || accessibleNavigation
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: Duration(milliseconds: 280),
              reverseDuration: Duration(milliseconds: 240),
            ),
    );
  }

  static Duration defaultDurationFor(
    HudaSnackBarKind kind, {
    required String message,
    bool hasAction = false,
  }) {
    final baseSeconds = switch (kind) {
      HudaSnackBarKind.success || HudaSnackBarKind.neutral => 3,
      HudaSnackBarKind.info => 4,
      HudaSnackBarKind.warning => 5,
      HudaSnackBarKind.error => 6,
    };
    final readingBonus =
        ((message.runes.length - 44).clamp(0, 180) / 54).ceil();
    final actionBonus = hasAction ? 2 : 0;
    return Duration(
      seconds: (baseSeconds + readingBonus + actionBonus).clamp(3, 10).toInt(),
    );
  }

  static void success(
    BuildContext context, {
    required String message,
    String? title,
    HudaSnackBarAction? action,
    Duration? duration,
    bool? dismissible,
    bool replaceCurrent = true,
  }) =>
      show(
        context,
        message: message,
        kind: HudaSnackBarKind.success,
        title: title,
        action: action,
        duration: duration,
        dismissible: dismissible,
        replaceCurrent: replaceCurrent,
      );

  static void error(
    BuildContext context, {
    required String message,
    String? title,
    HudaSnackBarAction? action,
    Duration? duration,
    bool? dismissible,
    bool replaceCurrent = true,
  }) =>
      show(
        context,
        message: message,
        kind: HudaSnackBarKind.error,
        title: title,
        action: action,
        duration: duration,
        dismissible: dismissible,
        replaceCurrent: replaceCurrent,
      );

  static void warning(
    BuildContext context, {
    required String message,
    String? title,
    HudaSnackBarAction? action,
    Duration? duration,
    bool? dismissible,
    bool replaceCurrent = true,
  }) =>
      show(
        context,
        message: message,
        kind: HudaSnackBarKind.warning,
        title: title,
        action: action,
        duration: duration,
        dismissible: dismissible,
        replaceCurrent: replaceCurrent,
      );

  static void info(
    BuildContext context, {
    required String message,
    String? title,
    HudaSnackBarAction? action,
    Duration? duration,
    bool? dismissible,
    bool replaceCurrent = true,
  }) =>
      show(
        context,
        message: message,
        kind: HudaSnackBarKind.info,
        title: title,
        action: action,
        duration: duration,
        dismissible: dismissible,
        replaceCurrent: replaceCurrent,
      );

  static void neutral(
    BuildContext context, {
    required String message,
    String? title,
    HudaSnackBarAction? action,
    Duration? duration,
    bool? dismissible,
    bool replaceCurrent = true,
  }) =>
      show(
        context,
        message: message,
        kind: HudaSnackBarKind.neutral,
        title: title,
        action: action,
        duration: duration,
        dismissible: dismissible,
        replaceCurrent: replaceCurrent,
      );
}

class HudaSnackBarPreview extends StatelessWidget {
  const HudaSnackBarPreview({
    super.key,
    required this.message,
    this.kind = HudaSnackBarKind.neutral,
    this.title,
    this.action,
    this.dismissible = false,
  });

  final String message;
  final HudaSnackBarKind kind;
  final String? title;
  final HudaSnackBarAction? action;
  final bool dismissible;

  @override
  Widget build(BuildContext context) => _HudaSnackBarSurface(
        message: message,
        kind: kind,
        title: title,
        action: action,
        dismissible: dismissible,
      );
}

class _HudaSnackBarSurface extends StatefulWidget {
  const _HudaSnackBarSurface({
    required this.message,
    required this.kind,
    required this.title,
    required this.action,
    required this.dismissible,
  });

  final String message;
  final HudaSnackBarKind kind;
  final String? title;
  final HudaSnackBarAction? action;
  final bool dismissible;

  @override
  State<_HudaSnackBarSurface> createState() => _HudaSnackBarSurfaceState();
}

class _HudaSnackBarSurfaceState extends State<_HudaSnackBarSurface> {
  bool _actionTriggered = false;

  void _triggerAction() {
    if (_actionTriggered) return;
    setState(() => _actionTriggered = true);
    widget.action!.onPressed();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar(reason: SnackBarClosedReason.action);
    }
  }

  void _dismiss() {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(reason: SnackBarClosedReason.dismiss);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _HudaSnackBarPalette.resolve(context, widget.kind);
    final textScaler = MediaQuery.textScalerOf(context);
    final scaledBodySize = textScaler.scale(14);
    final l10n = AppLocalizations.of(context)!;
    final statusLabel = switch (widget.kind) {
      HudaSnackBarKind.success => l10n.success,
      HudaSnackBarKind.error => l10n.error,
      HudaSnackBarKind.warning => l10n.warning,
      HudaSnackBarKind.info => l10n.info,
      HudaSnackBarKind.neutral => l10n.snackbarNeutral,
    };
    final closeLabel = l10n.close;
    final semanticLabel = [statusLabel, widget.title, widget.message]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join('. ');
    final reduceMotion = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    final snackBarAnimation =
        context.findAncestorWidgetOfExactType<SnackBar>()?.animation;

    return Semantics(
      key: ValueKey('huda-snackbar-${widget.kind.name}'),
      container: true,
      label: semanticLabel,
      child: _HudaSnackBarMotion(
        animation: snackBarAnimation,
        reduceMotion: reduceMotion,
        child: Align(
          alignment: AlignmentDirectional.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Material(
              key: ValueKey('huda-snackbar-card-${widget.kind.name}'),
              color: palette.surface,
              elevation: palette.highContrast ? 0 : 3,
              shadowColor: palette.shadow,
              shape: _HudaCutCornerBorder(
                side: BorderSide(
                  color: palette.border,
                  width: palette.highContrast ? 1.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomPaint(
                foregroundPainter: _HudaSnackBarSurfacePainter(
                  accent: palette.accent,
                  border: palette.border,
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 10, 12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stackAction = widget.action != null &&
                          (constraints.maxWidth < 390 || scaledBodySize > 18);
                      return _HudaSnackBarContent(
                        message: widget.message,
                        title: widget.title,
                        kind: widget.kind,
                        action: widget.action,
                        actionTriggered: _actionTriggered,
                        dismissible: widget.dismissible,
                        stackAction: stackAction,
                        palette: palette,
                        closeLabel: closeLabel,
                        onAction: _triggerAction,
                        onDismiss: _dismiss,
                      );
                    },
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

class _HudaSnackBarMotion extends StatelessWidget {
  const _HudaSnackBarMotion({
    required this.animation,
    required this.reduceMotion,
    required this.child,
  });

  final Animation<double>? animation;
  final bool reduceMotion;
  final Widget child;

  static const _motionCurve = Interval(
    0.30,
    1.0,
    curve: Curves.fastOutSlowIn,
  );

  @override
  Widget build(BuildContext context) {
    final animation = this.animation;
    if (reduceMotion || animation == null) return child;

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final progress = _motionCurve.transform(animation.value);
        return Transform.translate(
          key: const ValueKey('huda-snackbar-motion'),
          offset: Offset(0, 24 * (1 - progress)),
          child: Opacity(
            opacity: 0.96 + (0.04 * progress),
            child: child,
          ),
        );
      },
    );
  }
}

class _HudaSnackBarContent extends StatelessWidget {
  const _HudaSnackBarContent({
    required this.message,
    required this.title,
    required this.kind,
    required this.action,
    required this.actionTriggered,
    required this.dismissible,
    required this.stackAction,
    required this.palette,
    required this.closeLabel,
    required this.onAction,
    required this.onDismiss,
  });

  final String message;
  final String? title;
  final HudaSnackBarKind kind;
  final HudaSnackBarAction? action;
  final bool actionTriggered;
  final bool dismissible;
  final bool stackAction;
  final _HudaSnackBarPalette palette;
  final String closeLabel;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final text = Expanded(
      child: ExcludeSemantics(
        child: _HudaSnackBarText(
          title: title,
          message: message,
          palette: palette,
        ),
      ),
    );
    final leading = ExcludeSemantics(
      child: RepaintBoundary(
        child: _HudaStatusSeal(kind: kind, palette: palette),
      ),
    );
    final dismiss = dismissible
        ? _HudaSnackBarDismissButton(
            label: closeLabel,
            color: palette.icon,
            onPressed: onDismiss,
          )
        : null;

    if (stackAction) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: 12),
              text,
              if (dismiss != null) const SizedBox(width: 2),
              if (dismiss != null) dismiss,
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, thickness: 1, color: palette.divider),
          const SizedBox(height: 2),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _HudaSnackBarActionButton(
              action: action!,
              color: palette.accent,
              disabled: actionTriggered,
              onPressed: onAction,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        leading,
        const SizedBox(width: 12),
        text,
        if (action != null) ...[
          const SizedBox(width: 8),
          SizedBox(
              height: 42,
              child: VerticalDivider(
                  width: 1, thickness: 1, color: palette.divider)),
          const SizedBox(width: 6),
          _HudaSnackBarActionButton(
            action: action!,
            color: palette.accent,
            disabled: actionTriggered,
            onPressed: onAction,
          ),
        ],
        if (dismiss != null) const SizedBox(width: 2),
        if (dismiss != null) dismiss,
      ],
    );
  }
}

class _HudaSnackBarText extends StatelessWidget {
  const _HudaSnackBarText({
    required this.title,
    required this.message,
    required this.palette,
  });

  final String? title;
  final String message;
  final _HudaSnackBarPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title case final title?) ...[
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: palette.title,
              fontWeight: FontWeight.w700,
              height: 1.14,
            ),
          ),
          const SizedBox(height: 3),
        ],
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: palette.text,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _HudaSnackBarActionButton extends StatelessWidget {
  const _HudaSnackBarActionButton({
    required this.action,
    required this.color,
    required this.disabled,
    required this.onPressed,
  });

  final HudaSnackBarAction action;
  final Color color;
  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: action.label,
        child: TextButton(
          onPressed: disabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: color,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.15,
                ),
          ),
          child: Text(action.label, maxLines: 2, textAlign: TextAlign.center),
        ),
      );
}

class _HudaSnackBarDismissButton extends StatelessWidget {
  const _HudaSnackBarDismissButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: IconButton(
          tooltip: label,
          onPressed: onPressed,
          icon: const Icon(Icons.close_rounded),
          color: color,
          iconSize: 20,
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.all(12),
          ),
        ),
      );
}

class _HudaStatusSeal extends StatelessWidget {
  const _HudaStatusSeal({required this.kind, required this.palette});

  final HudaSnackBarKind kind;
  final _HudaSnackBarPalette palette;

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      HudaSnackBarKind.success => Icons.check_rounded,
      HudaSnackBarKind.error => Icons.close_rounded,
      HudaSnackBarKind.warning => Icons.priority_high_rounded,
      HudaSnackBarKind.info => Icons.info_outline_rounded,
      HudaSnackBarKind.neutral => Icons.horizontal_rule_rounded,
    };
    return SizedBox.square(
      dimension: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipPath(
            clipper: const _HudaSealClipper(),
            child: ColoredBox(color: palette.sealSurface),
          ),
          CustomPaint(
            size: const Size.square(44),
            painter: _HudaSealFramePainter(color: palette.accent),
          ),
          Icon(icon, color: palette.icon, size: 23, semanticLabel: ''),
        ],
      ),
    );
  }
}

class _HudaSnackBarPalette {
  const _HudaSnackBarPalette({
    required this.accent,
    required this.surface,
    required this.sealSurface,
    required this.text,
    required this.title,
    required this.icon,
    required this.border,
    required this.divider,
    required this.shadow,
    required this.highContrast,
  });

  final Color accent;
  final Color surface;
  final Color sealSurface;
  final Color text;
  final Color title;
  final Color icon;
  final Color border;
  final Color divider;
  final Color shadow;
  final bool highContrast;

  static _HudaSnackBarPalette resolve(
    BuildContext context,
    HudaSnackBarKind kind,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final highContrast = MediaQuery.highContrastOf(context);
    final accent = switch (kind) {
      HudaSnackBarKind.success =>
        dark ? const Color(0xFF72C99A) : const Color(0xFF1B7A4A),
      HudaSnackBarKind.error => scheme.error,
      HudaSnackBarKind.warning =>
        dark ? const Color(0xFFF2BE5C) : const Color(0xFF9A6100),
      HudaSnackBarKind.info => dark ? scheme.primary : scheme.primary,
      HudaSnackBarKind.neutral => dark ? scheme.secondary : scheme.primary,
    };
    final base = dark ? scheme.surfaceContainerHigh : scheme.surface;
    final surface = highContrast
        ? base
        : Color.alphaBlend(accent.withValues(alpha: dark ? 0.17 : 0.09), base);
    final sealSurface = Color.alphaBlend(
      accent.withValues(alpha: dark ? 0.26 : 0.15),
      surface,
    );
    final onSurface = scheme.onSurface;
    return _HudaSnackBarPalette(
      accent: accent,
      surface: surface,
      sealSurface: sealSurface,
      text: onSurface,
      title: dark ? scheme.onSurface : accent,
      icon: accent,
      border: highContrast
          ? accent
          : Color.alphaBlend(
              accent.withValues(alpha: dark ? 0.7 : 0.52), surface),
      divider: Color.alphaBlend(
        accent.withValues(alpha: highContrast ? 0.55 : 0.26),
        surface,
      ),
      shadow: Colors.black.withValues(alpha: dark ? 0.35 : 0.18),
      highContrast: highContrast,
    );
  }
}

class _HudaCutCornerBorder extends ShapeBorder {
  const _HudaCutCornerBorder({required this.side});

  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _hudaCutCornerPath(rect.deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _hudaCutCornerPath(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(
      getOuterPath(rect, textDirection: textDirection),
      side.toPaint()..style = PaintingStyle.stroke,
    );
  }

  @override
  ShapeBorder scale(double t) => _HudaCutCornerBorder(side: side.scale(t));
}

Path _hudaCutCornerPath(Rect rect) {
  final cut = math.min(14.0, math.max(8.0, rect.shortestSide * 0.22));
  final lowerCut = cut * 0.72;
  return Path()
    ..moveTo(rect.left + cut, rect.top)
    ..lineTo(rect.right - cut, rect.top)
    ..lineTo(rect.right, rect.top + cut)
    ..lineTo(rect.right, rect.bottom - lowerCut)
    ..lineTo(rect.right - lowerCut, rect.bottom)
    ..lineTo(rect.left + lowerCut, rect.bottom)
    ..lineTo(rect.left, rect.bottom - lowerCut)
    ..lineTo(rect.left, rect.top + cut)
    ..close();
}

class _HudaSnackBarSurfacePainter extends CustomPainter {
  const _HudaSnackBarSurfacePainter(
      {required this.accent, required this.border});

  final Color accent;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final hairline = Paint()
      ..color =
          Color.alphaBlend(border.withValues(alpha: 0.42), Colors.transparent)
      ..strokeWidth = 1;
    final accentLine = Paint()
      ..color = accent.withValues(alpha: 0.42)
      ..strokeWidth = 1;
    final start = 17.0;
    final end = math.max(start, size.width - 17);
    canvas.drawLine(Offset(start, 7), Offset(end, 7), hairline);
    canvas.drawLine(
        Offset(start, size.height - 7), Offset(end, size.height - 7), hairline);
    final registration = size.width * 0.15;
    canvas.drawLine(
      Offset(registration, size.height - 11),
      Offset(math.min(registration + 32, end), size.height - 11),
      accentLine,
    );
  }

  @override
  bool shouldRepaint(covariant _HudaSnackBarSurfacePainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.border != border;
}

class _HudaSealClipper extends CustomClipper<Path> {
  const _HudaSealClipper();

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    return Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius * 0.86, center.dy - radius * 0.5)
      ..lineTo(center.dx + radius * 0.86, center.dy + radius * 0.5)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius * 0.86, center.dy + radius * 0.5)
      ..lineTo(center.dx - radius * 0.86, center.dy - radius * 0.5)
      ..close();
  }

  @override
  bool shouldReclip(covariant _HudaSealClipper oldClipper) => false;
}

class _HudaSealFramePainter extends CustomPainter {
  const _HudaSealFramePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = const _HudaSealClipper().getClip(size);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: 0.72),
    );
  }

  @override
  bool shouldRepaint(covariant _HudaSealFramePainter oldDelegate) =>
      oldDelegate.color != color;
}
