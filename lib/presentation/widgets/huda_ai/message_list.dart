import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/chat/chat_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/huda_ai/empty_state_widget.dart';
import 'package:huda/presentation/widgets/huda_ai/message_bubble.dart';
import 'package:huda/data/models/chat_message_model.dart';

class MessageList extends StatelessWidget {
  final ScrollController scrollController;
  final TextEditingController textEditingController;
  final Map<String, GlobalKey> messageKeys;
  final bool isDark;
  final bool isRTL;
  final AppLocalizations appLocalizations;
  final Function(String) onCopy;
  final Function(String) onShare;
  final bool isGeneratingImage;

  const MessageList({
    super.key,
    required this.scrollController,
    required this.textEditingController,
    required this.messageKeys,
    required this.isDark,
    required this.isRTL,
    required this.appLocalizations,
    required this.onCopy,
    required this.onShare,
    required this.isGeneratingImage,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatState>(
      listener: (context, state) {
        if (state.messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scrollController.hasClients) {
              scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      },
      builder: (context, state) {
        if (state.messages.isEmpty) {
          return EmptyStateWidget(
            isDark: isDark,
            appLocalizations: appLocalizations,
            controller:
                textEditingController, // Pass textEditingController instead
            chatCubit: context.read<ChatCubit>(),
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: state.messages.length,
          itemBuilder: (context, index) {
            final message = state.messages[index];
            return RepaintBoundary(
              key: message.sender == Sender.user
                  ? (messageKeys[message.text] ??= GlobalKey())
                  : null,
              child: MessageBubble(
                message: message,
                isDark: isDark,
                isRTL: isRTL,
                appLocalizations: appLocalizations,
                onCopy: () => onCopy(message.text),
                onShare: () => onShare(message.text),
                isGeneratingImage: isGeneratingImage,
              ),
            );
          },
        );
      },
    );
  }
}
