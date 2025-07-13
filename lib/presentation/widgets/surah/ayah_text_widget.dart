import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/audio/audio_cubit.dart';
import 'package:huda/data/models/surah_model.dart';

class AyahTextWidget extends StatelessWidget {
  final Ayahs ayah;
  final int index;
  final int? playingAyahIndex;
  final String? selectedReaderId;
  final int surahNumber;
  final VoidCallback onTap;
  final VoidCallback? onUnavailableTap;

  const AyahTextWidget({
    super.key,
    required this.ayah,
    required this.index,
    required this.playingAyahIndex,
    required this.selectedReaderId,
    required this.surahNumber,
    required this.onTap,
    this.onUnavailableTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = index == playingAyahIndex;
    String ayahText = ayah.text ?? '';
    final isFirstAyah = ayah.numberInSurah == 1;
    final shouldShowBismillah =
        isFirstAyah && surahNumber != 1 && surahNumber != 9;

    // Remove Bismillah if it exists in the text
    if (shouldShowBismillah) {
      const bismillahText = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
      if (ayahText.trim().startsWith(bismillahText)) {
        ayahText = ayahText.trim().replaceFirst(bismillahText, '').trim();
      }
    }

    return BlocBuilder<AudioCubit, AudioState>(
      builder: (context, audioState) {
        // Determine if we're in offline mode
        bool isOfflineMode = audioState is AudioOfflineWithDownloads ||
            audioState is ReaderOffline;

        return FutureBuilder<bool>(
          future: isOfflineMode && selectedReaderId != null
              ? context.read<AudioCubit>().isAyahDownloaded(
                    surahNumber: surahNumber.toString(),
                    ayahNumber: ayah.numberInSurah.toString(),
                    readerId: selectedReaderId!,
                  )
              : Future.value(true), // Always available in online mode
          builder: (context, downloadSnapshot) {
            bool isAyahAvailable = downloadSnapshot.data ?? false;
            if (!isOfflineMode) {
              isAyahAvailable = true; // Always available online
            }

            return GestureDetector(
              onTap: isAyahAvailable ? onTap : onUnavailableTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isPlaying ? const Color(0xFFE0F7F1) : null,
                  borderRadius: BorderRadius.circular(12),
                  // Add a subtle visual indicator for non-available ayahs
                  border: !isAyahAvailable
                      ? Border.all(color: Colors.grey[300]!, width: 1)
                      : null,
                ),
                child: Opacity(
                  opacity: isAyahAvailable ? 1.0 : 0.6, // Dim unavailable ayahs
                  child: RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: ayahText,
                          style: const TextStyle(
                            fontFamily: 'uthmanic',
                            fontSize: 22,
                            color: Colors.black,
                            height: 1.8,
                          ),
                        ),
                        // Download status indicator
                        if (selectedReaderId != null)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: FutureBuilder<bool>(
                              future: context
                                  .read<AudioCubit>()
                                  .isAyahDownloaded(
                                    surahNumber: surahNumber.toString(),
                                    ayahNumber: ayah.numberInSurah.toString(),
                                    readerId: selectedReaderId!,
                                  ),
                              builder: (context, snapshot) {
                                if (snapshot.data == true) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    child: const Icon(
                                      Icons.download_done,
                                      size: 14,
                                      color: Colors.green,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isAyahAvailable
                                  ? const Color(0xFFF0E6D2).withOpacity(0.7)
                                  : Colors.grey[200],
                              border: Border.all(
                                color: isAyahAvailable
                                    ? const Color(0xFF2B6747)
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${ayah.numberInSurah}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isAyahAvailable
                                    ? const Color(0xFF2B6747)
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
