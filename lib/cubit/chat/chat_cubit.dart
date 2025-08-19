import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/gemini_service.dart';
import 'package:huda/data/api/chat_message_model.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final GeminiService _geminiService;

  ChatCubit(this._geminiService) : super(const ChatState());

  void sendMessage(String userInput) async {
    try {
      final userMessage = ChatMessage(text: userInput, sender: Sender.user);

      emit(state.copyWith(
        messages: [...state.messages, userMessage],
        isLoading: true,
      ));

      final conversationHistory = List<ChatMessage>.from(state.messages);
      conversationHistory.removeLast();

      String accumulatedResponse = '';
      ChatMessage? currentBotMessage;

      await for (final chunk
          in _geminiService.sendMessageStream(userInput, conversationHistory)) {
        accumulatedResponse += chunk;

        if (currentBotMessage == null) {
          currentBotMessage =
              ChatMessage(text: accumulatedResponse, sender: Sender.model);
          emit(state.copyWith(
            messages: [...state.messages, currentBotMessage],
            isLoading: true,
          ));
        } else {
          final updatedMessages = List<ChatMessage>.from(state.messages);
          updatedMessages[updatedMessages.length - 1] =
              ChatMessage(text: accumulatedResponse, sender: Sender.model);
          emit(state.copyWith(
            messages: updatedMessages,
            isLoading: true,
          ));
        }
      }

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      const errorMessage = ChatMessage(
          text: 'Sorry, I encountered an error. Please try again.',
          sender: Sender.model);
      emit(state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      ));
    }
  }

  void clearHistory() {
    emit(const ChatState());
  }
}
