import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/presentation/widgets/athkar%20details/arabic_text_container.dart';
import 'package:huda/presentation/widgets/athkar%20details/audio_controls.dart';
import 'package:huda/presentation/widgets/athkar%20details/counter_badge.dart';
import 'package:huda/presentation/widgets/athkar%20details/share_button.dart';
import 'package:huda/presentation/widgets/athkar%20details/translation_section.dart';

class AthkarCard extends StatelessWidget {
  final int index;
  final dynamic detail;
  final bool isCompleted;
  final bool isDark;
  final ColorScheme colorScheme;
  final int repeatCount;
  final int originalRepeatCount;
  final int? playingIndex;
  final bool isPlaying;
  final Duration audioDuration;
  final Duration audioPosition;
  final VoidCallback onResetCounter;
  final VoidCallback onShare;
  final Future<void> Function(String?) onPlayAudio;
  final Future<void> Function(Duration)? onSeek;

  const AthkarCard({
    super.key,
    required this.index,
    required this.detail,
    required this.isCompleted,
    required this.isDark,
    required this.colorScheme,
    required this.repeatCount,
    required this.originalRepeatCount,
    required this.playingIndex,
    required this.isPlaying,
    required this.audioDuration,
    required this.audioPosition,
    required this.onResetCounter,
    required this.onShare,
    required this.onPlayAudio,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final currentLanguageCode =
        context.read<LocalizationCubit>().state.locale.languageCode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: isCompleted
            ? LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.1),
                  Colors.green.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF1A1A1A),
                        const Color(0xFF252525),
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFFAFAFA),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CounterBadge(
                isCompleted: isCompleted,
                colorScheme: colorScheme,
                repeatCount: repeatCount,
                onResetCounter: onResetCounter,
              ),
              ShareButton(
                colorScheme: colorScheme,
                onShare: onShare,
              ),
            ],
          ),
          SizedBox(height: 20.h),
          ArabicTextContainer(
            arabicText: detail.arabicText ?? '',
            colorScheme: colorScheme,
          ),
          if (currentLanguageCode != "ar") SizedBox(height: 16.h),
          if (currentLanguageCode != "ar")
            TranslationSection(
              translatedText: detail.translatedText ?? '',
              colorScheme: colorScheme,
            ),
          SizedBox(height: 16.h),
          if (detail.audio != null && detail.audio!.isNotEmpty)
            AudioControls(
              audioUrl: detail.audio,
              index: index,
              colorScheme: colorScheme,
              isCurrentlyPlaying: playingIndex == index,
              isPlaying: isPlaying,
              audioDuration: audioDuration,
              audioPosition: audioPosition,
              onPlayAudio: onPlayAudio,
              onSeek: onSeek,
            ),
        ],
      ),
    );
  }
}
