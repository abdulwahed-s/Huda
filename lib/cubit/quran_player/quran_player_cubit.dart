import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:huda/core/quran/quran.dart';
import 'package:huda/core/services/audio_coordinator.dart';
import 'package:huda/core/services/quran_audio_progress_service.dart';
import 'package:huda/core/services/service_locator.dart';

import 'package:huda/data/models/reciter_model.dart';
import 'package:huda/cubit/quran_player/quran_player_state.dart';
import 'package:huda/cubit/quran_player/download_progress_cubit.dart';

class QuranPlayerCubit extends Cubit<QuranPlayerState> {
  final AudioPlayer audioPlayer = getIt<AudioPlayer>();
  final AudioCoordinator _coordinator = getIt<AudioCoordinator>();
  final DownloadProgressCubit downloadProgressCubit;

  Reciter? _currentReciter;
  Moshaf? _currentMoshaf;
  List? _currentJsonData;
  StreamSubscription<int?>? _indexSub;
  StreamSubscription<Duration>? _positionSub;
  int _lastSavedSurahIndex = -1;
  DateTime _lastSaveTime = DateTime.now();

  QuranPlayerCubit({required this.downloadProgressCubit})
      : super(QuranPlayerInitial()) {
    _coordinator.register(AudioCoordinator.quranPlayer, () {
      if (state is QuranPlayerPlaying || state is QuranPlayerLoading) {
        _saveCurrentPosition();
        _cancelTracking();
        emit(QuranPlayerInitial());
      }
    });
  }

