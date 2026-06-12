import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/gemini_service.dart';
import 'package:huda/data/models/chat_error.dart';
import 'package:huda/data/models/chat_message_model.dart';
import 'package:huda/data/models/counseling_response_model.dart';
part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final GeminiService _geminiService;

  String? _lastFeeling;

  ChatCubit(this._geminiService) : super(const ChatState());

  void sendMessage(String userInput) {
    final userMessage = ChatMessage(text: userInput, sender: Sender.user);
    emit(state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      clearError: true,
    ));
    _streamResponse(userInput);
  }

  void retryLastMessage() {
    final lastUserInput = _lastUserInput();
    if (lastUserInput == null) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    _streamResponse(lastUserInput);
  }

  String? _lastUserInput() {
    for (final message in state.messages.reversed) {
      if (message.sender == Sender.user) return message.text;
    }
    return null;
  }

  Future<void> _streamResponse(String userInput) async {
    final history = List<ChatMessage>.from(state.messages);
    if (history.isNotEmpty) history.removeLast();

    bool botMessageAdded = false;
    try {
      String accumulatedResponse = '';

      await for (final chunk
          in _geminiService.sendMessageStream(userInput, history)) {
        accumulatedResponse += chunk;
        final botMessage =
            ChatMessage(text: accumulatedResponse, sender: Sender.model);

        if (!botMessageAdded) {
          botMessageAdded = true;
          emit(state.copyWith(
            messages: [...state.messages, botMessage],
            isLoading: true,
          ));
        } else {
          final updatedMessages = List<ChatMessage>.from(state.messages);
          updatedMessages[updatedMessages.length - 1] = botMessage;
          emit(state.copyWith(messages: updatedMessages, isLoading: true));
        }
      }

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      var messages = state.messages;
      if (botMessageAdded &&
          messages.isNotEmpty &&
          messages.last.sender == Sender.model) {
        messages = messages.sublist(0, messages.length - 1);
      }
      emit(state.copyWith(
        messages: messages,
        isLoading: false,
        errorType: _errorTypeOf(e),
      ));
    }
  }

  void clearHistory() {
    emit(const ChatState());
  }

  void toggleMode() {
    emit(state.copyWith(
      isCounselingMode: !state.isCounselingMode,
      clearError: true,
    ));
  }

  void sendCounselingRequest(String userFeeling) async {
    _lastFeeling = userFeeling;
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      clearCounselingResponse: true,
    ));

    try {
      final response = await _geminiService.sendCounselingMessage(userFeeling);
      if (response != null) {
        emit(state.copyWith(
          counselingResponse: response,
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorType: ChatErrorType.server,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorType: _errorTypeOf(e),
      ));
    }
  }

  void retryCounselingRequest() {
    final feeling = _lastFeeling;
    if (feeling != null) sendCounselingRequest(feeling);
  }

  ChatErrorType _errorTypeOf(Object error) =>
      error is ChatException ? error.type : ChatErrorType.unknown;
}
