import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/gemini_service.dart';
import 'package:huda/data/models/chat_message_model.dart';
import 'package:huda/data/models/counseling_response_model.dart';
part 'chat_state.dart';

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

  void toggleMode() {
    emit(state.copyWith(isCounselingMode: !state.isCounselingMode));
  }

  void sendCounselingRequest(String userFeeling) async {
    emit(state.copyWith(isLoading: true));

    try {
      final response = await _geminiService.sendCounselingMessage(userFeeling);
      if (response != null) {
        emit(state.copyWith(
          counselingResponse: response,
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(
          error: 'Failed to generate counseling response. Please try again.',
          isLoading: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        error: 'An error occurred: $e',
        isLoading: false,
      ));
    }
  }
}
