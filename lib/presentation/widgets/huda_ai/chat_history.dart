import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/chat/chat_cubit.dart';
import 'package:huda/data/models/chat_session_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_search_field.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/huda_ai/huda_ai_identity.dart';
import 'package:huda/presentation/widgets/huda_ai/huda_ai_text.dart';
import 'package:huda/presentation/widgets/huda_ai/mode_switcher.dart';
import 'package:intl/intl.dart';

/// Opens the history where it isn't shown inline: a full-height bottom
/// sheet on phones, a dialog on medium windows.
Future<void> showHudaAiHistory(
  BuildContext context, {
  required VoidCallback onOpened,
}) {
  final l10n = AppLocalizations.of(context)!;
  final cubit = context.read<ChatCubit>();
  return showHudaSheet<void>(
    context: context,
    title: l10n.aiHistory,
    expand: true,
    // A side sheet on wide windows, like the Books language list.
    sideSheet: true,
    maxDialogWidth: 560,
    builder: (sheetContext) => BlocProvider.value(
      value: cubit,
      child: ChatHistory(
        presentation: ChatHistoryPresentation.sheet,
        onOpened: () {
          onOpened();
          Navigator.of(sheetContext).pop();
        },
      ),
    ),
  );
}

enum ChatHistoryPresentation {
  /// Beside the conversation, with New chat at its head.
  pane,

  /// Below the composer on a tabletop fold, with New chat.
  tabletop,

  /// In a sheet or dialog that closes once a conversation opens.
  sheet,
}

/// Saved conversations, newest first: search, open, delete, clear all.
/// Where it's inline it also holds New chat (the app bar then has none).
class ChatHistory extends StatefulWidget {
  const ChatHistory({
    super.key,
    required this.presentation,
    required this.onOpened,
    this.onNewChat,
  });

  final ChatHistoryPresentation presentation;

  /// A conversation was opened or the open one was deleted: the screen
  /// clears what was typed.
  final VoidCallback onOpened;
  final VoidCallback? onNewChat;

  @override
  State<ChatHistory> createState() => _ChatHistoryState();
}

