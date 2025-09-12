import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/athkar%20details/athkar_card.dart';

class LoadedState extends StatelessWidget {
  final dynamic athkarCategory;
  final List<int> repeatCounters;
  final List<int> originalRepeatCounters;
  final Map<int, GlobalKey> athkarCardKeys;
  final bool isGeneratingImage;
  final int? playingIndex;
  final bool isPlaying;
  final Duration audioDuration;
  final Duration audioPosition;
  final ColorScheme colorScheme;
  final bool isDark;
  final String title;
  final ValueChanged<int> onCounterTap;
  final ValueChanged<int> onResetCounter;
  final ValueChanged<int> onShare;
  final Future<void> Function(String?, int) onPlayAudio;
  final Future<void> Function(Duration)? onSeek;

  const LoadedState({
    super.key,
    required this.athkarCategory,
    required this.repeatCounters,
    required this.originalRepeatCounters,
    required this.athkarCardKeys,
    required this.isGeneratingImage,
    required this.playingIndex,
    required this.isPlaying,
    required this.audioDuration,
    required this.audioPosition,
    required this.colorScheme,
    required this.isDark,
    required this.title,
    required this.onCounterTap,
    required this.onResetCounter,
    required this.onShare,
    required this.onPlayAudio,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: athkarCategory.details.length,
      separatorBuilder: (context, index) => SizedBox(height: 20.h),
      itemBuilder: (context, index) {
        final isCompleted = repeatCounters[index] == 0;
        final detail = athkarCategory.details[index];

        athkarCardKeys[index] ??= GlobalKey();

        return RepaintBoundary(
          key: athkarCardKeys[index],
          child: GestureDetector(
            onTap: () => onCounterTap(index),
            child: AthkarCard(
              index: index,
              detail: detail,
              isCompleted: isCompleted,
              isDark: isDark,
              colorScheme: colorScheme,
              repeatCount: repeatCounters[index],
              originalRepeatCount: originalRepeatCounters[index],
              playingIndex: playingIndex,
              isPlaying: isPlaying,
              audioDuration: audioDuration,
              audioPosition: audioPosition,
              onResetCounter: () => onResetCounter(index),
              onShare: () => onShare(index),
              onPlayAudio: (audioUrl) => onPlayAudio(audioUrl, index),
              onSeek: (position) => onSeek!(position),
            ),
          ),
        );
      },
    );
  }
}
