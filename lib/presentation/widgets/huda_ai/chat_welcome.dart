import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/huda_ai/chat_conversation.dart';
import 'package:huda/presentation/widgets/huda_ai/huda_ai_identity.dart';

/// A new chat: the gathering of light drifting in and then breathing in
/// place (owner round 1), a welcome, a quiet note, and things to ask that
/// send at a tap. Counseling has its own writing page (`CounselingView`).
class ChatWelcome extends StatelessWidget {
  const ChatWelcome({super.key, required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final space = context.tokens.space;
    final suggestions = [
      (Icons.mosque_outlined, l10n.exampleQuestion1),
      (Icons.self_improvement_rounded, l10n.exampleQuestion2),
      (Icons.bedtime_outlined, l10n.exampleQuestion3),
      (Icons.format_quote_rounded, l10n.exampleQuestion4),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Phone landscape: the light beside the words, so the first
        // suggestions show without scrolling (not at large text).
        final short =
            context.windowClass.isCompactHeight &&
            MediaQuery.textScalerOf(context).scale(1) < 1.3;
        final side = hudaAiSidePadding(
          context,
          width,
          ChatConversation.measure,
        );
        final content = width - 2 * side;
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final tile = 168 * scale;
        var columns = (content / tile).floor().clamp(1, 4);
        // An even count where a fold divides the space.
        if (context.fold.hasFold && columns.isOdd && columns > 1) columns--;
        if (columns == 3) columns = 2;

        final noor = HudaAiNoor(
          size: short ? 56 : 120,
          entrance: true,
          breathing: true,
        );
        final heading = Text(
          l10n.welcomeToHudaAI,
          textAlign: short ? TextAlign.start : TextAlign.center,
          style:
              (short
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineSmall)
                  ?.copyWith(color: scheme.onSurface),
        );
        final intro = Text(
          l10n.aiIntroMessage,
          textAlign: short ? TextAlign.start : TextAlign.center,
          maxLines: short ? 2 : null,
          overflow: short ? TextOverflow.ellipsis : null,
          style:
              (short ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge)
                  ?.copyWith(color: scheme.onSurfaceVariant),
        );
        final words = Column(
          crossAxisAlignment: short
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            heading,
            SizedBox(height: space.xs),
            intro,
          ],
        );
        final head = short
            ? Row(
                children: [
                  noor,
                  SizedBox(width: space.md),
                  Expanded(child: words),
                ],
              )
            : Column(
                children: [
                  noor,
                  SizedBox(height: space.md),
                  words,
                ],
              );

        final note = _Note(
          icon: Icons.verified_outlined,
          text: l10n.verifySourcesSubtitle,
        );

        final rows = <Widget>[];
        for (var i = 0; i < suggestions.length; i += columns) {
          final row = suggestions.sublist(
            i,
            math.min(i + columns, suggestions.length),
          );
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) SizedBox(width: space.sm),
                    Expanded(
                      child: j < row.length
                          ? HudaReveal(
                              index: 3 + i + j,
                              child: _Suggestion(
                                icon: row[j].$1,
                                text: row[j].$2,
                                onTap: () => onPick(row[j].$2),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return HudaRevealScope(
          child: SingleChildScrollView(
            padding: context.scrollPadding(
              EdgeInsets.fromLTRB(
                side,
                short ? space.sm : space.xl,
                side,
                space.xl,
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(0, constraints.maxHeight - space.huge * 2),
              ),
              child: Column(
                // On a short window the suggestions come first in view.
                mainAxisAlignment: short
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HudaReveal(index: 0, child: head),
                  // Each answer carries the same note; a short window
                  // keeps the room for the suggestions.
                  if (!short) ...[
                    SizedBox(height: space.lg),
                    HudaReveal(index: 1, child: Center(child: note)),
                  ],
                  SizedBox(height: short ? space.sm : space.xl),
                  HudaReveal(
                    index: 2,
                    child: Text(
                      l10n.tryAsking,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(height: space.xs),
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) SizedBox(height: space.sm),
                    rows[i],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A suggestion: a quiet card with a mark and the words it sends.
class _Suggestion extends StatelessWidget {
  const _Suggestion({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final space = context.tokens.space;
    return HudaCard(
      onTap: onTap,
      padding: EdgeInsets.all(space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: context.tokens.ornament),
          SizedBox(height: space.xs),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          SizedBox(width: context.tokens.space.xs),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