  Future<Directory> get _downloadDir async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/huda_audio');
    if (!audioDir.existsSync()) {
      audioDir.createSync(recursive: true);
    }
    return audioDir;
  }

  String _localFileName(Reciter reciter, Moshaf moshaf, String surahNumber) {
    return '${reciter.name}-${moshaf.id}-${getSurahNameArabic(int.parse(surahNumber))}.mp3';
  }

  Future<void> startPlaying({
    required Moshaf moshaf,
    required Reciter reciter,
    required int suraNumber,
    required int initialIndex,
    required List jsonData,
    int initialPositionMs = 0,
  }) async {
    try {
      _coordinator.requestAudio(AudioCoordinator.quranPlayer);
      audioPlayer.stop();
      _cancelTracking();
      emit(QuranPlayerLoading(
        reciterId: reciter.id,
        moshafId: moshaf.id,
        initialIndex: initialIndex,
      ));

      int nextMediaId = 0;
      List<String> surahNumbers = moshaf.surahList.toString().split(',');
      final appDir = await _downloadDir;

      if (Platform.isAndroid) {
        final hasLocal = surahNumbers.any((e) =>
            File('${appDir.path}/${_localFileName(reciter, moshaf, e)}')
                .existsSync());
        if (hasLocal) {
          await _requestStoragePermission();
        }
      }

      List<Map<String, dynamic>> reciterLinks = surahNumbers.map((e) {
        final localPath =
            '${appDir.path}/${_localFileName(reciter, moshaf, e)}';
        if (File(localPath).existsSync()) {
          return {"link": Uri.file(localPath), "suraNumber": e};
        } else {
          return {
            "link": Uri.parse(
                '${moshaf.server}/${e.toString().padLeft(3, "0")}.mp3'),
            "suraNumber": e
          };
        }
      }).toList();

      var playList = reciterLinks.map((e) {
        return AudioSource.uri(
          e["link"] as Uri,
          tag: MediaItem(
            id: '${nextMediaId++}',
            album: '${reciter.name}',
            title: jsonData
                .where((element) =>
                    element["id"].toString() == e["suraNumber"].toString())
                .first["name"]
                .toString(),
            artUri: Uri.parse(
                'https://images.pexels.com/photos/318451/pexels-photo-318451.jpeg?auto=compress&cs=tinysrgb&w=600'),
          ),
        );
      }).toList();

      String currentSuraNumber = "";
      if (suraNumber == -1) {
        currentSuraNumber = surahNumbers[0];
      }

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());

      audioPlayer.playbackEventStream.listen(
        (event) {},
        onError: (Object e, StackTrace stackTrace) {
          debugPrint('A stream error occurred: $e');
        },
      );
      audioPlayer.setLoopMode(LoopMode.off);

      try {
        await audioPlayer.setAudioSource(
          ConcatenatingAudioSource(children: playList),
          initialIndex: initialIndex,
        );
      } catch (e) {
        debugPrint("Error loading playlist: $e");
      }

      audioPlayer.play();

      if (initialPositionMs > 0) {
        await audioPlayer.seek(Duration(milliseconds: initialPositionMs));
      }

      emit(QuranPlayerPlaying(
        moshaf: moshaf,
        reciter: reciter,
        suraNumber:
            suraNumber == -1 ? int.parse(currentSuraNumber) : suraNumber,
        jsonData: jsonData,
        audioPlayer: audioPlayer,
        surahNumbers: surahNumbers,
        playList: playList,
      ));

      _currentReciter = reciter;
      _currentMoshaf = moshaf;
      _currentJsonData = jsonData;
      _lastSavedSurahIndex = initialIndex;
      _lastSaveTime = DateTime.now();
      _startTracking();

      _saveCurrentPosition();
    } catch (e) {
      emit(QuranPlayerError(e.toString()));
    }
  }

  void _startTracking() {
    _indexSub = audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index != _lastSavedSurahIndex) {
        _saveCurrentPosition();
        _lastSavedSurahIndex = index;
      }
    });

    _positionSub = audioPlayer.positionStream.listen((position) {
      if (DateTime.now().difference(_lastSaveTime).inSeconds >= 5) {
        _saveCurrentPosition();
        _lastSaveTime = DateTime.now();
      }
    });
  }

  void _cancelTracking() {
    _indexSub?.cancel();
    _indexSub = null;
    _positionSub?.cancel();
    _positionSub = null;
  }

  void _saveCurrentPosition() {
    if (_currentReciter == null || _currentMoshaf == null) return;
    final index = audioPlayer.currentIndex ?? _lastSavedSurahIndex;
    if (index < 0) return;
    final position = audioPlayer.position;
    getIt<QuranAudioProgressService>().savePosition(
      reciter: _currentReciter!,
      moshaf: _currentMoshaf!,
      jsonData: _currentJsonData!,
      surahIndex: index,
      positionMs: position.inMilliseconds,
    );
  }

  Future<void> downloadSurah({
    required Reciter reciter,
    required Moshaf moshaf,
    required String suraNumber,
    required String url,
  }) async {
    try {
      if (Platform.isAndroid) {
        await _requestStoragePermission();
      }

      final appDir = await _downloadDir;
      final fullPath =
          '${appDir.path}/${_localFileName(reciter, moshaf, suraNumber)}';

      if (File(fullPath).existsSync()) {
        downloadProgressCubit.completeSurahDownload(
            reciter.id, moshaf.id, suraNumber);
        return;
      }

      downloadProgressCubit.updateSurahProgress(
          reciter.id, moshaf.id, suraNumber, 0.0);

      final dio = Dio();
      await dio.download(
        url,
        fullPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            downloadProgressCubit.updateSurahProgress(
              reciter.id,
              moshaf.id,
              suraNumber,
              received / total,
            );
          }
        },
      );

      downloadProgressCubit.completeSurahDownload(
          reciter.id, moshaf.id, suraNumber);
    } catch (e) {
      downloadProgressCubit.removeSurahProgress(
          reciter.id, moshaf.id, suraNumber);
      debugPrint('Download error: $e');
    }
  }

  Future<void> downloadAllSurahs({
    required Reciter reciter,
    required Moshaf moshaf,
  }) async {
    try {
      if (Platform.isAndroid) {
        await _requestStoragePermission();
      }

      List<String> surahNumbers = moshaf.surahList.toString().split(',');
      final appDir = await _downloadDir;
      final dio = Dio();

      int totalToDownload = 0;
      List<String> toDownload = [];
      for (var sn in surahNumbers) {
        final fp = '${appDir.path}/${_localFileName(reciter, moshaf, sn)}';
        if (!File(fp).existsSync()) {
          toDownload.add(sn);
        }
      }
      totalToDownload = toDownload.length;
      if (totalToDownload == 0) return;

      int completed = 0;
      downloadProgressCubit.updateBatchProgress(
          reciter.id, moshaf.id, 0, totalToDownload);

      for (var suraNumber in toDownload) {
        final fullPath =
            '${appDir.path}/${_localFileName(reciter, moshaf, suraNumber)}';
        final url =
            '${moshaf.server}/${suraNumber.toString().padLeft(3, "0")}.mp3';

        downloadProgressCubit.updateSurahProgress(
            reciter.id, moshaf.id, suraNumber, 0.0);

        try {
          await dio.download(
            url,
            fullPath,
            onReceiveProgress: (received, total) {
              if (total > 0) {
                downloadProgressCubit.updateSurahProgress(
                  reciter.id,
                  moshaf.id,
                  suraNumber,
                  received / total,
                );
              }
            },
          );
          downloadProgressCubit.completeSurahDownload(
              reciter.id, moshaf.id, suraNumber);
        } catch (e) {
          downloadProgressCubit.removeSurahProgress(
              reciter.id, moshaf.id, suraNumber);
          debugPrint('Error downloading surah $suraNumber: $e');
        }
        completed++;
        downloadProgressCubit.updateBatchProgress(
            reciter.id, moshaf.id, completed, totalToDownload);
      }

      downloadProgressCubit.completeBatch(reciter.id, moshaf.id);
    } catch (e) {
      downloadProgressCubit.completeBatch(reciter.id, moshaf.id);
      debugPrint('Download all error: $e');
    }
  }

  bool isDownloaded(Reciter reciter, Moshaf moshaf, String suraNumber,
      String downloadDirPath) {
    final fullPath =
        '$downloadDirPath/${_localFileName(reciter, moshaf, suraNumber)}';
    return File(fullPath).existsSync();
  }

  Future<String> getDownloadDirPath() async {
    final dir = await _downloadDir;
    return dir.path;
  }

  void closePlayer() {
    _saveCurrentPosition();
    _cancelTracking();
    audioPlayer.stop();
    _coordinator.release(AudioCoordinator.quranPlayer);
    emit(QuranPlayerInitial());
  }

  void pausePlayer() {
    _saveCurrentPosition();
    audioPlayer.pause();
  }

  void resumePlayer() {
    audioPlayer.play();
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
    }
  }

  @override
  Future<void> close() {
    _cancelTracking();
    _coordinator.unregister(AudioCoordinator.quranPlayer);
    return super.close();
  }
}
