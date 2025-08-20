enum Sender { user, model }

class ChatMessage {
  final String text;
  final Sender sender;

  const ChatMessage({required this.text, required this.sender});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.text == text && other.sender == sender;
  }

  @override
  int get hashCode => text.hashCode ^ sender.hashCode;
}
