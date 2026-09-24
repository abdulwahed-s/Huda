import 'package:huda/data/models/chat_error.dart';
import 'package:huda/data/models/chat_message_model.dart';
import 'package:huda/data/models/counseling_response_model.dart';

enum ChatSessionMode { chat, counseling }

enum ChatGenerationStatus { ready, generating, failed, interrupted }

enum ChatTitleStatus { temporary, generating, generated, failed }

class ChatSession {
  static const int schemaVersion = 1;

  const ChatSession({
    required this.id,
    required this.mode,
    required this.title,
    required this.titleStatus,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
    this.counselingRequest,
    this.counselingResponse,
    this.generationStatus = ChatGenerationStatus.ready,
    this.errorType,
  });

  final String id;
  final ChatSessionMode mode;
  final String title;
  final ChatTitleStatus titleStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
  final String? counselingRequest;
  final CounselingResponse? counselingResponse;
  final ChatGenerationStatus generationStatus;
  final ChatErrorType? errorType;

  String get preview {
    if (mode == ChatSessionMode.counseling) {
      return counselingRequest ?? '';
    }
    for (final message in messages) {
      if (message.sender == Sender.user && message.text.trim().isNotEmpty) {
        return message.text.trim();
      }
    }
    return '';
  }

  ChatSession copyWith({
    String? title,
    ChatTitleStatus? titleStatus,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
    String? counselingRequest,
    CounselingResponse? counselingResponse,
    bool clearCounselingResponse = false,
    ChatGenerationStatus? generationStatus,
    ChatErrorType? errorType,
    bool clearError = false,
  }) {
    return ChatSession(
      id: id,
      mode: mode,
      title: title ?? this.title,
      titleStatus: titleStatus ?? this.titleStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      counselingRequest: counselingRequest ?? this.counselingRequest,
      counselingResponse: clearCounselingResponse
          ? null
          : (counselingResponse ?? this.counselingResponse),
      generationStatus: generationStatus ?? this.generationStatus,
      errorType: clearError ? null : (errorType ?? this.errorType),
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'mode': mode.name,
    'title': title,
    'titleStatus': titleStatus.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'messages': messages.map((message) => message.toJson()).toList(),
    'counselingRequest': counselingRequest,
    'counselingResponse': counselingResponse?.toJson(),
    'generationStatus': generationStatus.name,
    'errorType': errorType?.name,
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'] as int? ?? 1;
    if (version != schemaVersion) {
      throw FormatException('Unsupported chat session schema: $version');
    }

    final rawMessages = json['messages'] as List<dynamic>? ?? const [];
    final rawResponse = json['counselingResponse'];
    return ChatSession(
      id: json['id'] as String,
      mode: ChatSessionMode.values.byName(json['mode'] as String),
      title: json['title'] as String,
      titleStatus: ChatTitleStatus.values.byName(
        json['titleStatus'] as String? ?? ChatTitleStatus.temporary.name,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
      messages: rawMessages
          .map(
            (message) =>
                ChatMessage.fromJson(Map<String, dynamic>.from(message as Map)),
          )
          .toList(growable: false),
      counselingRequest: json['counselingRequest'] as String?,
      counselingResponse: rawResponse is Map
          ? CounselingResponse.fromJson(Map<String, dynamic>.from(rawResponse))
          : null,
      generationStatus: ChatGenerationStatus.values.byName(
        json['generationStatus'] as String? ?? ChatGenerationStatus.ready.name,
      ),
      errorType: _errorTypeFromJson(json['errorType']),
    );
  }

  static ChatErrorType? _errorTypeFromJson(Object? value) {
    if (value is! String) return null;
    try {
      return ChatErrorType.values.byName(value);
    } on ArgumentError {
      return ChatErrorType.unknown;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatSession &&
        other.id == id &&
        other.mode == mode &&
        other.title == title &&
        other.titleStatus == titleStatus &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        _listEquals(other.messages, messages) &&
        other.counselingRequest == counselingRequest &&
        other.counselingResponse == counselingResponse &&
        other.generationStatus == generationStatus &&
        other.errorType == errorType;
  }

  @override
  int get hashCode => Object.hash(
    id,
    mode,
    title,
    titleStatus,
    createdAt,
    updatedAt,
    Object.hashAll(messages),
    counselingRequest,
    counselingResponse,
    generationStatus,
    errorType,
  );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

class ChatSessionSummary {
  const ChatSessionSummary({
    required this.id,
    required this.mode,
    required this.title,
    required this.titleStatus,
    required this.preview,
    required this.createdAt,
    required this.updatedAt,
    required this.generationStatus,
  });

  final String id;
  final ChatSessionMode mode;
  final String title;
  final ChatTitleStatus titleStatus;
  final String preview;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ChatGenerationStatus generationStatus;

  factory ChatSessionSummary.fromSession(ChatSession session) {
    return ChatSessionSummary(
      id: session.id,
      mode: session.mode,
      title: session.title,
      titleStatus: session.titleStatus,
      preview: session.preview,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
      generationStatus: session.generationStatus,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mode': mode.name,
    'title': title,
    'titleStatus': titleStatus.name,
    'preview': preview,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'generationStatus': generationStatus.name,
  };

  factory ChatSessionSummary.fromJson(Map<String, dynamic> json) {
    return ChatSessionSummary(
      id: json['id'] as String,
      mode: ChatSessionMode.values.byName(json['mode'] as String),
      title: json['title'] as String,
      titleStatus: ChatTitleStatus.values.byName(
        json['titleStatus'] as String? ?? ChatTitleStatus.temporary.name,
      ),
      preview: json['preview'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
      generationStatus: ChatGenerationStatus.values.byName(
        json['generationStatus'] as String? ?? ChatGenerationStatus.ready.name,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatSessionSummary &&
        other.id == id &&
        other.mode == mode &&
        other.title == title &&
        other.titleStatus == titleStatus &&
        other.preview == preview &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.generationStatus == generationStatus;
  }

  @override
  int get hashCode => Object.hash(
    id,
    mode,
    title,
    titleStatus,
    preview,
    createdAt,
    updatedAt,
    generationStatus,
  );
}
