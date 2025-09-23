import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

            return Container(
              padding: const EdgeInsets.all(0),
              child: Opacity(
                opacity: isAyahAvailable ? 1.0 : 0.6, // Dim unavailable ayahs
                child: Text(
                  ayahText,
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontFamily: 'uthmanic',
                    fontSize: 18.sp,
                    color: isPlaying
                        ? const Color(0xFF10B981) // Bright green for playing
                        : (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFF8FAFC) // Pure white
                            : Colors.black87),
                    height: 2.0,
                    fontWeight: FontWeight.w400,
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
