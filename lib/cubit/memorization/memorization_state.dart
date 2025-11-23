part of 'memorization_cubit.dart';

abstract class MemorizationState extends Equatable {
  const MemorizationState();

  @override
  List<Object?> get props => [];
}

class MemorizationInitial extends MemorizationState {}

class MemorizationModeUpdated extends MemorizationState {
  final bool isMemorizationMode;
  final Set<int> hiddenAyahIndices;
  final bool isListening;
  final int? listeningAyahIndex;
  final String recognizedText;
  final bool isMatch;

  const MemorizationModeUpdated({
    required this.isMemorizationMode,
    required this.hiddenAyahIndices,
    this.isListening = false,
    this.listeningAyahIndex,
    this.recognizedText = '',
    this.isMatch = false,
  });

  @override
  List<Object?> get props => [
        isMemorizationMode,
        hiddenAyahIndices,
        isListening,
        listeningAyahIndex,
        recognizedText,
        isMatch,
      ];

  MemorizationModeUpdated copyWith({
    bool? isMemorizationMode,
    Set<int>? hiddenAyahIndices,
    bool? isListening,
    int? listeningAyahIndex,
    String? recognizedText,
    bool? isMatch,
  }) {
    return MemorizationModeUpdated(
      isMemorizationMode: isMemorizationMode ?? this.isMemorizationMode,
      hiddenAyahIndices: hiddenAyahIndices ?? this.hiddenAyahIndices,
      isListening: isListening ?? this.isListening,
      listeningAyahIndex: listeningAyahIndex ?? this.listeningAyahIndex,
      recognizedText: recognizedText ?? this.recognizedText,
      isMatch: isMatch ?? this.isMatch,
    );
  }
}

class MemorizationError extends MemorizationState {
  final String message;

  const MemorizationError(this.message);

  @override
  List<Object> get props => [message];
}

class MemorizationCompleted extends MemorizationState {
  const MemorizationCompleted();
}