class _ChatHistoryState extends State<ChatHistory> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String? _opening;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
  }

  Future<void> _open(String id) async {
    if (_opening != null) return;
    final cubit = context.read<ChatCubit>();
    if (cubit.state.activeSession?.id == id) {
      widget.onOpened();
      return;
    }
    setState(() => _opening = id);
    await cubit.selectSession(id);
    if (!mounted) return;
    setState(() => _opening = null);
    if (cubit.state.activeSession?.id == id) widget.onOpened();
  }

  Future<void> _delete(ChatSessionSummary summary) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirm(
      context,
      title: l10n.deleteChat,
      message: l10n.deleteChatConfirmation,
      action: l10n.delete,
    );
    if (!confirmed || !mounted) return;
    HudaHaptics.light(context);
    final cubit = context.read<ChatCubit>();
    final active = cubit.state.activeSession?.id == summary.id;
    await cubit.deleteSession(summary.id);
    if (mounted && active) widget.onOpened();
  }

  Future<void> _clearAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirm(
      context,
      title: l10n.clearAllHistory,
      message: l10n.clearAllHistoryConfirmation,
      action: l10n.clearAll,
    );
    if (!confirmed || !mounted) return;
    HudaHaptics.light(context);
    await context.read<ChatCubit>().clearHistory();
    if (!mounted) return;
    _clearSearch();
    widget.onOpened();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final space = tokens.space;
    final insets = MediaQuery.paddingOf(context);
    final sheet = widget.presentation == ChatHistoryPresentation.sheet;
    final dialog =
        sheet && context.findAncestorWidgetOfExactType<Dialog>() != null;
    final onNewChat = widget.onNewChat;

    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        final q = _query.toLowerCase();
        final sessions = [
          for (final s in state.summaries)
            if (q.isEmpty ||
                s.title.toLowerCase().contains(q) ||
                s.preview.toLowerCase().contains(q))
              s,
        ];
        final hasHistory = state.summaries.isNotEmpty;
        final edge = EdgeInsets.only(
          left: insets.left + space.md,
          right: insets.right + space.md,
        );

        final header = Padding(
          padding: edge.copyWith(top: sheet ? 0 : space.sm),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.aiHistory,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              if (hasHistory)
                PopupMenuButton<_HistoryAction>(
                  key: const ValueKey('huda_ai_history_more'),
                  tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (_) => _clearAll(),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      // A value: a null one reads as "dismissed" and never
                      // calls onSelected.
                      value: _HistoryAction.clearAll,
                      child: _MenuRow(
                        icon: Icons.delete_sweep_outlined,
                        label: l10n.clearAllHistory,
                      ),
                    ),
                  ],
                ),
              if (dialog)
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
        );

        final Widget body;
        if (state.isHydrating) {
          body = const _HistorySkeleton(key: ValueKey('hydrating'));
        } else if (!hasHistory) {
          body = _HistoryEmpty(
            key: const ValueKey('empty'),
            message: l10n.noChatHistory,
          );
        } else if (sessions.isEmpty) {
          body = _HistoryEmpty(
            key: const ValueKey('no-results'),
            message: l10n.noHistoryResults,
            actionLabel: l10n.clear,
            onAction: _clearSearch,
          );
        } else {
          body = HudaRevealScope(
            key: const ValueKey('list'),
            child: ListView.separated(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: context.scrollPadding(
                EdgeInsets.fromLTRB(space.xs, space.xxs, space.xs, space.lg),
              ),
              itemCount: sessions.length,
              separatorBuilder: (context, index) => SizedBox(height: space.xxs),
              itemBuilder: (context, index) {
                final summary = sessions[index];
                return HudaReveal(
                  index: index,
                  child: _HistoryRow(
                    summary: summary,
                    selected: state.activeSession?.id == summary.id,
                    opening: _opening == summary.id,
                    onTap: () => _open(summary.id),
                    onDelete: () => _delete(summary),
                  ),
                );
              },
            ),
          );
        }

        return Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              if (onNewChat != null)
                Padding(
                  padding: edge.copyWith(top: space.xs),
                  child: FilledButton.icon(
                    key: const ValueKey('huda_ai_new_chat'),
                    onPressed: onNewChat,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.newChat),
                  ),
                ),
              if (hasHistory)
                Padding(
                  padding: edge.copyWith(top: space.sm, bottom: space.xs),
                  child: HudaSearchField(
                    controller: _search,
                    hintText: l10n.searchConversations,
                    onChanged: (value) => setState(() => _query = value.trim()),
                  ),
                ),
              Expanded(
                child: HudaStateSwitcher(stateKey: body.key!, child: body),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _HistoryAction { delete, clearAll }

/// The saved history loading: rows in their shape (never "no history").
class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(space.md),
      child: HudaSkeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HudaSkeletonBlock(height: 48),
            for (var i = 0; i < 4; i++) ...[
              SizedBox(height: space.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HudaSkeletonBlock(width: 36, height: 36, circle: true),
                  SizedBox(width: space.sm),
                  Expanded(
                    child: HudaSkeletonLines(lines: 3, style: text.bodySmall),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Row(
      children: [
        Icon(icon, size: 20, color: error),
        SizedBox(width: context.tokens.space.sm),
        Flexible(
          child: Text(label, style: TextStyle(color: error)),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.summary,
    required this.selected,
    required this.opening,
    required this.onTap,
    required this.onDelete,
  });

  final ChatSessionSummary summary;
  final bool selected;
  final bool opening;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final dark = theme.brightness == Brightness.dark;
    final mode = summary.mode == ChatSessionMode.chat
        ? l10n.chat
        : l10n.counseling;
    final meta = '$mode · ${_when(context, summary.updatedAt, l10n)}';
    final status = switch (summary.generationStatus) {
      ChatGenerationStatus.ready => null,
      ChatGenerationStatus.generating => (
        l10n.aiResponseGenerating,
        scheme.primary,
      ),
      ChatGenerationStatus.interrupted => (
        l10n.aiResponseInterrupted,
        scheme.tertiary,
      ),
      ChatGenerationStatus.failed => (l10n.aiResponseFailed, scheme.error),
    };
    final generatingTitle = summary.titleStatus == ChatTitleStatus.generating;

    return Semantics(
      selected: selected,
      child: AnimatedContainer(
        duration: tokens.motion.of(context, tokens.motion.short),
        decoration: BoxDecoration(
          color: selected
              ? Color.alphaBlend(
                  scheme.primary.withValues(alpha: dark ? 0.20 : 0.09),
                  scheme.surface,
                ).withValues(alpha: 1)
              : Colors.transparent,
          borderRadius: tokens.radius.control,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: tokens.radius.control,
            onTap: opening ? null : onTap,
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                space.sm,
                space.sm,
                space.xxs,
                space.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HudaIconMark(hudaAiModeIcon(summary.mode)),
                  SizedBox(width: space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                summary.title,
                                textDirection: hudaAiTextDirection(
                                  summary.title,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            if (generatingTitle) ...[
                              SizedBox(width: space.xs),
                              HudaLampSpinner(size: 14, color: tokens.ornament),
                            ],
                          ],
                        ),
                        if (summary.preview.trim().isNotEmpty &&
                            summary.preview.trim() != summary.title.trim()) ...[
                          SizedBox(height: space.xxs),
                          Text(
                            summary.preview.trim(),
                            textDirection: hudaAiTextDirection(summary.preview),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        SizedBox(height: space.xxs),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: meta),
                              if (status != null)
                                TextSpan(
                                  text: ' · ${status.$1}',
                                  style: TextStyle(color: status.$2),
                                ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (opening)
                    const SizedBox.square(
                      dimension: 48,
                      child: Center(child: HudaLampSpinner(size: 18)),
                    )
                  else
                    PopupMenuButton<_HistoryAction>(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).moreButtonTooltip,
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                      onSelected: (_) => onDelete(),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _HistoryAction.delete,
                          child: _MenuRow(
                            icon: Icons.delete_outline_rounded,
                            label: l10n.deleteChat,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final space = context.tokens.space;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: context.scrollPadding(EdgeInsets.all(space.xl)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - space.xl * 2 - 40).clamp(
              0,
              double.infinity,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HudaAiNoor(size: 72),
              SizedBox(height: space.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                SizedBox(height: space.xs),
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _when(BuildContext context, DateTime at, AppLocalizations l10n) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final local = at.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final days = today.difference(day).inDays;
  if (days == 0) return '${l10n.today} ${DateFormat.jm(locale).format(local)}';
  if (days > 0 && days < 7) return DateFormat.EEEE(locale).format(local);
  if (local.year == now.year) return DateFormat.MMMd(locale).format(local);
  return DateFormat.yMMMd(locale).format(local);
}
