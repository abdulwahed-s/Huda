import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/gemini_service.dart';
import 'package:huda/data/models/chat_error.dart';
import 'package:huda/data/models/chat_message_model.dart';
import 'package:huda/data/models/chat_session_model.dart';
import 'package:huda/data/models/counseling_response_model.dart';
import 'package:huda/data/repository/chat_history_repository.dart';
import 'package:uuid/uuid.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._aiClient, this._historyRepository, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid(),
      super(const ChatState());

  final HudaAiClient _aiClient;
  final ChatHistoryRepository _historyRepository;
  final Uuid _uuid;

  final Map<String, ChatSession> _sessionCache = {};
  final Map<ChatSessionMode, String?> _lastSessionIds = {};
  final Map<String, Timer> _persistTimers = {};
  final Map<String, CancelToken> _titleCancelTokens = {};
  final Set<String> _deletedSessionIds = {};
  final Set<String> _titleRetriedThisRun = {};

  Future<void> _writeQueue = Future<void>.value();
  CancelToken? _answerCancelToken;
  bool _isClosed = false;

  Future<void> initialize() async {
    try {
      if (!_historyRepository.isAvailable) {
        await _historyRepository.initialize();
      }
      if (!_historyRepository.isAvailable) {
        emit(state.copyWith(isHydrating: false, storageWarning: true));
        return;
      }

      var summaries = await _historyRepository.loadSummaries();
      summaries = await _recoverInterruptedSessions(summaries);

      for (final mode in ChatSessionMode.values) {
        _lastSessionIds[mode] = await _historyRepository
            .loadLastActiveSessionId(mode);
      }

      ChatSession? activeSession;
      var selectedMode =
          await _historyRepository.loadLastSelectedMode() ??
          (summaries.isEmpty ? ChatSessionMode.chat : summaries.first.mode);
      if (summaries.isNotEmpty) {
        final selectedId = _lastSessionIds[selectedMode];
        ChatSessionSummary? fallback;
        for (final summary in summaries) {
          if (summary.mode == selectedMode) {
            fallback = summary;
            break;
          }
        }
        activeSession = await _historyRepository.loadSession(
          selectedId ?? fallback?.id ?? summaries.first.id,
        );
        if (activeSession != null) {
          _sessionCache[activeSession.id] = activeSession;
          _lastSessionIds[activeSession.mode] = activeSession.id;
        }
      }

      emit(
        ChatState(
          summaries: summaries,
          activeSession: activeSession,
          selectedMode: selectedMode,
          isHydrating: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isHydrating: false, storageWarning: true));
    }
  }

  Future<List<ChatSessionSummary>> _recoverInterruptedSessions(
    List<ChatSessionSummary> summaries,
  ) async {
    final recovered = <ChatSessionSummary>[];
    for (final summary in summaries) {
      final needsAnswerRecovery =
          summary.generationStatus == ChatGenerationStatus.generating;
      final needsTitleRecovery =
          summary.titleStatus == ChatTitleStatus.generating;
      if (!needsAnswerRecovery && !needsTitleRecovery) {
        recovered.add(summary);
        continue;
      }

      final stored = await _historyRepository.loadSession(summary.id);
      if (stored == null) continue;
      final updated = stored.copyWith(
        generationStatus: needsAnswerRecovery
            ? ChatGenerationStatus.interrupted
            : stored.generationStatus,
        errorType: needsAnswerRecovery
            ? ChatErrorType.interrupted
            : stored.errorType,
        titleStatus: needsTitleRecovery
            ? ChatTitleStatus.failed
            : stored.titleStatus,
        updatedAt: DateTime.now().toUtc(),
      );
      _sessionCache[updated.id] = updated;
      await _historyRepository.saveSession(updated);
      recovered.add(ChatSessionSummary.fromSession(updated));
    }
    recovered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return recovered;
  }

  void onScreenOpened() {
    final session = state.activeSession;
    if (session != null) _retryTitleIfNeeded(session);
  }

  Future<void> sendMessage(String userInput) async {
    final input = userInput.trim();
    if (input.isEmpty || state.hasActiveRequest) return;

    final now = DateTime.now().toUtc();
    var session = state.activeSession;
    final isFirstMessage = session == null || session.messages.isEmpty;
    final previousMessages = session?.messages ?? const <ChatMessage>[];
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      text: input,
      sender: Sender.user,
      createdAt: now,
    );

    if (session == null || session.mode != ChatSessionMode.chat) {
      session = ChatSession(
        id: _uuid.v4(),
        mode: ChatSessionMode.chat,
        title: _temporaryTitle(input),
        titleStatus: ChatTitleStatus.generating,
        createdAt: now,
        updatedAt: now,
        messages: [userMessage],
        generationStatus: ChatGenerationStatus.generating,
      );
    } else {
      session = session.copyWith(
        messages: [...session.messages, userMessage],
        generationStatus: ChatGenerationStatus.generating,
        updatedAt: now,
        clearError: true,
      );
    }

    _setActiveSession(session, activeRequestSessionId: session.id);
    await _rememberAndPersist(session);

    if (isFirstMessage) {
      _startTitleGeneration(session.id, input);
    }

    final history = previousMessages
        .where((message) => message.isComplete)
        .toList(growable: false);
    _startChatResponse(session.id, input, history);
  }

  void _startChatResponse(
    String sessionId,
    String userInput,
    List<ChatMessage> history,
  ) {
    final cancelToken = CancelToken();
    _answerCancelToken = cancelToken;
    unawaited(_streamResponse(sessionId, userInput, history, cancelToken));
  }

  Future<void> _streamResponse(
    String sessionId,
    String userInput,
    List<ChatMessage> history,
    CancelToken cancelToken,
  ) async {
    final responseMessageId = _uuid.v4();
    var accumulatedResponse = '';
    var botMessageAdded = false;
    try {
      await for (final chunk in _aiClient.sendMessageStream(
        userInput,
        history,
        cancelToken: cancelToken,
      )) {
        if (_deletedSessionIds.contains(sessionId)) return;
        accumulatedResponse += chunk;
        final current = _sessionCache[sessionId];
        if (current == null) return;
        final botMessage = ChatMessage(
          id: responseMessageId,
          text: accumulatedResponse,
          sender: Sender.model,
          createdAt: DateTime.now().toUtc(),
          isComplete: false,
        );
        final messages = [...current.messages];
        if (!botMessageAdded) {
          messages.add(botMessage);
          botMessageAdded = true;
        } else {
          final index = messages.indexWhere(
            (message) => message.id == responseMessageId,
          );
          if (index >= 0) messages[index] = botMessage;
        }
        _commitSession(
          current.copyWith(
            messages: messages,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
        _schedulePersist(sessionId);
      }

      if (accumulatedResponse.isEmpty) {
        throw const ChatException(ChatErrorType.server);
      }
      final current = _sessionCache[sessionId];
      if (current == null || _deletedSessionIds.contains(sessionId)) return;
      final completedMessages = current.messages
          .map(
            (message) => message.id == responseMessageId
                ? message.copyWith(isComplete: true)
                : message,
          )
          .toList(growable: false);
      _commitSession(
        current.copyWith(
          messages: completedMessages,
          generationStatus: ChatGenerationStatus.ready,
          updatedAt: DateTime.now().toUtc(),
          clearError: true,
        ),
      );
      await _persistNow(sessionId);
      _finishAnswerRequest(sessionId);
    } catch (error) {
      if (_deletedSessionIds.contains(sessionId)) return;
      final current = _sessionCache[sessionId];
      if (current == null) return;
      _commitSession(
        current.copyWith(
          generationStatus: ChatGenerationStatus.failed,
          errorType: _errorTypeOf(error),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      await _persistNow(sessionId);
      _finishAnswerRequest(sessionId);
    }
  }

  Future<void> retryLastMessage() async {
    final session = state.activeSession;
    if (session == null ||
        session.mode != ChatSessionMode.chat ||
        state.hasActiveRequest) {
      return;
    }

    final cleanedMessages = session.messages
        .where((message) => message.isComplete)
        .toList(growable: false);
    var lastUserIndex = -1;
    for (var index = cleanedMessages.length - 1; index >= 0; index--) {
      if (cleanedMessages[index].sender == Sender.user) {
        lastUserIndex = index;
        break;
      }
    }
    if (lastUserIndex < 0) return;

    final updated = session.copyWith(
      messages: cleanedMessages,
      generationStatus: ChatGenerationStatus.generating,
      updatedAt: DateTime.now().toUtc(),
      clearError: true,
    );
    _setActiveSession(updated, activeRequestSessionId: updated.id);
    await _persistNow(updated.id);
    _startChatResponse(
      updated.id,
      cleanedMessages[lastUserIndex].text,
      cleanedMessages.sublist(0, lastUserIndex),
    );
  }

  Future<void> sendCounselingRequest(String userFeeling) async {
    final feeling = userFeeling.trim();
    if (feeling.isEmpty || state.hasActiveRequest) return;

    final now = DateTime.now().toUtc();
    final session = ChatSession(
      id: _uuid.v4(),
      mode: ChatSessionMode.counseling,
      title: _temporaryTitle(feeling),
      titleStatus: ChatTitleStatus.generating,
      createdAt: now,
      updatedAt: now,
      counselingRequest: feeling,
      generationStatus: ChatGenerationStatus.generating,
    );
    _setActiveSession(session, activeRequestSessionId: session.id);
    await _rememberAndPersist(session);
    _startTitleGeneration(session.id, feeling);
    _startCounselingResponse(session.id, feeling);
  }

  void _startCounselingResponse(String sessionId, String feeling) {
    final cancelToken = CancelToken();
    _answerCancelToken = cancelToken;
    unawaited(_requestCounseling(sessionId, feeling, cancelToken));
  }

  Future<void> _requestCounseling(
    String sessionId,
    String feeling,
    CancelToken cancelToken,
  ) async {
    try {
      final response = await _aiClient.sendCounselingMessage(
        feeling,
        cancelToken: cancelToken,
      );
      final current = _sessionCache[sessionId];
      if (current == null || _deletedSessionIds.contains(sessionId)) return;
      _commitSession(
        current.copyWith(
          counselingResponse: response,
          generationStatus: ChatGenerationStatus.ready,
          updatedAt: DateTime.now().toUtc(),
          clearError: true,
        ),
      );
      await _persistNow(sessionId);
      _finishAnswerRequest(sessionId);
    } catch (error) {
      if (_deletedSessionIds.contains(sessionId)) return;
      final current = _sessionCache[sessionId];
      if (current == null) return;
      _commitSession(
        current.copyWith(
          generationStatus: ChatGenerationStatus.failed,
          errorType: _errorTypeOf(error),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      await _persistNow(sessionId);
      _finishAnswerRequest(sessionId);
    }
  }

  Future<void> retryCounselingRequest() async {
    final session = state.activeSession;
    final feeling = session?.counselingRequest;
    if (session == null ||
        session.mode != ChatSessionMode.counseling ||
        feeling == null ||
        state.hasActiveRequest) {
      return;
    }
    final updated = session.copyWith(
      generationStatus: ChatGenerationStatus.generating,
      updatedAt: DateTime.now().toUtc(),
      clearCounselingResponse: true,
      clearError: true,
    );
    _setActiveSession(updated, activeRequestSessionId: updated.id);
    await _persistNow(updated.id);
    _startCounselingResponse(updated.id, feeling);
  }

  void _startTitleGeneration(String sessionId, String firstUserText) {
    final current = _sessionCache[sessionId];
    if (current == null || current.titleStatus == ChatTitleStatus.generated) {
      return;
    }
    final cancelToken = CancelToken();
    _titleCancelTokens[sessionId]?.cancel();
    _titleCancelTokens[sessionId] = cancelToken;
    if (current.titleStatus != ChatTitleStatus.generating) {
      _commitSession(current.copyWith(titleStatus: ChatTitleStatus.generating));
    }
    unawaited(_generateTitle(sessionId, firstUserText, cancelToken));
  }

  Future<void> _generateTitle(
    String sessionId,
    String firstUserText,
    CancelToken cancelToken,
  ) async {
    try {
      final title = await _aiClient.generateSessionTitle(
        firstUserText,
        cancelToken: cancelToken,
      );
      final current = _sessionCache[sessionId];
      if (current == null || _deletedSessionIds.contains(sessionId)) return;
      _commitSession(
        current.copyWith(title: title, titleStatus: ChatTitleStatus.generated),
      );
      await _persistNow(sessionId);
    } catch (_) {
      if (_deletedSessionIds.contains(sessionId) || cancelToken.isCancelled) {
        return;
      }
      final current = _sessionCache[sessionId];
      if (current == null) return;
      _commitSession(current.copyWith(titleStatus: ChatTitleStatus.failed));
      await _persistNow(sessionId);
    } finally {
      if (identical(_titleCancelTokens[sessionId], cancelToken)) {
        _titleCancelTokens.remove(sessionId);
      }
    }
  }

  void _retryTitleIfNeeded(ChatSession session) {
    if (session.titleStatus != ChatTitleStatus.failed ||
        _titleRetriedThisRun.contains(session.id) ||
        session.preview.isEmpty) {
      return;
    }
    _titleRetriedThisRun.add(session.id);
    _startTitleGeneration(session.id, session.preview);
  }

  Future<void> switchMode() async {
    final target = state.isCounselingMode
        ? ChatSessionMode.chat
        : ChatSessionMode.counseling;
    final sessionId = _lastSessionIds[target];
    final session = sessionId == null ? null : await _sessionForId(sessionId);
    emit(
      state.copyWith(
        selectedMode: target,
        activeSession: session,
        clearActiveSession: session == null,
      ),
    );
    await _saveSelectedMode(target);
    if (session != null) _retryTitleIfNeeded(session);
  }

  void toggleMode() {
    unawaited(switchMode());
  }

  Future<void> selectSession(String id) async {
    final session = await _sessionForId(id);
    if (session == null) return;
    _lastSessionIds[session.mode] = session.id;
    emit(state.copyWith(activeSession: session, selectedMode: session.mode));
    await Future.wait([
      _saveLastActive(session.mode, session.id),
      _saveSelectedMode(session.mode),
    ]);
    _retryTitleIfNeeded(session);
  }

  Future<void> startNewSession() async {
    final mode = state.selectedMode;
    _lastSessionIds[mode] = null;
    emit(state.copyWith(clearActiveSession: true));
    await Future.wait([_saveLastActive(mode, null), _saveSelectedMode(mode)]);
  }

  Future<void> deleteSession(String id) async {
    _deletedSessionIds.add(id);
    _persistTimers.remove(id)?.cancel();
    if (state.activeRequestSessionId == id) {
      _answerCancelToken?.cancel('Session deleted');
      _answerCancelToken = null;
    }
    _titleCancelTokens.remove(id)?.cancel('Session deleted');
    _sessionCache.remove(id);

    for (final mode in ChatSessionMode.values) {
      if (_lastSessionIds[mode] == id) {
        _lastSessionIds[mode] = null;
        await _saveLastActive(mode, null);
      }
    }

    final deletingActive = state.activeSession?.id == id;
    emit(
      state.copyWith(
        summaries: state.summaries
            .where((summary) => summary.id != id)
            .toList(growable: false),
        clearActiveSession: deletingActive,
        clearActiveRequest: state.activeRequestSessionId == id,
      ),
    );

    _writeQueue = _writeQueue.then((_) => _historyRepository.deleteSession(id));
    try {
      await _writeQueue;
    } catch (_) {
      _showStorageWarning();
    }
  }

  Future<void> clearHistory() async {
    _answerCancelToken?.cancel('History cleared');
    _answerCancelToken = null;
    for (final token in _titleCancelTokens.values) {
      token.cancel('History cleared');
    }
    _titleCancelTokens.clear();
    for (final timer in _persistTimers.values) {
      timer.cancel();
    }
    _persistTimers.clear();
    _deletedSessionIds.addAll(state.summaries.map((summary) => summary.id));
    _sessionCache.clear();
    _lastSessionIds.clear();
    emit(
      ChatState(
        selectedMode: state.selectedMode,
        isHydrating: false,
        storageWarning: state.storageWarning,
      ),
    );

    _writeQueue = _writeQueue.then((_) => _historyRepository.clearAll());
    try {
      await _writeQueue;
    } catch (_) {
      _showStorageWarning();
    }
  }

  Future<void> _rememberAndPersist(ChatSession session) async {
    _lastSessionIds[session.mode] = session.id;
    await Future.wait([
      _persistNow(session.id),
      _saveLastActive(session.mode, session.id),
      _saveSelectedMode(session.mode),
    ]);
  }

  Future<void> _saveLastActive(ChatSessionMode mode, String? sessionId) async {
    try {
      await _historyRepository.saveLastActiveSessionId(mode, sessionId);
    } catch (_) {
      _showStorageWarning();
    }
  }

  Future<void> _saveSelectedMode(ChatSessionMode mode) async {
    try {
      await _historyRepository.saveLastSelectedMode(mode);
    } catch (_) {
      _showStorageWarning();
    }
  }

  Future<ChatSession?> _sessionForId(String id) async {
    final cached = _sessionCache[id];
    if (cached != null) return cached;
    if (_deletedSessionIds.contains(id)) return null;
    try {
      final session = await _historyRepository.loadSession(id);
      if (session != null) _sessionCache[id] = session;
      return session;
    } catch (_) {
      _showStorageWarning();
      return null;
    }
  }

  void _setActiveSession(
    ChatSession session, {
    String? activeRequestSessionId,
  }) {
    _sessionCache[session.id] = session;
    emit(
      state.copyWith(
        activeSession: session,
        selectedMode: session.mode,
        activeRequestSessionId: activeRequestSessionId,
        summaries: _summariesWith(session),
      ),
    );
  }

  void _commitSession(ChatSession session) {
    if (_deletedSessionIds.contains(session.id)) return;
    _sessionCache[session.id] = session;
    emit(
      state.copyWith(
        activeSession: state.activeSession?.id == session.id
            ? session
            : state.activeSession,
        summaries: _summariesWith(session),
      ),
    );
  }

  List<ChatSessionSummary> _summariesWith(ChatSession session) {
    final summaries =
        state.summaries
            .where((summary) => summary.id != session.id)
            .toList(growable: true)
          ..add(ChatSessionSummary.fromSession(session))
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(summaries);
  }

  void _schedulePersist(String sessionId) {
    _persistTimers.remove(sessionId)?.cancel();
    _persistTimers[sessionId] = Timer(const Duration(milliseconds: 500), () {
      _persistTimers.remove(sessionId);
      unawaited(_persistNow(sessionId));
    });
  }

  Future<void> _persistNow(String sessionId) {
    _persistTimers.remove(sessionId)?.cancel();
    _writeQueue = _writeQueue
        .then((_) async {
          if (_deletedSessionIds.contains(sessionId)) return;
          final session = _sessionCache[sessionId];
          if (session != null) await _historyRepository.saveSession(session);
        })
        .catchError((Object _) {
          _showStorageWarning();
        });
    return _writeQueue;
  }

  void _finishAnswerRequest(String sessionId) {
    if (state.activeRequestSessionId != sessionId) return;
    _answerCancelToken = null;
    emit(state.copyWith(clearActiveRequest: true));
  }

  String _temporaryTitle(String input) {
    var title = input.trim().split(RegExp(r'[\r\n]+')).first.trim();
    if (title.runes.length > 60) {
      title = '${String.fromCharCodes(title.runes.take(57)).trimRight()}…';
    }
    return title;
  }

  ChatErrorType _errorTypeOf(Object error) =>
      error is ChatException ? error.type : ChatErrorType.unknown;

  void dismissStorageWarning() {
    emit(state.copyWith(storageWarning: false));
  }

  void _showStorageWarning() {
    if (!_isClosed && !state.storageWarning) {
      emit(state.copyWith(storageWarning: true));
    }
  }

  @override
  Future<void> close() async {
    _isClosed = true;
    _answerCancelToken?.cancel('Chat manager closed');
    for (final token in _titleCancelTokens.values) {
      token.cancel('Chat manager closed');
    }
    final pendingSessionIds = _persistTimers.keys.toList(growable: false);
    for (final timer in _persistTimers.values) {
      timer.cancel();
    }
    _persistTimers.clear();
    for (final sessionId in pendingSessionIds) {
      await _persistNow(sessionId);
    }
    await _writeQueue;
    return super.close();
  }
}
