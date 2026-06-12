part of 'chat_cubit.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  final ChatErrorType? errorType;

  final bool isCounselingMode;
  final CounselingResponse? counselingResponse;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorType,
    this.isCounselingMode = false,
    this.counselingResponse,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    ChatErrorType? errorType,
    bool clearError = false,
    bool? isCounselingMode,
    CounselingResponse? counselingResponse,
    bool clearCounselingResponse = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorType: clearError ? null : (errorType ?? this.errorType),
      isCounselingMode: isCounselingMode ?? this.isCounselingMode,
      counselingResponse: clearCounselingResponse
          ? null
          : (counselingResponse ?? this.counselingResponse),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatState &&
        _listEquals(other.messages, messages) &&
        other.isLoading == isLoading &&
        other.errorType == errorType &&
        other.isCounselingMode == isCounselingMode &&
        other.counselingResponse == counselingResponse;
  }

  @override
  int get hashCode =>
      _listHashCode(messages) ^
      isLoading.hashCode ^
      errorType.hashCode ^
      isCounselingMode.hashCode ^
      counselingResponse.hashCode;

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  int _listHashCode<T>(List<T> list) {
    int hash = 0;
    for (T item in list) {
      hash ^= item.hashCode;
    }
    return hash;
  }
}
