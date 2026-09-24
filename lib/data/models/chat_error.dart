enum ChatErrorType {
  noConnection,
  rateLimit,
  server,
  safetyFilter,
  interrupted,
  unknown,
}

class ChatException implements Exception {
  final ChatErrorType type;

  const ChatException(this.type);

  @override
  String toString() => 'ChatException($type)';
}
