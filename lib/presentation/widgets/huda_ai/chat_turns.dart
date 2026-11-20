import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/huda_ai/huda_ai_identity.dart';
import 'package:huda/presentation/widgets/huda_ai/huda_ai_text.dart';

class HudaAiUserTurn extends StatelessWidget {
  const HudaAiUserTurn({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final dark = theme.brightness == Brightness.dark;
    final lg = Radius.circular(tokens.radius.lg);
    return Semantics(
      label: l10n.hudaAiYouAsked,
      container: true,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: FractionallySizedBox(
          alignment: AlignmentDirectional.centerEnd,
          widthFactor: 0.86,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  scheme.primary.withValues(alpha: dark ? 0.24 : 0.10),
                  scheme.surface,
                ),
                borderRadius: BorderRadiusDirectional.only(
                  topStart: lg,
                  topEnd: lg,
                  bottomStart: lg,
                  bottomEnd: Radius.circular(tokens.radius.sm),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.space.md,
                  vertical: tokens.space.sm,
                ),
                child: SelectableText(
                  text,
                  textDirection: hudaAiTextDirection(text),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface,
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

class HudaAiTurnHeader extends StatelessWidget {
  const HudaAiTurnHeader({super.key, this.writing = false});

  final bool writing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    return Row(
      children: [
        HudaAiMark(size: 28, gathering: writing),
        SizedBox(width: tokens.space.xs),
        Flexible(
          child: Text(
            l10n.hudaAI,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(color: scheme.tertiary),
          ),
        ),
        if (writing) ...[
          SizedBox(width: tokens.space.xs),
          Flexible(
            child: Semantics(
              liveRegion: true,
              child: Text(
                l10n.hudaAiWriting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class HudaAiAnswer extends StatelessWidget {
  const HudaAiAnswer({
    super.key,
    required this.text,
    required this.writing,
    required this.onCopy,
    required this.onShare,
  });

  final String text;
  final bool writing;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return Semantics(
      label: AppLocalizations.of(context)!.hudaAI,
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HudaAiTurnHeader(writing: writing),
          SizedBox(height: space.xs),
          HudaAiMarkdown(text),
          if (!writing) ...[
            SizedBox(height: space.xs),
            HudaAiAnswerActions(onCopy: onCopy, onShare: onShare),
          ],
        ],
      ),
    );
  }
}

class HudaAiAnswerActions extends StatelessWidget {
  const HudaAiAnswerActions({
    super.key,
    required this.onCopy,
    required this.onShare,
  });

  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final space = context.tokens.space;
    final narrow =
        MediaQuery.sizeOf(context).width <
        420 * MediaQuery.textScalerOf(context).scale(1);
    final buttons = [
      IconButton(
        key: const ValueKey('huda_ai_copy'),
        tooltip: l10n.copyButton,
        onPressed: onCopy,
        color: scheme.onSurfaceVariant,
        icon: const Icon(Icons.copy_rounded, size: 20),
      ),
      if (!PlatformUtils.isLinux)
        IconButton(
          key: const ValueKey('huda_ai_share'),
          tooltip: l10n.share,
          onPressed: onShare,
          color: scheme.onSurfaceVariant,
          icon: const Icon(Icons.ios_share_rounded, size: 20),
        ),
    ];
    final note = Text(
      l10n.aiGeneratedDisclaimer,
      style: theme.textTheme.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    );
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: Offset(
              Directionality.of(context) == TextDirection.rtl ? 8 : -8,
              0,
            ),
            child: Row(children: buttons),
          ),
          note,
        ],
      );
    }
    return Row(
      children: [
        Transform.translate(
          offset: Offset(
            Directionality.of(context) == TextDirection.rtl ? 8 : -8,
            0,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: buttons),
        ),
        SizedBox(width: space.xxs),
        Expanded(child: note),
      ],
    );
  }
}

class HudaAiThinking extends StatelessWidget {
  const HudaAiThinking({super.key, this.retrying = false});

  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final space = context.tokens.space;
    final title = retrying ? l10n.stateRetrying : l10n.hudaAIThinking;
    return Semantics(
      liveRegion: true,
      label: title,
      excludeSemantics: true,
      child: Row(
        key: const ValueKey('huda_ai_thinking'),
        children: [
          const HudaAiNoor(size: 56, gathering: true),
          SizedBox(width: space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                SizedBox(height: space.xxs),
                Text(
                  l10n.analyzingQuestion,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HudaAiStatusLine extends StatelessWidget {
  const HudaAiStatusLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final insets = MediaQuery.paddingOf(context);
    return Semantics(
      liveRegion: true,
      label: text,
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          insets.left + tokens.space.md,
          tokens.space.xs,
          insets.right + tokens.space.md,
          tokens.space.xs,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HudaLamp(
              size: 28,
              child: HudaLampSpinner(size: 14, color: tokens.gilt),
            ),
            SizedBox(width: tokens.space.xs),
            Flexible(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HudaAiRiseIn extends StatefulWidget {
  const HudaAiRiseIn({
    super.key,
    required this.child,
    this.animate = true,
    this.delay = Duration.zero,
  });

  final Widget child;
  final bool animate;
  final Duration delay;

  @override
  State<HudaAiRiseIn> createState() => _HudaAiRiseInState();
}

class _HudaAiRiseInState extends State<HudaAiRiseIn>
    with SingleTickerProviderStateMixin {
  static const _motion = HudaMotion();
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + _motion.long,
    value: widget.animate ? 0 : 1,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMicroseconds / _controller.duration!.inMicroseconds,
      1,
      curve: _motion.emphasized,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.value == 1 || _controller.isAnimating) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _curve,
    child: SlideTransition(
      position: _curve.drive(
        Tween(begin: const Offset(0, 0.04), end: Offset.zero),
      ),
      child: widget.child,
    ),
  );
}
