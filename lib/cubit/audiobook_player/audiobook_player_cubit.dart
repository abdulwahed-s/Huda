import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:huda/core/bootstrap/audio_service_ready.dart';
import 'package:huda/core/services/audio_coordinator.dart';
import 'package:huda/core/services/audio_progress_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/data/models/audio_detail_model.dart';
import 'package:huda/data/services/offline_audiobooks_service.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_state.dart';

class AudiobookPlayerCubit extends Cubit<AudiobookPlayerState> {
  final AudioPlayer audioPlayer = getIt<AudioPlayer>();
  final AudioCoordinator _coordinator = getIt<AudioCoordinator>();
  final AudioProgressService _progressService;
  final OfflineAudiobooksService _offlineService;

  static const String _fallbackArt =
      'https://images.pexels.com/photos/8164742/pexels-photo-8164742.jpeg?auto=compress&cs=tinysrgb&w=600';

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<int?>? _indexSub;
  DateTime _lastSaved = DateTime.fromMillisecondsSinceEpoch(0);

  Timer? _sleepTimer;
  bool _endOfChapterSleep = false;
  final ValueNotifier<Duration?> sleepRemaining = ValueNotifier(null);
  Duration? _initialSleepDuration;

  Duration? get initialSleepDuration => _initialSleepDuration;

  int _currentId = 0;
  String _currentTitle = '';
  String _currentAuthor = '';
  int _trackCount = 0;

  AudiobookPlayerCubit({
    required AudioProgressService progressService,
    required OfflineAudiobooksService offlineService,
  })  : _progressService = progressService,
        _offlineService = offlineService,
        super(AudiobookPlayerInitial()) {
    _coordinator.register(AudioCoordinator.audiobook, () {
      if (state is AudiobookPlayerPlaying || state is AudiobookPlayerLoading) {
        _saveCurrentPosition();
        _cancelSubscriptions();
        cancelSleepTimer();
        emit(AudiobookPlayerInitial());
      }
    });
  }

