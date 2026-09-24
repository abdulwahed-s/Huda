import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:huda/data/models/chat_session_model.dart';

abstract interface class ChatHistoryRepository {
  bool get isAvailable;

  Future<void> initialize();

  Future<List<ChatSessionSummary>> loadSummaries();

  Future<ChatSession?> loadSession(String id);

  Future<void> saveSession(ChatSession session);

  Future<void> deleteSession(String id);

  Future<void> clearAll();

  Future<String?> loadLastActiveSessionId(ChatSessionMode mode);

  Future<void> saveLastActiveSessionId(ChatSessionMode mode, String? sessionId);

  Future<ChatSessionMode?> loadLastSelectedMode();

  Future<void> saveLastSelectedMode(ChatSessionMode mode);
}

class ChatHistoryStorageException implements Exception {
  const ChatHistoryStorageException([this.cause]);

  final Object? cause;

  @override
  String toString() => 'ChatHistoryStorageException($cause)';
}

class HiveChatHistoryRepository implements ChatHistoryRepository {
  HiveChatHistoryRepository({String? storagePath}) : _storagePath = storagePath;

  static const _indexBoxName = 'huda_ai_history_index_v1';
  static const _sessionBoxName = 'huda_ai_history_sessions_v1';
  static const _sessionKeyPrefix = 'session:';
  static const _activeKeyPrefix = 'active:';
  static const _selectedModeKey = 'selectedMode';

  final String? _storagePath;

  Box<dynamic>? _indexBox;
  LazyBox<dynamic>? _sessionBox;

  @override
  bool get isAvailable => _indexBox != null && _sessionBox != null;

  @override
  Future<void> initialize() async {
    if (isAvailable) return;
    try {
      final storagePath = _storagePath;
      if (storagePath == null) {
        await Hive.initFlutter();
      } else {
        Hive.init(storagePath);
      }
      _indexBox = await Hive.openBox<dynamic>(_indexBoxName);
      _sessionBox = await Hive.openLazyBox<dynamic>(_sessionBoxName);
    } catch (error, stackTrace) {
      debugPrint('Failed to initialize Huda AI history: $error');
      debugPrintStack(stackTrace: stackTrace);
      _indexBox = null;
      _sessionBox = null;
    }
  }

  @override
  Future<List<ChatSessionSummary>> loadSummaries() async {
    final index = _requireIndexBox();
    final summaries = <ChatSessionSummary>[];
    for (final key in index.keys) {
      if (key is! String || !key.startsWith(_sessionKeyPrefix)) continue;
      final value = index.get(key);
      if (value is! Map) continue;
      try {
        summaries.add(
          ChatSessionSummary.fromJson(Map<String, dynamic>.from(value)),
        );
      } catch (error) {
        debugPrint('Ignoring invalid Huda AI history summary: $error');
      }
    }
    summaries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return summaries;
  }

  @override
  Future<ChatSession?> loadSession(String id) async {
    final value = await _requireSessionBox().get(id);
    if (value == null) return null;
    if (value is! Map) return null;
    try {
      return ChatSession.fromJson(Map<String, dynamic>.from(value));
    } catch (error) {
      debugPrint('Ignoring invalid Huda AI history session $id: $error');
      return null;
    }
  }

  @override
  Future<void> saveSession(ChatSession session) async {
    try {
      await _requireSessionBox().put(session.id, session.toJson());
      await _requireIndexBox().put(
        '$_sessionKeyPrefix${session.id}',
        ChatSessionSummary.fromSession(session).toJson(),
      );
    } catch (error) {
      throw ChatHistoryStorageException(error);
    }
  }

  @override
  Future<void> deleteSession(String id) async {
    try {
      await _requireSessionBox().delete(id);
      await _requireIndexBox().delete('$_sessionKeyPrefix$id');
    } catch (error) {
      throw ChatHistoryStorageException(error);
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _requireSessionBox().clear();
      await _requireIndexBox().clear();
    } catch (error) {
      throw ChatHistoryStorageException(error);
    }
  }

  @override
  Future<String?> loadLastActiveSessionId(ChatSessionMode mode) async {
    final value = _requireIndexBox().get('$_activeKeyPrefix${mode.name}');
    return value is String ? value : null;
  }

  @override
  Future<void> saveLastActiveSessionId(
    ChatSessionMode mode,
    String? sessionId,
  ) async {
    final key = '$_activeKeyPrefix${mode.name}';
    try {
      if (sessionId == null) {
        await _requireIndexBox().delete(key);
      } else {
        await _requireIndexBox().put(key, sessionId);
      }
    } catch (error) {
      throw ChatHistoryStorageException(error);
    }
  }

  @override
  Future<ChatSessionMode?> loadLastSelectedMode() async {
    final value = _requireIndexBox().get(_selectedModeKey);
    if (value is! String) return null;
    try {
      return ChatSessionMode.values.byName(value);
    } on ArgumentError {
      return null;
    }
  }

  @override
  Future<void> saveLastSelectedMode(ChatSessionMode mode) async {
    try {
      await _requireIndexBox().put(_selectedModeKey, mode.name);
    } catch (error) {
      throw ChatHistoryStorageException(error);
    }
  }

  Box<dynamic> _requireIndexBox() {
    final box = _indexBox;
    if (box == null) throw const ChatHistoryStorageException();
    return box;
  }

  LazyBox<dynamic> _requireSessionBox() {
    final box = _sessionBox;
    if (box == null) throw const ChatHistoryStorageException();
    return box;
  }
}
