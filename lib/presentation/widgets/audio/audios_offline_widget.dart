import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/audios/audios_cubit.dart';
import 'package:huda/presentation/widgets/audio/offline_audio_card.dart';

class AudiosOfflineWidget extends StatelessWidget {
  final AudiosOfflineLoaded state;
  final bool isDark;

  const AudiosOfflineWidget({
    super.key,
    required this.state,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => OfflineAudioCard(
            audiobook: state.offlineAudios[index],
            isDark: isDark,
          ),
          childCount: state.offlineAudios.length,
        ),
      ),
    );
  }
}