  Future<void> startPlaying({
    required int audiobookId,
    required List<AudioTrack> tracks,
    required String title,
    required String author,
    String? artUrl,
    int initialIndex = 0,
    Duration? initialPosition,
    required bool isOffline,
  }) async {
    try {
      if (tracks.isEmpty) {
        emit(AudiobookPlayerError('No tracks available'));
        return;
      }

      _coordinator.requestAudio(AudioCoordinator.audiobook);
      await audioPlayer.stop();
      _cancelSubscriptions();

      _currentId = audiobookId;
      _currentTitle = title;
      _currentAuthor = author;
      _trackCount = tracks.length;

      emit(AudiobookPlayerLoading(
        audiobookId: audiobookId,
        initialTrackIndex: initialIndex,
      ));

      final offline = await _offlineService.getAudiobook(audiobookId);
      final Map<int, String> localByOrder = {};
      if (offline != null) {
        for (final t in offline.tracks) {
          if (t.isDownloaded) localByOrder[t.order] = t.localPath;
        }
      }

      final bool hasLocal = localByOrder.isNotEmpty;
      if (Platform.isAndroid && hasLocal) {
        await _requestStoragePermission();
      }

      int nextMediaId = 0;
      final List<AudioSource> playList = tracks.map((track) {
        final localPath = localByOrder[track.order];
        final Uri uri = (localPath != null && File(localPath).existsSync())
            ? Uri.file(localPath)
            : Uri.parse(track.url);
        return AudioSource.uri(
          uri,
          tag: MediaItem(
            id: '${nextMediaId++}',
            album: author,
            title: track.description.isNotEmpty ? track.description : title,
            artUri: Uri.parse(
                (artUrl != null && artUrl.isNotEmpty) ? artUrl : _fallbackArt),
          ),
        );
      }).toList();

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());

      audioPlayer.playbackEventStream.listen(
        (event) {},
        onError: (Object e, StackTrace stackTrace) {
          debugPrint('Audiobook stream error: $e');
        },
      );
      audioPlayer.setLoopMode(LoopMode.off);

      await audioServiceReady;

      try {
        await audioPlayer.setAudioSource(
          ConcatenatingAudioSource(children: playList),
          initialIndex: initialIndex,
          initialPosition: initialPosition ?? Duration.zero,
        );
      } catch (e) {
        debugPrint('Error loading audiobook playlist: $e');
      }

      audioPlayer.play();

      _attachProgressListeners();

      emit(AudiobookPlayerPlaying(
        audiobookId: audiobookId,
        title: title,
        author: author,
        artUrl: artUrl,
        audioPlayer: audioPlayer,
        tracks: tracks,
        playList: playList,
        isOffline: isOffline,
      ));
    } catch (e) {
      emit(AudiobookPlayerError(e.toString()));
    }
  }

  void _attachProgressListeners() {
    _positionSub = audioPlayer.positionStream.listen((position) {
      final now = DateTime.now();
      if (now.difference(_lastSaved).inSeconds >= 5) {
        _lastSaved = now;
        _saveCurrentPosition();
      }
    });
    _indexSub = audioPlayer.currentIndexStream.listen((_) {
      _saveCurrentPosition();
      if (_endOfChapterSleep) {
        _endOfChapterSleep = false;
        sleepRemaining.value = null;
        audioPlayer.pause();
      }
    });
  }

  void _saveCurrentPosition() {
    if (_currentId == 0) return;
    final index = audioPlayer.currentIndex ?? 0;
    _progressService.savePosition(
      _currentId,
      index,
      audioPlayer.position,
      title: _currentTitle,
      author: _currentAuthor,
      trackCount: _trackCount,
    );
  }

  void pause() {
    audioPlayer.pause();
    _saveCurrentPosition();
  }

  void resume() => audioPlayer.play();

  Future<void> seek(Duration position) => audioPlayer.seek(position);

  Future<void> seekToIndex(int index) async {
    await audioPlayer.seek(Duration.zero, index: index);
    if (!audioPlayer.playing) audioPlayer.play();
  }

  Future<void> skipForward([Duration by = const Duration(seconds: 30)]) async {
    final target = audioPlayer.position + by;
    final dur = audioPlayer.duration ?? target;
    await audioPlayer.seek(target > dur ? dur : target);
  }

  Future<void> skipBackward([Duration by = const Duration(seconds: 15)]) async {
    final target = audioPlayer.position - by;
    await audioPlayer.seek(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> nextChapter() async {
    if (audioPlayer.hasNext) await audioPlayer.seekToNext();
  }

  Future<void> previousChapter() async {
    if (audioPlayer.hasPrevious) await audioPlayer.seekToPrevious();
  }

  Future<void> setSpeed(double speed) => audioPlayer.setSpeed(speed);

  void startSleepTimer(Duration duration) {
    cancelSleepTimer();
    _endOfChapterSleep = false;
    _initialSleepDuration = duration;
    Duration remaining = duration;
    sleepRemaining.value = remaining;
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining -= const Duration(seconds: 1);
      if (remaining <= Duration.zero) {
        timer.cancel();
        sleepRemaining.value = null;
        audioPlayer.pause();
      } else {
        sleepRemaining.value = remaining;
      }
    });
  }

  void startEndOfChapterTimer() {
    cancelSleepTimer();
    _endOfChapterSleep = true;
    sleepRemaining.value = const Duration(seconds: -1);
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _endOfChapterSleep = false;
    _initialSleepDuration = null;
    sleepRemaining.value = null;
  }

  bool get isSleepTimerActive => _sleepTimer != null || _endOfChapterSleep;

  void closePlayer() {
    _saveCurrentPosition();
    _cancelSubscriptions();
    cancelSleepTimer();
    audioPlayer.stop();
    _coordinator.release(AudioCoordinator.audiobook);
    emit(AudiobookPlayerInitial());
  }

  void _cancelSubscriptions() {
    _positionSub?.cancel();
    _positionSub = null;
    _indexSub?.cancel();
    _indexSub = null;
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
    _cancelSubscriptions();
    cancelSleepTimer();
    sleepRemaining.dispose();
    _coordinator.unregister(AudioCoordinator.audiobook);
    return super.close();
  }
}
