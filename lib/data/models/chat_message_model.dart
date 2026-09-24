enum Sender { user, model }

class ChatMessage {
  final String id;
  final String text;
  final Sender sender;
  final DateTime createdAt;
  final bool isComplete;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.createdAt,
    this.isComplete = true,
  });

  ChatMessage copyWith({String? text, bool? isComplete}) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      sender: sender,
      createdAt: createdAt,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'sender': sender.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'isComplete': isComplete,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      sender: Sender.values.byName(json['sender'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      isComplete: json['isComplete'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.text == text &&
        other.sender == sender &&
        other.createdAt == createdAt &&
        other.isComplete == isComplete;
  }

  @override
  int get hashCode => Object.hash(id, text, sender, createdAt, isComplete);
}
