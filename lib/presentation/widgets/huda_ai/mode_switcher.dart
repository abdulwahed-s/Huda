import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/chat_session_model.dart';
import 'package:huda/l10n/app_localizations.dart';

/// The icon for each mode, wherever a mode is shown (the segment, history
/// rows): one meaning per icon.
IconData hudaAiModeIcon(ChatSessionMode mode) => switch (mode) {
  ChatSessionMode.chat => Icons.chat_bubble_outline_rounded,
  ChatSessionMode.counseling => Icons.volunteer_activism_outlined,
};

/// Chat or Counseling: a two-part lit segment, sized to its labels and
/// centered in a pinned strip under the bar.
class ModeSwitcher extends StatelessWidget {
  const ModeSwitcher({super.key, required this.mode, required this.onChanged});

  final ChatSessionMode mode;
  final ValueChanged<ChatSessionMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final insets = MediaQuery.paddingOf(context);
    // Large text: the labels keep the room.
    final icons = MediaQuery.textScalerOf(context).scale(1) < 1.5;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        insets.left + space.md,
        space.xxs,
        insets.right + space.md,
        space.xs,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SegmentedButton<ChatSessionMode>(
            key: const ValueKey('huda_ai_mode'),
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            segments: [
              for (final value in ChatSessionMode.values)
                ButtonSegment(
                  value: value,
                  icon: icons ? Icon(hudaAiModeIcon(value)) : null,
                  label: Text(
                    value == ChatSessionMode.chat ? l10n.chat : l10n.counseling,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            selected: {mode},
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
        ),
      ),
    );
  }
}
