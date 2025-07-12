import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/quran/quran_cubit.dart';
import 'package:huda/cubit/audio/audio_cubit.dart';
import 'package:huda/cubit/tafsir/tafsir_cubit.dart';
import 'package:huda/cubit/translation/translation_cubit.dart';
import 'package:huda/data/api/audio_services.dart';
import 'package:huda/data/api/tafsir_services.dart';
import 'package:huda/data/api/translation_services.dart';
import 'package:huda/data/repository/audio_repository.dart';
import 'package:huda/data/repository/tafsir_repository.dart';
import 'package:huda/data/repository/translation_repository.dart';
import 'package:huda/presentation/screens/surah_screen.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:huda/core/utils/text_utils.dart';
import 'package:huda/presentation/widgets/quran_app_bar.dart';
import 'package:huda/presentation/widgets/quran_loading_state.dart';
import 'package:huda/presentation/widgets/quran_empty_state.dart';
import 'package:huda/presentation/widgets/quran_error_state.dart';
import 'package:huda/presentation/widgets/surah_list.dart';

class HomeQuran extends StatefulWidget {
  const HomeQuran({super.key});

  @override
  State<HomeQuran> createState() => _HomeQuranState();
}

class _HomeQuranState extends State<HomeQuran> with TickerProviderStateMixin {
  late AnimationController _animationController;
  TextEditingController _searchController = TextEditingController();
  List<QuranModel> _filteredSurahs = [];
  List<QuranModel> _allSurahs = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterSurahs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSurahs = List.from(_allSurahs);
      } else {
        _filteredSurahs = _allSurahs.where((surah) {
          return surah.englishName!
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              surah.englishNameTranslation!
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              surah.number.toString().contains(query) ||
              TextUtils.removeDiacriticsAndNormalize(surah.name.toString())
                  .contains(TextUtils.removeDiacriticsAndNormalize(query));
        }).toList();
      }
    });
  }

  void _navigateToSurah(QuranModel surah) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AudioRepository>(
              create: (_) => AudioRepository(audioServices: AudioServices()),
            ),
            RepositoryProvider<TafsirRepository>(
              create: (_) => TafsirRepository(tafsirServices: TafsirServices()),
            ),
            RepositoryProvider<TranslationRepository>(
              create: (_) => TranslationRepository(
                  translationServices: TranslationServices()),
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AudioCubit>(
                create: (context) =>
                    AudioCubit(context.read<AudioRepository>()),
              ),
              BlocProvider<TafsirCubit>(
                create: (context) =>
                    TafsirCubit(context.read<TafsirRepository>()),
              ),
              BlocProvider<TranslationCubit>(
                create: (context) =>
                    TranslationCubit(context.read<TranslationRepository>()),
              ),
            ],
            child: SurahScreen(surahInfo: surah),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuranCubit()..loadQuran(),
      child: Scaffold(
        appBar: QuranAppBar(
          searchController: _searchController,
          onSearchChanged: _filterSurahs,
          onSearchClear: () {
            _searchController.clear();
            _filterSurahs('');
          },
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color.fromARGB(255, 103, 43, 93).withOpacity(0.05),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: BlocBuilder<QuranCubit, QuranState>(
              builder: (context, state) {
                if (state is QuranLoading) {
                  return const QuranLoadingState();
                } else if (state is QuranLoaded) {
                  if (_allSurahs.isEmpty) {
                    _allSurahs = state.surahs;
                    _filteredSurahs = List.from(_allSurahs);
                    _animationController.forward();
                  }

                  return _filteredSurahs.isEmpty
                      ? const QuranEmptyState()
                      : SurahList(
                          surahs: _filteredSurahs,
                          animationController: _animationController,
                          onSurahTap: _navigateToSurah,
                        );
                } else if (state is QuranError) {
                  return QuranErrorState(
                    message: state.message,
                    onRetry: () => context.read<QuranCubit>().loadQuran(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }
}
