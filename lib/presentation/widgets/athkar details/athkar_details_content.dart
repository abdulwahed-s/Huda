import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/athkar_details/athkar_details_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/athkar%20details/error_state.dart';
import 'package:huda/presentation/widgets/athkar%20details/loaded_state.dart';
import 'package:huda/presentation/widgets/athkar%20details/loading_state.dart';
import 'package:huda/presentation/widgets/athkar%20details/offline_state.dart';
import 'package:huda/presentation/widgets/athkar%20details/share_image_footer.dart';
import 'package:huda/presentation/widgets/athkar%20details/share_image_header.dart';
import 'package:huda/presentation/widgets/athkar%20details/share_image_translation.dart';
import 'package:huda/presentation/widgets/athkar%20details/share_options_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/rendering.dart';

import 'share_image_arabic_text.dart';

class AthkarDetailsContent extends StatefulWidget {
  final String athkarId;
  final String title;
  final String titleEn;

  const AthkarDetailsContent({
    super.key,
    required this.athkarId,
    required this.title,
    required this.titleEn,
  });

  @override
  State<AthkarDetailsContent> createState() => _AthkarDetailsContentState();
}

class _AthkarDetailsContentState extends State<AthkarDetailsContent>
    with TickerProviderStateMixin {
  List<int>? _repeatCounters;
  List<int>? _originalRepeatCounters;
  bool _isGeneratingImage = false;
  final Map<int, GlobalKey> _athkarCardKeys = {};

  AudioPlayer? _audioPlayer;
  int? _playingIndex;
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  @override
  void initState() {
    _initAudioPlayer();
    super.initState();
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();
    _playerStateSubscription =
        _audioPlayer!.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        _playNextAudio();
      }
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed || state == PlayerState.stopped) {
            _audioPosition = Duration.zero;
          }
        });
      }
    });
    _durationSubscription = _audioPlayer!.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _audioDuration = duration;
        });
      }
    });
    _positionSubscription = _audioPlayer!.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _audioPosition = position;
        });
      }
    });
  }

  void _playNextAudio() {
    if (_playingIndex == null) return;

    final state = context.read<AthkarDetailsCubit>().state;
    if (state is! AthkarDetailsLoaded) return;

    final nextIndex = _playingIndex! + 1;
    if (nextIndex < state.athkarCategory.details.length) {
      final nextAudio = state.athkarCategory.details[nextIndex].audio;
      if (nextAudio != null && nextAudio.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _playAudio(nextAudio, nextIndex);
          }
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _playingIndex = null;
          _isPlaying = false;
          _audioPosition = Duration.zero;
        });
      }
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0A1A) : const Color(0xFFFFFDF7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.primary,
        centerTitle: true,
        title: Text(
          widget.title,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 22.sp,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
      ),
      body: BlocBuilder<AthkarDetailsCubit, AthkarDetailsState>(
        builder: (context, state) {
          if (state is AthkarDetailsLoading) {
            return LoadingState(colorScheme: colorScheme);
          } else if (state is AthkarDetailsLoaded) {
            _repeatCounters ??= List<int>.from(
              state.athkarCategory.details.map((e) => e.repeat ?? 0),
            );
            _originalRepeatCounters ??= List<int>.from(
              state.athkarCategory.details.map((e) => e.repeat ?? 0),
            );

            return LoadedState(
              athkarCategory: state.athkarCategory,
              repeatCounters: _repeatCounters!,
              originalRepeatCounters: _originalRepeatCounters!,
              athkarCardKeys: _athkarCardKeys,
              isGeneratingImage: _isGeneratingImage,
              playingIndex: _playingIndex,
              isPlaying: _isPlaying,
              audioDuration: _audioDuration,
              audioPosition: _audioPosition,
              colorScheme: colorScheme,
              isDark: isDark,
              title: widget.title,
              onCounterTap: (index) {
                if (_repeatCounters![index] > 0 && mounted) {
                  setState(() {
                    _repeatCounters![index]--;
                  });
                }
              },
              onResetCounter: (index) {
                if (mounted) {
                  setState(() {
                    _repeatCounters![index] = _originalRepeatCounters![index];
                  });
                }
              },
              onShare: _showShareOptions,
              onPlayAudio: _playAudio,
              onSeek: _seekAudio,
            );
          } else if (state is AthkarDetailsOffline) {
            return OfflineState(
              colorScheme: colorScheme,
              onRetry: () => context
                  .read<AthkarDetailsCubit>()
                  .loadAthkarDetail(widget.athkarId),
            );
          } else if (state is AthkarDetailsError) {
            return ErrorState(
              message: state.message,
              colorScheme: colorScheme,
              onRetry: () => context
                  .read<AthkarDetailsCubit>()
                  .loadAthkarDetail(widget.athkarId),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _playAudio(String? audioUrl, int index) async {
    if (audioUrl == null || audioUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'رابط الصوت غير متوفر',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (audioUrl.startsWith('http://')) {
      audioUrl = audioUrl.replaceFirst('http://', 'https://');
    }

    try {
      if (_playingIndex == index) {
        if (_isPlaying) {
          await _audioPlayer?.pause();
        } else {
          await _audioPlayer?.resume();
        }
      } else {
        await _audioPlayer?.stop();
        await _audioPlayer?.release();
        await _audioPlayer?.setSource(UrlSource(audioUrl));
        await _audioPlayer?.resume();
        if (mounted) {
          setState(() {
            _playingIndex = index;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل في تشغيل الصوت: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _seekAudio(Duration position) async {
    if (_audioPlayer != null) {
      await _audioPlayer!.seek(position);
    }
  }

  void _showShareOptions(int index) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ShareOptionsBottomSheet(
          isGeneratingImage: _isGeneratingImage,
          onShareText: () {
            Navigator.pop(context);
            _shareAsText(index);
          },
          onShareImage: () {
            Navigator.pop(context);
            _shareAsImage(index);
          },
        );
      },
    );
  }

  Future<void> _shareAsText(int index) async {
    final state = context.read<AthkarDetailsCubit>().state;
    if (state is! AthkarDetailsLoaded) return;

    final athkar = state.athkarCategory.details[index];
    final shareText = """
${athkar.arabicText ?? ''}

${athkar.languageArabicTranslatedText ?? ''}

${"عدد التكرار: ${athkar.repeat}"}
""";

    await SharePlus.instance.share(ShareParams(
      text: shareText,
    ));
  }

  Future<void> _shareAsImage(int index) async {
    if (mounted) {
      setState(() {
        _isGeneratingImage = true;
      });
    }

    try {
      final state = context.read<AthkarDetailsCubit>().state;
      if (state is! AthkarDetailsLoaded) return;

      final athkar = state.athkarCategory.details[index];
      final colorScheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      final GlobalKey shareKey = GlobalKey();
      OverlayEntry? overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: -2000,
          left: 0,
          child: RepaintBoundary(
            key: shareKey,
            child: Material(
              color: Colors.transparent,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF1A1A2E),
                              const Color(0xFF16213E),
                            ]
                          : [
                              colorScheme.primary,
                              colorScheme.primary.withValues(alpha: 0.8),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShareImageHeader(title: widget.title),
                      const SizedBox(height: 24),
                      ShareImageArabicText(
                        arabicText: athkar.arabicText ?? '',
                        isDark: isDark,
                        colorScheme: colorScheme,
                      ),
                      if (athkar.translatedText != null &&
                          athkar.translatedText!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: ShareImageTranslation(
                            translatedText: athkar.translatedText ?? '',
                            isDark: isDark,
                            colorScheme: colorScheme,
                          ),
                        ),
                      const SizedBox(height: 20),
                      ShareImageFooter(
                        repeatCount: athkar.repeat ?? 1,
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(overlayEntry);
      await Future.delayed(const Duration(milliseconds: 200));

      final RenderRepaintBoundary boundary =
          shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      overlayEntry.remove();

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'athkar_${widget.athkarId}_$index.png';
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: 'مشاركة الأذكار - ${widget.title}',
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل في مشاركة الصورة: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(top: 50, left: 20, right: 20),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingImage = false;
        });
      }
    }
  }
}
