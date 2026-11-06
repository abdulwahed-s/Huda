import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:huda/cubit/quran_player/player_bar_cubit.dart';
import 'package:huda/cubit/quran_player/quran_player_cubit.dart';
import 'package:huda/data/models/reciter_model.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/quran_player/player_bar_widget.dart';
import 'package:huda/presentation/widgets/reciter_surahs/reciter_recitation.dart';

/// One recitation as its own page: what Home's "continue listening" opens
/// (resuming at [initialSurahIndex] and [initialPositionMs]). Inside Quran
/// Audio, recitations open from the reciters screen instead. Brings its own
/// Lantern scope, since Home pushes it directly.
class ReciterSurahsScreen extends StatefulWidget {
  final Reciter reciter;
  final Moshaf moshaf;
  final List jsonData;
  final int? initialSurahIndex;
  final int initialPositionMs;

  const ReciterSurahsScreen({
    super.key,
    required this.reciter,
    required this.moshaf,
    required this.jsonData,
    this.initialSurahIndex,
    this.initialPositionMs = 0,
  });

  @override
  State<ReciterSurahsScreen> createState() => _ReciterSurahsScreenState();
}

class _ReciterSurahsScreenState extends State<ReciterSurahsScreen> {
  @override
  void initState() {
    super.initState();
    _autoPlayIfNeeded();
  }

  @override
  void deactivate() {
    FocusManager.instance.primaryFocus?.unfocus();
    super.deactivate();
  }

  void _autoPlayIfNeeded() {
    final index = widget.initialSurahIndex;
    if (index == null || index < 0) return;

    final numbers = widget.moshaf.surahList.toString().split(',');
    if (index >= numbers.length) return;

    final surahNumber = int.parse(numbers[index]);
    context.read<QuranPlayerCubit>().startPlaying(
      moshaf: widget.moshaf,
      reciter: widget.reciter,
      suraNumber: surahNumber,
      initialIndex: index,
      jsonData: widget.jsonData,
      initialPositionMs: widget.initialPositionMs,
    );
    context.read<PlayerBarCubit>().show();
  }

  @override
  Widget build(BuildContext context) {
    return HudaRevealScope(
      child: PlayerBarWidget.dock(
        child: HudaScaffold(
          title: widget.reciter.name.toString(),
          body: ReciterRecitationView(
            reciter: widget.reciter,
            moshaf: widget.moshaf,
            jsonData: widget.jsonData,
          ),
        ),
      ),
    );
  }
}
