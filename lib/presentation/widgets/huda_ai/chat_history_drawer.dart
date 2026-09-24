import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/chat/chat_cubit.dart';
import 'package:huda/data/models/chat_session_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ChatHistoryDrawer extends StatefulWidget {
  const ChatHistoryDrawer({
    super.key,
    required this.onNewChat,
    required this.onSessionSelected,
  });

  final VoidCallback onNewChat;
  final VoidCallback onSessionSelected;

  @override
  State<ChatHistoryDrawer> createState() => _ChatHistoryDrawerState();
}

class _ChatHistoryDrawerState extends State<ChatHistoryDrawer> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _openingSessionId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  void _startNewChat() {
    _searchController.clear();
    _query = '';
    widget.onNewChat();
    Navigator.of(context).pop();
  }

  Future<void> _openSession(String id) async {
    if (_openingSessionId != null) return;
    setState(() => _openingSessionId = id);

    final chatCubit = context.read<ChatCubit>();
    await chatCubit.selectSession(id);
    if (!mounted) return;

    setState(() => _openingSessionId = null);
    if (chatCubit.state.activeSession?.id != id) return;

    widget.onSessionSelected();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = (screenWidth * 0.92).clamp(288.0, 400.0);

    return Drawer(
      width: drawerWidth,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      backgroundColor: isDark
          ? context.darkGradientStart
          : context.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(28),
          bottomStart: Radius.circular(28),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Column(
          children: [
            BlocSelector<ChatCubit, ChatState, bool>(
              selector: (state) => state.summaries.isNotEmpty,
              builder: (context, hasHistory) => _DrawerHeader(
                isDark: isDark,
                title: l10n.aiHistory,
                newChatLabel: l10n.newChat,
                clearAllLabel: l10n.clearAllHistory,
                hasHistory: hasHistory,
                onClose: () => Navigator.of(context).pop(),
                onNewChat: _startNewChat,
                onClearAll: () => _confirmClearAll(context),
              ),
            ),
            Expanded(
              child: BlocBuilder<ChatCubit, ChatState>(
                builder: (context, state) {
                  final normalizedQuery = _query.toLowerCase();
                  final sessions = state.summaries
                      .where((summary) {
                        if (normalizedQuery.isEmpty) return true;
                        return summary.title.toLowerCase().contains(
                              normalizedQuery,
                            ) ||
                            summary.preview.toLowerCase().contains(
                              normalizedQuery,
                            );
                      })
                      .toList(growable: false);

                  return Column(
                    children: [
                      if (state.summaries.isNotEmpty)
                        _HistorySearchField(
                          controller: _searchController,
                          query: _query,
                          isDark: isDark,
                          hintText: l10n.searchConversations,
                          clearTooltip: l10n.clear,
                          onChanged: (value) =>
                              setState(() => _query = value.trim()),
                          onClear: _clearSearch,
                        ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _buildHistoryContent(
                            context: context,
                            state: state,
                            sessions: sessions,
                            l10n: l10n,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryContent({
    required BuildContext context,
    required ChatState state,
    required List<ChatSessionSummary> sessions,
    required AppLocalizations l10n,
    required bool isDark,
  }) {
    if (state.summaries.isEmpty) {
      return _EmptyHistory(
        key: const ValueKey('empty-history'),
        icon: Icons.forum_outlined,
        message: l10n.noChatHistory,
      );
    }

    if (sessions.isEmpty) {
      return _EmptyHistory(
        key: const ValueKey('empty-search'),
        icon: Icons.search_off_rounded,
        message: l10n.noHistoryResults,
        actionLabel: l10n.clear,
        onAction: _clearSearch,
      );
    }

    return ListView.separated(
      key: const ValueKey('history-list'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
      itemCount: sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final summary = sessions[index];
        return _HistoryTile(
          summary: summary,
          selected: state.activeSession?.id == summary.id,
          isDark: isDark,
          isOpening: _openingSessionId == summary.id,
          onTap: () => _openSession(summary.id),
          onDelete: () => _confirmDelete(context, summary),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ChatSessionSummary summary,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _DestructiveConfirmationDialog(
        icon: Icons.delete_outline_rounded,
        title: l10n.deleteChat,
        message: l10n.deleteChatConfirmation,
        cancelLabel: l10n.cancel,
        confirmLabel: l10n.delete,
      ),
    );
    if (shouldDelete == true && context.mounted) {
      final deletingActive =
          context.read<ChatCubit>().state.activeSession?.id == summary.id;
      await context.read<ChatCubit>().deleteSession(summary.id);
      if (!mounted) return;
      if (deletingActive) widget.onSessionSelected();
    }
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _DestructiveConfirmationDialog(
        icon: Icons.delete_sweep_outlined,
        title: l10n.clearAllHistory,
        message: l10n.clearAllHistoryConfirmation,
        cancelLabel: l10n.cancel,
        confirmLabel: l10n.clearAll,
      ),
    );
    if (shouldClear == true && context.mounted) {
      await context.read<ChatCubit>().clearHistory();
      if (!mounted) return;
      widget.onSessionSelected();
      _clearSearch();
    }
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.isDark,
    required this.title,
    required this.newChatLabel,
    required this.clearAllLabel,
    required this.hasHistory,
    required this.onClose,
    required this.onNewChat,
    required this.onClearAll,
  });

  final bool isDark;
  final String title;
  final String newChatLabel;
  final String clearAllLabel;
  final bool hasHistory;
  final VoidCallback onClose;
  final VoidCallback onNewChat;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = isDark ? context.darkText : context.lightText;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 14, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            context.primaryColor.withValues(alpha: isDark ? 0.18 : 0.10),
            context.primaryColor.withValues(alpha: 0.02),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.35)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(
                    alpha: isDark ? 0.24 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: context.primaryColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (hasHistory)
                PopupMenuButton<_DrawerAction>(
                  tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
                  position: PopupMenuPosition.under,
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (action) {
                    if (action == _DrawerAction.clearAll) onClearAll();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _DrawerAction.clearAll,
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_sweep_outlined,
                            size: 20,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            clearAllLabel,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: onClose,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface.withValues(
                    alpha: 0.7,
                  ),
                  minimumSize: const Size.square(48),
                ),
                icon: const Icon(Icons.close_rounded, size: 21),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onNewChat,
              style: FilledButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 22),
              label: Text(
                newChatLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _DrawerAction { clearAll }

class _HistorySearchField extends StatelessWidget {
  const _HistorySearchField({
    required this.controller,
    required this.query,
    required this.isDark,
    required this.hintText,
    required this.clearTooltip,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final bool isDark;
  final String hintText;
  final String clearTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: SizedBox(
        height: 48,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 21,
              color: context.primaryColor,
            ),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: clearTooltip,
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 19),
                  ),
            filled: true,
            fillColor: isDark
                ? context.darkCardBackground.withValues(alpha: 0.88)
                : Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: context.primaryColor, width: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}

enum _HistoryAction { delete }

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.summary,
    required this.selected,
    required this.isDark,
    required this.isOpening,
    required this.onTap,
    required this.onDelete,
  });

  final ChatSessionSummary summary;
  final bool selected;
  final bool isDark;
  final bool isOpening;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final primaryColor = context.primaryColor;
    final timestamp = _formatTimestamp(context, summary.updatedAt, l10n);
    final modeLabel = summary.mode == ChatSessionMode.chat
        ? l10n.chat
        : l10n.counseling;

    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withValues(alpha: isDark ? 0.22 : 0.09)
              : isDark
              ? context.darkCardBackground.withValues(alpha: 0.82)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? primaryColor.withValues(alpha: isDark ? 0.55 : 0.30)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.38),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isOpening ? null : onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 6, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ModeIcon(mode: summary.mode, selected: selected),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                summary.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                            if (summary.titleStatus ==
                                ChatTitleStatus.generating) ...[
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.6,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (summary.preview.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            summary.preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.35,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Flexible(
                              child: Wrap(
                                spacing: 7,
                                runSpacing: 5,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _ModeChip(label: modeLabel),
                                  if (summary.generationStatus !=
                                      ChatGenerationStatus.ready)
                                    _StatusLabel(
                                      status: summary.generationStatus,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timestamp,
                              maxLines: 1,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isOpening)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    PopupMenuButton<_HistoryAction>(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).moreButtonTooltip,
                      position: PopupMenuPosition.under,
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onSelected: (action) {
                        if (action == _HistoryAction.delete) onDelete();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _HistoryAction.delete,
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l10n.deleteChat,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
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

class _ModeIcon extends StatelessWidget {
  const _ModeIcon({required this.mode, required this.selected});

  final ChatSessionMode mode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: selected ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        mode == ChatSessionMode.chat
            ? Icons.chat_bubble_outline_rounded
            : Icons.favorite_outline_rounded,
        color: context.primaryColor,
        size: 20,
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: context.primaryColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final ChatGenerationStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final (label, icon, color) = switch (status) {
      ChatGenerationStatus.generating => (
        l10n.aiResponseGenerating,
        Icons.autorenew_rounded,
        context.primaryColor,
      ),
      ChatGenerationStatus.interrupted => (
        l10n.aiResponseInterrupted,
        Icons.pause_circle_outline_rounded,
        theme.brightness == Brightness.dark
            ? Colors.orange.shade400
            : Colors.orange.shade700,
      ),
      ChatGenerationStatus.failed => (
        l10n.aiResponseFailed,
        Icons.error_outline_rounded,
        theme.colorScheme.error,
      ),
      ChatGenerationStatus.ready => (
        '',
        Icons.check_rounded,
        context.primaryColor,
      ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DestructiveConfirmationDialog extends StatelessWidget {
  const _DestructiveConfirmationDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: theme.colorScheme.onErrorContainer),
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 31, color: context.primaryColor),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 10),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatTimestamp(
  BuildContext context,
  DateTime timestamp,
  AppLocalizations l10n,
) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final localTimestamp = timestamp.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(
    localTimestamp.year,
    localTimestamp.month,
    localTimestamp.day,
  );
  final dayDifference = today.difference(date).inDays;

  if (dayDifference == 0) {
    return '${l10n.today} · ${DateFormat.jm(locale).format(localTimestamp)}';
  }
  if (dayDifference > 0 && dayDifference < 7) {
    return DateFormat.E(locale).format(localTimestamp);
  }
  if (localTimestamp.year == now.year) {
    return DateFormat.MMMd(locale).format(localTimestamp);
  }
  return DateFormat.yMMMd(locale).format(localTimestamp);
}
