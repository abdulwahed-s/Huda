import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/surah/quran_page_view.dart';
import 'package:huda/cubit/surah/surah_cubit.dart';
import 'package:huda/cubit/audio/audio_cubit.dart';
import 'package:huda/cubit/tafsir/tafsir_cubit.dart';
import 'package:huda/cubit/translation/translation_cubit.dart';
import 'package:huda/cubit/bookmark/bookmarks_cubit.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:huda/data/repository/tafsir_repository.dart';
import 'package:huda/data/repository/translation_repository.dart';
import 'package:huda/core/services/bookmark_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/surah/surah_loading_state_widget.dart';
import 'package:huda/cubit/memorization/memorization_cubit.dart';

class SurahScreen extends StatelessWidget {
  final QuranModel surahInfo;
  final int? scrollToAyah;
  final double? ayahPosition;
  final bool shouldRestorePosition;
  final bool isBookmarkVisit;

  const SurahScreen({
    super.key,
    required this.surahInfo,
    this.scrollToAyah,
    this.ayahPosition,
    this.shouldRestorePosition = false,
    this.isBookmarkVisit = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {},
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => SurahCubit()..loadSurah(surahInfo.number!),
          ),
          BlocProvider(
            create: (_) => context.read<AudioCubit>()
              ..fetchAudioInfo(surahInfo.number.toString()),
          ),
          BlocProvider(
            create: (_) => TafsirCubit(context.read<TafsirRepository>())
              ..fetchTafsirInfo(),
          ),
          BlocProvider(
            create: (_) =>
                TranslationCubit(context.read<TranslationRepository>())
                  ..fetchTranslationInfo(),
          ),
          BlocProvider(
            create: (_) => BookmarksCubit(
              bookmarkService: getIt<BookmarkService>(),
            ),
          ),
          BlocProvider(
            create: (_) => MemorizationCubit(),
          ),
        ],
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(90.h),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          context.darkGradientStart,
                          context.darkGradientMid,
                          context.darkGradientEnd,
                        ]
                      : [
                          context.primaryColor,
                          context.primaryVariantColor,
                          context.primaryLightColor,
                        ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              surahInfo.name ?? '',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1.h),
                                    blurRadius: 2.r,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 5.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    'Surah ${surahInfo.number}',
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                if (surahInfo.englishName != null)
                                  Flexible(
                                    child: Text(
                                      surahInfo.englishName!,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: BlocBuilder<SurahCubit, SurahState>(
            builder: (context, state) {
              if (state is SurahLoading) {
                return const SurahLoadingStateWidget();
              } else if (state is SurahLoaded) {
                return QuranPageView(
                  surah: state.surah,
                  surahNumber: surahInfo.number!,
                  scrollToAyah: scrollToAyah,
                  ayahPosition: ayahPosition,
                  shouldRestorePosition: shouldRestorePosition,
                  isBookmarkVisit: isBookmarkVisit,
                );
              } else if (state is SurahError) {
                return Center(
                  child: Text(AppLocalizations.of(context)!
                      .unknownError(state.message)),
                );
              } else {
                return Center(
                  child: Text(AppLocalizations.of(context)!.unknownState),
                );
              }
            },
          ),
          floatingActionButton:
              BlocBuilder<MemorizationCubit, MemorizationState>(
            builder: (context, state) {
              final isMemorizationMode =
                  state is MemorizationModeUpdated && state.isMemorizationMode;

              if (!isMemorizationMode) return const SizedBox.shrink();

              return FloatingActionButton.extended(
                onPressed: () {
                  context
                      .read<MemorizationCubit>()
                      .toggleMemorizationMode([], 0);
                },
                backgroundColor: Colors.red,
                icon: const Icon(Icons.stop_rounded, color: Colors.white),
                label: Text(
                  AppLocalizations.of(context)!.stopMemorization,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
