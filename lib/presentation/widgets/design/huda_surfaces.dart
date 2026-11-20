import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';

class HudaCard extends StatelessWidget {
  const HudaCard({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? EdgeInsets.all(context.tokens.space.md),
      child: child,
    );
    return HudaPressable(
      enabled: onTap != null,
      child: Card(
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class HudaEyebrow extends StatelessWidget {
  const HudaEyebrow(this.text, {super.key, this.color, this.header = false});

  final String text;
  final Color? color;

  final bool header;

  @override
  Widget build(BuildContext context) => Semantics(
    header: header,
    child: Text(
      text.toUpperCase(),
      style: context.type.eyebrow.copyWith(color: color),
    ),
  );
}

class HudaSectionHeader extends StatelessWidget {
  const HudaSectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final trailing = this.trailing;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: space.xxs,
        end: space.xxs,
        bottom: space.xs,
      ),
      child: Row(
        children: [
          Expanded(child: HudaEyebrow(title, header: true)),
          if (trailing != null) ...[SizedBox(width: space.xs), trailing],
        ],
      ),
    );
  }
}

class HudaSection extends StatelessWidget {
  const HudaSection({
    super.key,
    required this.title,
    required this.children,
    this.footer,
  });

  final String title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final footer = this.footer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HudaSectionHeader(title),
        HudaCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(indent: 16, endIndent: 16),
                children[i],
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              space.xxs,
              space.xs,
              space.xxs,
              0,
            ),
            child: Text(
              footer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class HudaIconMark extends StatelessWidget {
  const HudaIconMark(this.icon, {super.key, this.accent});

  final IconData icon;

  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final color = accent ?? scheme.primary;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.alphaBlend(color.withValues(alpha: 0.07), scheme.surface),
        border: Border.all(color: tokens.ornament.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class HudaSettingsRow extends StatelessWidget {
  const HudaSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = this.subtitle;
    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      child: ListTile(
        leading: HudaIconMark(icon),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: trailing,
        onTap: onTap,
        selected: selected,
        selectedTileColor: scheme.secondaryContainer.withValues(alpha: 0.5),
      ),
    );
  }
}

class HudaContentRow extends StatelessWidget {
  const HudaContentRow({
    super.key,
    required this.title,
    this.arabicTitle,
    this.meta,
    this.leading,
    this.trailing,
    this.onTap,
    this.selected = false,
  });

  final String title;

  final String? arabicTitle;
  final String? meta;
  final Widget? leading;

  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final arabicTitle = this.arabicTitle;
    final meta = this.meta;
    final leading = this.leading;
    final trailing =
        this.trailing ??
        (onTap == null
            ? null
            : Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ));
    final row = Padding(
      padding: EdgeInsets.symmetric(horizontal: space.md, vertical: space.sm),
      child: Row(
        children: [
          if (leading != null) ...[leading, SizedBox(width: space.md)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (arabicTitle != null)
                  Text(
                    arabicTitle,
                    textDirection: TextDirection.rtl,
                    style: context.type.arabicTitle.copyWith(fontSize: 19),
                  ),
                Text(title, style: theme.textTheme.titleMedium),
                if (meta != null) ...[
                  SizedBox(height: space.xxs),
                  Text(
                    meta,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: space.xs), trailing],
        ],
      ),
    );
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: row,
    );
    if (onTap == null) return content;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: selected
            ? ColoredBox(
                color: scheme.secondaryContainer.withValues(alpha: 0.5),
                child: content,
              )
            : content,
      ),
    );
  }
}

class HudaChoiceRow extends StatelessWidget {
  const HudaChoiceRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.titleStyle,
    this.titleDirection,
    this.semanticLabel,
  });

  final String title;
  final bool selected;
  final VoidCallback? onTap;
  final String? subtitle;
  final Widget? leading;

  final TextStyle? titleStyle;

  final TextDirection? titleDirection;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final duration = tokens.motion.of(context, tokens.motion.short);
    final radius = BorderRadius.circular(tokens.radius.md);
    final enabled = onTap != null;
    final subtitle = this.subtitle;
    final leading = this.leading;
    final tint = scheme.primary.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.16 : 0.08,
    );
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      button: true,
      label: semanticLabel ?? [title, ?subtitle].join(', '),
      excludeSemantics: true,
      child: HudaPressable(
        enabled: enabled,
        child: AnimatedContainer(
          duration: duration,
          curve: tokens.motion.standard,
          decoration: BoxDecoration(
            color: selected ? tint : Colors.transparent,
            borderRadius: radius,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? tokens.stroke.fine : tokens.stroke.hairline,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    space.md,
                    space.sm,
                    space.sm,
                    space.sm,
                  ),
                  child: Row(
                    children: [
                      if (leading != null) ...[
                        leading,
                        SizedBox(width: space.md),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              textDirection: titleDirection,
                              style:
                                  titleStyle ??
                                  theme.textTheme.titleSmall?.copyWith(
                                    color: scheme.onSurface,
                                  ),
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
                          ],
                        ),
                      ),
                      SizedBox(width: space.sm),
                      _ChoiceMark(selected: selected, duration: duration),
                    ],
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

class _ChoiceMark extends StatelessWidget {
  const _ChoiceMark({required this.selected, required this.duration});

  final bool selected;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 32,
      child: Center(
        child: AnimatedContainer(
          duration: duration,
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? scheme.primary : Colors.transparent,
            border: Border.all(
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              width: 1.5,
            ),
          ),
          child: AnimatedSwitcher(
            duration: duration,
            child: selected
                ? Icon(
                    Icons.check_rounded,
                    key: const ValueKey('on'),
                    size: 16,
                    color: scheme.onPrimary,
                  )
                : const SizedBox.shrink(key: ValueKey('off')),
          ),
        ),
      ),
    );
  }
}
