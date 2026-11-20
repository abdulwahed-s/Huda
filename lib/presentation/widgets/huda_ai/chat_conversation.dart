import 'package:flutter/material.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/chat_error.dart';
import 'package:huda/data/models/chat_message_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/huda_ai/chat_turns.dart';

String hudaAiErrorMessage(AppLocalizations l10n, ChatErrorType type) =>
    switch (type) {
      ChatErrorType.noConnection => l10n.chatErrorNoConnection,
      ChatErrorType.rateLimit => l10n.chatErrorRateLimit,
      ChatErrorType.server => l10n.chatErrorServer,
      ChatErrorType.safetyFilter => l10n.chatErrorSafety,
      ChatErrorType.interrupted => l10n.chatErrorInterrupted,
      ChatErrorType.unknown => l10n.chatErrorGeneric,
    };

double hudaAiSidePadding(BuildContext context, double width, double measure) {
  final gutter = context.tokens.space.gutter(width);
  return ((width - measure) / 2).clamp(gutter, double.infinity);
}

class ChatConversation extends StatefulWidget {
  const ChatConversation({
    super.key,
    required this.sessionId,
    required this.messages,
    required this.waiting,
    required this.errorType,
    required this.retrying,
    required this.onRetry,
    required this.onCopy,
    required this.onShare,
    this.onEdit,
  });

  final String? sessionId;
  final List<ChatMessage> messages;

  final bool waiting;
  final ChatErrorType? errorType;

  final bool retrying;
  final VoidCallback onRetry;
  final ValueChanged<String> onCopy;
  final void Function(String? question, String answer) onShare;

  final VoidCallback? onEdit;

  static const double measure = 720;

  @override
  State<ChatConversation> createState() => _ChatConversationState();
}

class _ChatConversationState extends State<ChatConversation> {
  final ScrollController _scroll = ScrollController();

  late Set<String> _opened = _ids();

  String? _tailId;
  int _slotEpoch = 0;

  Set<String> _ids() => {for (final m in widget.messages) m.id};

  @override
  void initState() {
    super.initState();
    _toEnd(jump: true);
  }

  @override
  void didUpdateWidget(ChatConversation old) {
    super.didUpdateWidget(old);
    if (old.sessionId != widget.sessionId) {
      _opened = _ids();
      _toEnd(jump: true);
      return;
    }
    final sent =
        widget.messages.length > old.messages.length &&
        widget.messages.last.sender == Sender.user;
    final changed =
        sent ||
        widget.messages.length != old.messages.length ||
        widget.waiting != old.waiting ||
        widget.errorType != old.errorType ||
        (widget.messages.isNotEmpty &&
            old.messages.isNotEmpty &&
            widget.messages.last.text != old.messages.last.text);
    if (changed && (sent || _atEnd)) _toEnd();
  }

  bool get _atEnd {
    if (!_scroll.hasClients) return true;
    final position = _scroll.position;
    return position.maxScrollExtent - position.pixels < 160;
  }

  void _toEnd({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      final duration = context.tokens.motion.of(
        context,
        context.tokens.motion.long,
      );
      if (jump || duration == Duration.zero) {
        _scroll.jumpTo(end);
      } else {
        _scroll.animateTo(
          end,
          duration: duration,
          curve: context.tokens.motion.standard,
        );
      }
      if (jump) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scroll.hasClients) {
            _scroll.jumpTo(_scroll.position.maxScrollExtent);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final messages = widget.messages;
    final last = messages.isEmpty ? null : messages.last;
    final thinking =
        widget.waiting && (last == null || last.sender == Sender.user);
    final error = widget.waiting ? null : widget.errorType;

    final tail =
        last != null &&
            last.sender == Sender.model &&
            !_opened.contains(last.id)
        ? last
        : null;
    if (_tailId != null && _tailId != tail?.id) {
      _slotEpoch++;
    }
    _tailId = tail?.id;

    final items = <Widget>[];
    String? question;
    String? tailQuestion;
    for (final message in messages) {
      if (message.sender == Sender.user) {
        question = message.text;
        items.add(
          HudaAiRiseIn(
            key: ValueKey('user-${message.id}'),
            animate: !_opened.contains(message.id),
            child: HudaAiUserTurn(text: message.text),
          ),
        );
        continue;
      }
      if (identical(message, tail)) {
        tailQuestion = question;
        continue;
      }
      items.add(
        KeyedSubtree(
          key: ValueKey('answer-${message.id}'),
          child: _answer(message, question),
        ),
      );
    }

    final Widget status = thinking
        ? HudaAiThinking(
            key: const ValueKey('thinking'),
            retrying: widget.retrying,
          )
        : tail != null
        ? KeyedSubtree(
            key: ValueKey('answer-${tail.id}'),
            child: _answer(tail, tailQuestion),
          )
        : const SizedBox(key: ValueKey('none'), width: double.infinity);
    items.add(
      HudaStateSwitcher(
        key: ValueKey('status-$_slotEpoch'),
        stateKey: status.key!,
        sequential: true,
        child: status,
      ),
    );
    if (error != null) {
      final safety = error == ChatErrorType.safetyFilter;
      final onEdit = widget.onEdit;
      items.add(
        HudaAiRiseIn(
          key: ValueKey('error-$error'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HudaStatusBanner(
                status: HudaStatus.failed,
                message: hudaAiErrorMessage(l10n, error),
                onRetry: safety ? null : widget.onRetry,
              ),
              if (safety && onEdit != null) ...[
                SizedBox(height: space.xs),
                OutlinedButton.icon(
                  key: const ValueKey('huda_ai_edit'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.edit),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = hudaAiSidePadding(
          context,
          constraints.maxWidth,
          ChatConversation.measure,
        );
        return ListView.separated(
          controller: _scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: context.scrollPadding(
            EdgeInsets.fromLTRB(side, space.md, side, space.xl),
          ),
          itemCount: items.length,
          separatorBuilder: (context, index) => SizedBox(height: space.xl),
          itemBuilder: (context, index) => items[index],
          findItemIndexCallback: (key) {
            final index = items.indexWhere((item) => item.key == key);
            return index < 0 ? null : index;
          },
        );
      },
    );
  }

  Widget _answer(ChatMessage message, String? question) => HudaAiAnswer(
    text: message.text,
    writing: !message.isComplete && widget.waiting,
    onCopy: () => widget.onCopy(message.text),
    onShare: () => widget.onShare(question, message.text),
  );
}
