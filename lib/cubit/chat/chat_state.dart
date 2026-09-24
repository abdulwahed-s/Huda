part of 'chat_cubit.dart';

class ChatState {
  const ChatState({
    this.summaries = const [],
    this.activeSession,
    this.selectedMode = ChatSessionMode.chat,
    this.activeRequestSessionId,
    this.isHydrating = true,
    this.storageWarning = false,
  });

  final List<ChatSessionSummary> summaries;
  final ChatSession? activeSession;
  final ChatSessionMode selectedMode;
  final String? activeRequestSessionId;
  final bool isHydrating;
  final bool storageWarning;

  List<ChatMessage> get messages => activeSession?.messages ?? const [];

  bool get isLoading =>
      activeSession?.generationStatus == ChatGenerationStatus.generating;

  bool get hasActiveRequest => activeRequestSessionId != null;

  ChatErrorType? get errorType => activeSession?.errorType;

  bool get isCounselingMode => selectedMode == ChatSessionMode.counseling;

  CounselingResponse? get counselingResponse =>
      activeSession?.counselingResponse;

  ChatState copyWith({
    List<ChatSessionSummary>? summaries,
    ChatSession? activeSession,
    bool clearActiveSession = false,
    ChatSessionMode? selectedMode,
    String? activeRequestSessionId,
    bool clearActiveRequest = false,
    bool? isHydrating,
    bool? storageWarning,
  }) {
    return ChatState(
      summaries: summaries ?? this.summaries,
      activeSession: clearActiveSession
          ? null
          : (activeSession ?? this.activeSession),
      selectedMode: selectedMode ?? this.selectedMode,
      activeRequestSessionId: clearActiveRequest
          ? null
          : (activeRequestSessionId ?? this.activeRequestSessionId),
      isHydrating: isHydrating ?? this.isHydrating,
      storageWarning: storageWarning ?? this.storageWarning,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatState &&
        _listEquals(other.summaries, summaries) &&
        other.activeSession == activeSession &&
        other.selectedMode == selectedMode &&
        other.activeRequestSessionId == activeRequestSessionId &&
        other.isHydrating == isHydrating &&
        other.storageWarning == storageWarning;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(summaries),
    activeSession,
    selectedMode,
    activeRequestSessionId,
    isHydrating,
    storageWarning,
  );

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
