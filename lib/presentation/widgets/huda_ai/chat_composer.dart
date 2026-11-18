import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';

/// Where the person writes: a field that grows to six lines, then
/// scrolls, and a lit Send. Pinned to the bottom edge: its surface runs
/// under the navigation bar and its content is lifted by the inset (the
/// inset drops to zero while the keyboard is up).
///
/// On desktops Enter sends and Shift+Enter starts a new line.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.hintText,
    required this.enabled,
    required this.onSend,
    this.maxWidth = 720,
    this.reachesBottom = true,
  });

  final TextEditingController controller;
  final String hintText;

  /// False while an answer is coming: typing stays possible, sending not.
  final bool enabled;
  final ValueChanged<String> onSend;
  final double maxWidth;

  /// Whether the bar owns the window's bottom edge (lifts by its inset).
  final bool reachesBottom;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  late final FocusNode _focus = FocusNode(onKeyEvent: _onKey);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(ChatComposer old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  bool get _canSend =>
      widget.enabled && widget.controller.text.trim().isNotEmpty;

  bool get _desktop => switch (Theme.of(context).platform) {
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux => true,
    _ => false,
  };

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_desktop || event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) return KeyEventResult.ignored;
    _send();
    return KeyEventResult.handled;
  }

  void _send() {
    if (!_canSend) return;
    widget.onSend(widget.controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final insets = MediaQuery.paddingOf(context);
    final field = TextField(
      controller: widget.controller,
      focusNode: _focus,
      minLines: 1,
      maxLines: 6,
      keyboardType: TextInputType.multiline,
      textInputAction: _desktop
          ? TextInputAction.send
          : TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintMaxLines: 1,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: space.md,
          vertical: space.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius.xl),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius.xl),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius.xl),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
    );
    final send = IconButton.filled(
      key: const ValueKey('huda_ai_send'),
      tooltip: l10n.hudaAiSend,
      onPressed: _canSend ? _send : null,
      style: IconButton.styleFrom(minimumSize: const Size.square(48)),
      icon: const Icon(Icons.arrow_upward_rounded),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          insets.left + space.sm,
          space.xs,
          insets.right + space.sm,
          space.xs + (widget.reachesBottom ? context.bottomInset : 0),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.maxWidth),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: field),
                SizedBox(width: space.xs),
                send,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
