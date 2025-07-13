import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioControlsWidget extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final int currentIndex;
  final int totalAyahs;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Function(double) onSeek;
  final Function(bool) onUserSeekingChanged;
  final bool isPlayButtonEnabled;

  const AudioControlsWidget({
    super.key,
    required this.audioPlayer,
    required this.currentIndex,
    required this.totalAyahs,
    required this.currentPosition,
    required this.totalDuration,
    required this.isPlaying,
    required this.onPlayPause,
    this.onPrevious,
    this.onNext,
    required this.onSeek,
    required this.onUserSeekingChanged,
    this.isPlayButtonEnabled = true,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress bar
        if (totalDuration.inMilliseconds > 0)
          Column(
            children: [
              Slider(
                value: totalDuration.inMilliseconds > 0
                    ? (currentPosition.inMilliseconds /
                            totalDuration.inMilliseconds)
                        .clamp(0.0, 1.0)
                    : 0.0,
                onChanged: (value) {
                  onUserSeekingChanged(true);
                  onSeek(value);
                },
                onChangeEnd: (value) {
                  onUserSeekingChanged(false);
                },
                activeColor: const Color.fromARGB(255, 103, 43, 93),
                inactiveColor: Colors.grey[300],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(currentPosition),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      _formatDuration(totalDuration),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Previous button
            IconButton(
              onPressed: currentIndex > 0 ? onPrevious : null,
              icon: Icon(
                Icons.skip_previous,
                color: currentIndex > 0
                    ? const Color.fromARGB(255, 103, 43, 93)
                    : Colors.grey,
                size: 32,
              ),
            ),
            // Play/Pause button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPlayButtonEnabled
                    ? const Color.fromARGB(255, 103, 43, 93)
                    : Colors.grey,
                boxShadow: isPlayButtonEnabled
                    ? [
                        BoxShadow(
                          color: const Color.fromARGB(255, 103, 43, 93)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: IconButton(
                onPressed: isPlayButtonEnabled ? onPlayPause : null,
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            // Next button
            IconButton(
              onPressed: currentIndex < totalAyahs - 1 ? onNext : null,
              icon: Icon(
                Icons.skip_next,
                color: currentIndex < totalAyahs - 1
                    ? const Color.fromARGB(255, 103, 43, 93)
                    : Colors.grey,
                size: 32,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
