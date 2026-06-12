import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/utils/responsive_utils.dart';
import 'package:huda/core/services/audio_progress_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/cubit/audios/audio_languages_cubit.dart';
import 'package:huda/cubit/audios/audios_cubit.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/data/models/audios_response.dart';
import 'package:huda/presentation/widgets/audio/audio_card.dart';
import 'package:huda/presentation/widgets/audio/continue_listening_card.dart';
import 'package:huda/presentation/widgets/books/pagination_section.dart';
import 'package:huda/presentation/widgets/books/selected_language_chip.dart';

class AudiosLoadedWidget extends StatelessWidget {
  final AudiosLoaded state;
  final bool isDark;
  final String? selectedLanguage;
  final ValueChanged<String?> onLanguageChanged;

  const AudiosLoadedWidget({
    super.key,
    required this.state,
    required this.isDark,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  String? _resolveLanguageName(BuildContext context, String code) {
    final langState = context.watch<AudioLanguagesCubit>().state;
    if (langState is AudioLanguagesLoaded) {
      for (final lang in langState.languages) {
        if (lang.langsymbol == code) return lang.langtranslation;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lastPlayed = getIt<AudioProgressService>().getLastPlayed();
    final columns = context.responsive<int>(mobile: 2, tablet: 3, desktop: 4);

    return SliverMainAxisGroup(
      slivers: [
        if (lastPlayed != null && lastPlayed.title != null)
          SliverToBoxAdapter(
            child: ContinueListeningCard(
              progress: lastPlayed,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoute.audioDetail,
                  arguments: {
                    'audioId': lastPlayed.audiobookId.toString(),
                    'language': context
                        .read<LocalizationCubit>()
                        .state
                        .locale
                        .languageCode,
                    'title': lastPlayed.title,
                  },
                );
              },
            ),
          ),
        if (selectedLanguage != null)
          SelectedLanguageChip(
            language: selectedLanguage!,
            languageName: _resolveLanguageName(context, selectedLanguage!),
            onClear: () => onLanguageChanged(null),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _MasonryGrid(
              items: state.audiosResponse.data,
              columns: columns,
              isDark: isDark,
              spacing: 16.w,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: 32.h),
            child: PaginationSection(
              currentPage: state.audiosResponse.links.currentPage,
              totalPages: state.audiosResponse.links.pagesNumber,
              isDark: isDark,
              onPageChanged: (page) {
                context.read<AudiosCubit>().fetchAudios(
                      selectedLanguage ?? 'showall',
                      page,
                      context
                          .read<LocalizationCubit>()
                          .state
                          .locale
                          .languageCode,
                    );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MasonryGrid extends StatelessWidget {
  final List<AudioItem> items;
  final int columns;
  final bool isDark;
  final double spacing;

  const _MasonryGrid({
    required this.items,
    required this.columns,
    required this.isDark,
    required this.spacing,
  });

  List<List<AudioItem>> _distribute() {
    final cols = List.generate(columns, (_) => <AudioItem>[]);
    for (int i = 0; i < items.length; i++) {
      cols[i % columns].add(items[i]);
    }
    return cols;
  }

  @override
  Widget build(BuildContext context) {
    final cols = _distribute();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int c = 0; c < columns; c++) ...[
          if (c > 0) SizedBox(width: spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final audio in cols[c])
                  Padding(
                    padding: EdgeInsets.only(bottom: spacing),
                    child: AudioCard(
                      audio: audio,
                      isDark: isDark,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
