import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/chat/chat_cubit.dart';
import 'package:huda/data/models/chat_message_model.dart';
import 'package:huda/data/models/chat_session_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/huda_ai/chat_composer.dart';
import 'package:huda/presentation/widgets/huda_ai/chat_conversation.dart';
import 'package:huda/presentation/widgets/huda_ai/chat_history.dart';
import 'package:huda/presentation/widgets/huda_ai/chat_turns.dart';
import 'package:huda/presentation/widgets/huda_ai/chat_welcome.dart';
import 'package:huda/presentation/widgets/huda_ai/counseling_view.dart';
import 'package:huda/presentation/widgets/huda_ai/huda_ai_share_sheet.dart';
import 'package:huda/presentation/widgets/huda_ai/mode_switcher.dart';

/// Huda AI: ask about Islam (Chat) or share a feeling (Counseling), and
/// come back to past conversations. A standard-tier screen: the
/// conversation at a reading measure over a pinned composer; the history
/// in a sheet on phones and medium windows, inline beside the
/// conversation from 840 and on folds, under the composer on a tabletop
/// fold. See `design/features/huda-ai/brief.md`.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

/// History goes inline from portrait tablets up: a 720 window leaves the
/// conversation 400 beside a 320 pane.

class _ChatScreenState extends State<ChatScreen> {
  /// The chat composer's text.
  final TextEditingController _controller = TextEditingController();

  /// Counseling's writing area (kept across mode switches, refilled by
  /// Edit).
  final TextEditingController _feeling = TextEditingController();

