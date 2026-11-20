import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/share/share_image_frame.dart';

TextDirection hudaAiTextDirection(String text) => shareTextDirection(text);

MarkdownStyleSheet hudaAiMarkdownStyle(
  BuildContext context, {
  TextStyle? body,
  Color? ink,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final tokens = context.tokens;
  final text = theme.textTheme;
  final color = ink ?? scheme.onSurface;
  final p = (body ?? text.bodyLarge!).copyWith(color: color);
  return MarkdownStyleSheet(
    p: p,
    pPadding: EdgeInsets.zero,
    h1: text.titleLarge?.copyWith(color: color),
    h2: text.titleMedium?.copyWith(color: color),
    h3: text.titleSmall?.copyWith(color: color),
    h4: text.titleSmall?.copyWith(color: color),
    h1Padding: EdgeInsets.only(top: tokens.space.xs),
    h2Padding: EdgeInsets.only(top: tokens.space.xs),
    h3Padding: EdgeInsets.only(top: tokens.space.xxs),
    strong: p.copyWith(fontWeight: FontWeight.w700),
    em: p.copyWith(fontStyle: FontStyle.italic),
    a: p.copyWith(color: scheme.primary, decoration: TextDecoration.underline),
    listBullet: p.copyWith(color: tokens.ornament),
    listIndent: 22,
    blockSpacing: tokens.space.sm,
    code: p.copyWith(
      fontFamily: 'monospace',
      fontSize: (p.fontSize ?? 15) * 0.88,
      backgroundColor: scheme.surfaceContainerHigh,
    ),
    codeblockDecoration: BoxDecoration(
      color: scheme.surfaceContainerHigh,
      borderRadius: tokens.radius.control,
    ),
    blockquote: p.copyWith(color: scheme.onSurfaceVariant),
    blockquotePadding: EdgeInsets.symmetric(
      horizontal: tokens.space.md,
      vertical: tokens.space.xxs,
    ),
    blockquoteDecoration: BoxDecoration(
      border: BorderDirectional(
        start: BorderSide(color: tokens.ornament, width: tokens.stroke.bold),
      ),
    ),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: scheme.outlineVariant)),
    ),
  );
}

class HudaAiMarkdown extends StatelessWidget {
  const HudaAiMarkdown(
    this.data, {
    super.key,
    this.selectable = true,
    this.body,
    this.ink,
  });

  final String data;
  final bool selectable;
  final TextStyle? body;
  final Color? ink;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: hudaAiTextDirection(data),
    child: MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: hudaAiMarkdownStyle(context, body: body, ink: ink),
    ),
  );
}
