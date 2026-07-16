import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/core/services/reading_position_service.dart';
import 'package:huda/core/services/quran_audio_progress_service.dart';
import 'package:huda/core/services/quran_radio_progress_service.dart';
import 'package:huda/core/services/khatma_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/data/models/home/home_dashboard_data.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    ReadingPositionService? readingPositionService,
    QuranAudioProgressService? quranAudioProgressService,
    QuranRadioProgressService? quranRadioProgressService,
    KhatmaService? khatmaService,
  })  : _readingPositionService =
            readingPositionService ?? getIt<ReadingPositionService>(),
        _quranAudioProgressService =
            quranAudioProgressService ?? getIt<QuranAudioProgressService>(),
        _quranRadioProgressService =
            quranRadioProgressService ?? getIt<QuranRadioProgressService>(),
        _khatmaService = khatmaService ?? getIt<KhatmaService>(),
        super(HomeInitial()) {
    _khatmaSubscription = _khatmaService.khatmaChanges.listen((_) {
      loadHomeData();
    });
    loadHomeData();
  }

  final ReadingPositionService _readingPositionService;
  final QuranAudioProgressService _quranAudioProgressService;
  final QuranRadioProgressService _quranRadioProgressService;
  final KhatmaService _khatmaService;
  StreamSubscription<void>? _khatmaSubscription;

  void loadHomeData() {
    try {
      emit(HomeLoading());

      final hasLastRead = _readingPositionService.hasLastReadPosition();
      final lastReadSummary = _readingPositionService.getLastReadSummary();
      final lastQuranAudio = _quranAudioProgressService.getLastPlayed();
      final lastRadioStation = _quranRadioProgressService.getLastStation();
      final dailyAyah = dailyAyahFor(DateTime.now());
      final khatma = _readKhatma();

      emit(HomeLoaded(
        hasLastReadPosition: hasLastRead,
        lastReadSummary: lastReadSummary,
        hasLastQuranAudio: lastQuranAudio != null,
        lastQuranAudio: lastQuranAudio,
        hasLastRadioStation: lastRadioStation != null,
        lastRadioStation: lastRadioStation,
        dailyAyah: dailyAyah,
        khatma: khatma,
      ));
    } catch (e) {
      emit(HomeError(message: 'Failed to load home data: $e'));
    }
  }

  Map<String, dynamic>? getLastReadPosition() {
    return _readingPositionService.getLastReadSummary();
  }

  Future<void> clearLastReadPosition() async {
    try {
      await _readingPositionService.clearLastReadPosition();
      loadHomeData();
    } catch (e) {
      emit(HomeError(message: 'Failed to clear last read position: $e'));
    }
  }

  void refresh() {
    loadHomeData();
  }

  static DailyAyah dailyAyahFor(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(2000))
        .inDays;
    var verseIndex = day % quran.totalVerseCount;

    for (var surah = 1; surah <= quran.totalSurahCount; surah++) {
      final verseCount = quran.getVerseCount(surah);
      if (verseIndex < verseCount) {
        final ayah = verseIndex + 1;
        return DailyAyah(
          surahNumber: surah,
          ayahNumber: ayah,
          text: quran.getVerse(surah, ayah, verseEndSymbol: false),
        );
      }
      verseIndex -= verseCount;
    }

    return DailyAyah(
      surahNumber: 1,
      ayahNumber: 1,
      text: quran.getVerse(1, 1, verseEndSymbol: false),
    );
  }

  KhatmaSnapshot _readKhatma() {
    final active = _khatmaService.enabled;
    final completed = _khatmaService.isCompleted;
    int? startSurah;
    int? startAyah;
    if (active && !completed) {
      final details = _khatmaService.rangeDetailsForDay(
        _khatmaService.currentDayIndex,
        _khatmaService.planDays,
      );
      startSurah = details.startSurah;
      startAyah = details.startVerse;
    }

    return KhatmaSnapshot(
      isActive: active,
      isCompleted: completed,
      currentDay: _khatmaService.currentDayIndex,
      totalDays: _khatmaService.planDays,
      progress: _khatmaService.percentTotal,
      startSurah: startSurah,
      startAyah: startAyah,
    );
  }

  @override
  Future<void> close() async {
    await _khatmaSubscription?.cancel();
    return super.close();
  }
}