  /// The conversation whose Retry was tapped, until its answer stops
  /// generating ("Retrying…" instead of "thinking").
  String? _retrying;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ChatCubit>().onScreenOpened();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _feeling.dispose();
    super.dispose();
  }

  ChatCubit get _cubit => context.read<ChatCubit>();

  void _send(String text) {
    _cubit.sendMessage(text);
    _controller.clear();
  }

  void _seek(String feeling) {
    FocusScope.of(context).unfocus();
    _cubit.sendCounselingRequest(feeling);
    _feeling.clear();
  }

  void _startNewChat() {
    FocusScope.of(context).unfocus();
    _controller.clear();
    _feeling.clear();
    _cubit.startNewSession();
  }

  /// After a safety refusal: the feeling back on the writing page.
  void _editFeeling(String? text) {
    if (text == null) return;
    _feeling
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
    _cubit.startNewSession();
  }

  void _conversationChanged() {
    FocusScope.of(context).unfocus();
    _controller.clear();
  }

  void _retry() {
    final session = _cubit.state.activeSession;
    if (session == null) return;
    setState(() => _retrying = session.id);
    if (session.mode == ChatSessionMode.counseling) {
      _cubit.retryCounselingRequest();
    } else {
      _cubit.retryLastMessage();
    }
  }

  /// Puts [text] back in the composer to rephrase it.
  void _edit(String? text) {
    if (text == null) return;
    _controller
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showHudaToast(
      context,
      message: AppLocalizations.of(context)!.messageCopied,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MultiBlocListener(
      listeners: [
        BlocListener<ChatCubit, ChatState>(
          listenWhen: (previous, current) =>
              previous.isHydrating && !current.isHydrating,
          listener: (context, state) => _cubit.onScreenOpened(),
        ),
        BlocListener<ChatCubit, ChatState>(
          listenWhen: (previous, current) =>
              !previous.storageWarning && current.storageWarning,
          listener: (context, state) => showHudaToast(
            context,
            message: l10n.aiStorageWarning,
            kind: HudaToastKind.failed,
            actionLabel: l10n.close,
            onAction: _cubit.dismissStorageWarning,
            duration: const Duration(seconds: 8),
          ),
        ),
        BlocListener<ChatCubit, ChatState>(
          listenWhen: (previous, current) =>
              _retrying != null &&
              (current.activeSession?.id != _retrying || !current.isLoading),
          listener: (context, state) => setState(() => _retrying = null),
        ),
      ],
      child: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          // History is never a standing pane on wide windows (it took half
          // the screen): it opens from the app bar, as a side sheet there.
          // Only a tabletop fold keeps it inline, in the bottom half.
          final inline = TabletopSplit.applies(context);
          final tabletop = inline;
          return HudaScaffold(
            title: l10n.hudaAI,
            actions: inline
                ? const []
                : [
                    IconButton(
                      key: const ValueKey('huda_ai_history'),
                      tooltip: l10n.aiHistory,
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        showHudaAiHistory(
                          context,
                          onOpened: _conversationChanged,
                        );
                      },
                      icon: const Icon(Icons.history_rounded),
                    ),
                    IconButton(
                      key: const ValueKey('huda_ai_new_chat'),
                      tooltip: l10n.newChat,
                      onPressed: _startNewChat,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
            body: tabletop
                ? TabletopSplit(
                    top: _conversationPane(state, composer: false),
                    bottom: Column(
                      children: [
                        _modes(state),
                        if (!state.isCounselingMode)
                          ..._composer(state, reachesBottom: false),
                        Expanded(
                          child: _history(ChatHistoryPresentation.tabletop),
                        ),
                      ],
                    ),
                  )
                : _conversationPane(state, composer: true),
          );
        },
      ),
    );
  }

  Widget _history(ChatHistoryPresentation presentation) => ChatHistory(
    presentation: presentation,
    onOpened: _conversationChanged,
    onNewChat: _startNewChat,
  );

  Widget _modes(ChatState state) => ModeSwitcher(
    mode: state.selectedMode,
    onChanged: (mode) {
      if (mode != state.selectedMode) {
        _conversationChanged();
        _cubit.toggleMode();
      }
    },
  );

  bool _busyElsewhere(ChatState state) =>
      state.hasActiveRequest &&
      state.activeRequestSessionId != state.activeSession?.id;

  /// The chat composer (counseling writes in its page instead).
  List<Widget> _composer(ChatState state, {required bool reachesBottom}) {
    final l10n = AppLocalizations.of(context)!;
    return [
      if (_busyElsewhere(state))
        HudaAiStatusLine(text: l10n.aiBusyOtherConversation),
      ChatComposer(
        controller: _controller,
        hintText: l10n.typeMessageHint,
        enabled: !state.hasActiveRequest && !state.isHydrating,
        onSend: _send,
        reachesBottom: reachesBottom,
      ),
    ];
  }

  Widget _conversationPane(ChatState state, {required bool composer}) {
    final content = _content(state);
    // The segment sits over the pane, except on tabletop (below the band).
    final modes = composer;
    // Counseling has no composer: its page owns the bottom edge.
    composer = composer && !state.isCounselingMode;
    return Column(
      children: [
        if (modes) _modes(state),
        Expanded(
          // The pane's own context: inside a tabletop half or a pane the
          // screen's would bring back the whole window's size and fold.
          child: Builder(
            builder: (context) => MediaQuery.removePadding(
              context: context,
              // The composer owns the bottom edge.
              removeBottom: composer,
              child: HudaStateSwitcher(
                stateKey: content.key!,
                sequential: true,
                child: content,
              ),
            ),
          ),
        ),
        if (composer) ..._composer(state, reachesBottom: true),
      ],
    );
  }

  Widget _content(ChatState state) {
    if (state.isHydrating) {
      return const _ConversationSkeleton(key: ValueKey('hydrating'));
    }
    final session = state.activeSession;
    final waiting = state.isLoading;
    if (state.isCounselingMode) {
      // A chat session can't show here (the mode follows the session).
      final counsel = session?.mode == ChatSessionMode.counseling
          ? session
          : null;
      final response = counsel?.counselingResponse;
      return CounselingView(
        key: const ValueKey('counseling'),
        sessionId: counsel?.id,
        feeling: counsel?.counselingRequest,
        response: response,
        waiting: waiting,
        errorType: counsel?.errorType,
        retrying: counsel != null && _retrying == counsel.id,
        controller: _feeling,
        canSeek: !state.hasActiveRequest,
        busyElsewhere: _busyElsewhere(state),
        onSeek: _seek,
        onRetry: _retry,
        onEdit: () => _editFeeling(counsel?.counselingRequest),
        onAnother: _startNewChat,
        onCopy: () {
          if (response != null) {
            _copy(hudaAiCounselText(AppLocalizations.of(context)!, response));
          }
        },
        onShare: () {
          if (response != null) {
            shareHudaAiCounsel(
              context,
              response: response,
              feeling: counsel?.counselingRequest,
            );
          }
        },
      );
    }
    if (session == null || (session.messages.isEmpty && !waiting)) {
      return ChatWelcome(key: const ValueKey('welcome-chat'), onPick: _send);
    }
    return ChatConversation(
      key: ValueKey('chat-${session.id}'),
      sessionId: session.id,
      messages: session.messages,
      waiting: waiting,
      errorType: session.errorType,
      retrying: _retrying == session.id,
      onRetry: _retry,
      onEdit: () => _edit(
        session.messages
            .lastWhere(
              (m) => m.sender == Sender.user,
              orElse: () => session.messages.last,
            )
            .text,
      ),
      onCopy: _copy,
      onShare: (question, answer) =>
          shareHudaAiAnswer(context, answer: answer, question: question),
    );
  }
}

/// The saved history loading: a conversation's shape.
class _ConversationSkeleton extends StatelessWidget {
  const _ConversationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final body = Theme.of(context).textTheme.bodyLarge;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = hudaAiSidePadding(
          context,
          constraints.maxWidth,
          ChatConversation.measure,
        );
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(side, space.md, side, 0),
          child: HudaSkeleton(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: HudaSkeletonBlock(width: 220, height: 44),
                ),
                SizedBox(height: space.xl),
                Row(
                  children: [
                    const HudaSkeletonBlock(
                      width: 28,
                      height: 28,
                      circle: true,
                    ),
                    SizedBox(width: space.xs),
                    const HudaSkeletonBlock(width: 72, height: 12),
                  ],
                ),
                SizedBox(height: space.sm),
                HudaSkeletonLines(lines: 5, style: body),
              ],
            ),
          ),
        );
      },
    );
  }
}
