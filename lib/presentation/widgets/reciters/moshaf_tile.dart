import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:huda/cubit/quran_player/quran_player_cubit.dart';
import 'package:huda/cubit/quran_player/quran_player_state.dart';
import 'package:huda/cubit/quran_player/player_bar_cubit.dart';
import 'package:huda/cubit/quran_player/download_progress_cubit.dart';
import 'package:huda/data/models/reciter_model.dart';
import 'package:huda/presentation/screens/reciter_surahs_screen.dart';

class MoshafTile extends StatelessWidget {
  final Reciter reciter;
  final Moshaf moshaf;
  final List suwar;
  final bool isDark;
  final ThemeData theme;
  final bool isOffline;

  const MoshafTile({
    super.key,
    required this.reciter,
    required this.moshaf,
    required this.suwar,
    required this.isDark,
    required this.theme,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: context.read<QuranPlayerCubit>()),
                    BlocProvider.value(value: context.read<PlayerBarCubit>()),
                    BlocProvider.value(
                        value: context.read<DownloadProgressCubit>()),
                  ],
                  child: ReciterSurahsScreen(
                    reciter: reciter,
                    moshaf: moshaf,
                    jsonData: suwar,
                  ),
                ),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: isDark ? 0.25 : 0.45),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32.r,
                  height: 32.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.55),
                  ),
                  child: Icon(
                    Icons.library_music_rounded,
                    size: 15.sp,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        moshaf.name.toString(),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      BlocBuilder<DownloadProgressCubit, DownloadProgressState>(
                        builder: (context, dlState) {
                          final batch =
                              dlState.getBatchProgress(reciter.id, moshaf.id);
                          if (batch == null) return const SizedBox.shrink();
                          return Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4.r),
                                  child: LinearProgressIndicator(
                                    value: batch.fraction,
                                    minHeight: 3.h,
                                    backgroundColor: theme
                                        .colorScheme.surfaceContainerHighest,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '${batch.completed}/${batch.total}',
                                  style: TextStyle(
                                      fontSize: 10.sp,
                                      color: theme.colorScheme.outline),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                BlocBuilder<QuranPlayerCubit, QuranPlayerState>(
                  builder: (context, playerState) {
                    final isLoadingThis = playerState is QuranPlayerLoading &&
                        playerState.reciterId == reciter.id &&
                        playerState.moshafId == moshaf.id;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: isLoadingThis
                          ? SizedBox(
                              key: const ValueKey('loading'),
                              width: 26.sp,
                              height: 26.sp,
                              child: Padding(
                                padding: EdgeInsets.all(2.r),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            )
                          : IconButton(
                              key: const ValueKey('play'),
                              icon: Icon(
                                Icons.play_circle_rounded,
                                color: theme.colorScheme.primary,
                                size: 26.sp,
                              ),
                              onPressed: () {
                                context.read<QuranPlayerCubit>().startPlaying(
                                      moshaf: moshaf,
                                      reciter: reciter,
                                      suraNumber: -1,
                                      initialIndex: 0,
                                      jsonData: suwar,
                                    );
                                context.read<PlayerBarCubit>().show();
                              },
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(
                                  minWidth: 32.w, minHeight: 32.w),
                              visualDensity: VisualDensity.compact,
                            ),
                    );
                  },
                ),
                if (!isOffline) ...[
                  SizedBox(width: 2.w),
                  BlocBuilder<DownloadProgressCubit, DownloadProgressState>(
                    builder: (context, dlState) {
                      final batch =
                          dlState.getBatchProgress(reciter.id, moshaf.id);
                      final isDownloading = batch != null && !batch.isDone;
                      return IconButton(
                        icon: isDownloading
                            ? SizedBox(
                                width: 20.sp,
                                height: 20.sp,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: batch.fraction,
                                  color: theme.colorScheme.secondary,
                                ),
                              )
                            : Icon(
                                Icons.download_rounded,
                                color: theme.colorScheme.secondary,
                                size: 22.sp,
                              ),
                        onPressed: isDownloading
                            ? null
                            : () {
                                context
                                    .read<QuranPlayerCubit>()
                                    .downloadAllSurahs(
                                      reciter: reciter,
                                      moshaf: moshaf,
                                    );
                              },
                        padding: EdgeInsets.zero,
                        constraints:
                            BoxConstraints(minWidth: 32.w, minHeight: 32.w),
                        visualDensity: VisualDensity.compact,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
