import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/cubit/quran/quran_cubit.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:huda/core/utils/text_utils.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/presentation/widgets/quran_home/quran_app_bar.dart';
import 'package:huda/presentation/widgets/quran_home/quran_loading_state.dart';
import 'package:huda/presentation/widgets/quran_home/quran_empty_state.dart';
import 'package:huda/presentation/widgets/quran_home/quran_error_state.dart';
import 'package:huda/presentation/widgets/quran_home/surah_list.dart';
import 'package:huda/presentation/widgets/quran_home/search_result_list.dart';
import 'package:huda/cubit/surah/surah_cubit.dart';
import 'package:huda/data/models/search_result_model.dart';

class HomeQuran extends StatefulWidget {
  const HomeQuran({super.key});

  @override
  State<HomeQuran> createState() => _HomeQuranState();
}

class _HomeQuranState extends State<HomeQuran> with TickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  List<QuranModel> _filteredSurahs = [];
  List<QuranModel> _allSurahs = [];
  List<SearchResult> _searchResults = []; // New search results list
  List<dynamic>? _cachedSurahData; // For storing full surah content with ayahs
  Timer? _searchDebounce;
  bool _isSearching = false; // Track if we're in search mode

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadCachedSurahData();
  }

  // Load the cached surah data for content search
  Future<void> _loadCachedSurahData() async {
    try {
      // Try to get the preloaded data first
      if (SurahCubit.isDataPreloaded) {
        // Access the static cached data from SurahCubit
        final String response =
            await rootBundle.loadString('assets/json/surah_data_new.json');
        _cachedSurahData = json.decode(response);
      }
    } catch (e) {
      // If loading fails, search will work without content search
      debugPrint('Failed to load cached surah data for search: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // Debounced search to improve performance
  void _debouncedSearch(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _filterSurahs(query);
    });
  }

  void _filterSurahs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSurahs = List.from(_allSurahs);
        _searchResults = [];
        _isSearching = false;
      } else {
        _isSearching = true;
        List<SearchResult> results = [];
        List<AyahSearchResult> ayahResults = [];

        // First, find surahs that match metadata (names, numbers)
        List<QuranModel> matchingSurahs = _allSurahs.where((surah) {
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

        // Add matching surahs to results
        for (var surah in matchingSurahs) {
          results.add(SearchResult.surah(surah));
        }

        // Then, search within ayah content if cached data is available
        if (_cachedSurahData != null) {
          int maxAyahResults = 20; // Limit ayah results to prevent overwhelming
          int currentAyahCount = 0;

          for (var surah in _allSurahs) {
            if (currentAyahCount >= maxAyahResults) break;

            // Skip if this surah already matches metadata
            bool alreadyMatched =
                matchingSurahs.any((s) => s.number == surah.number);
            if (alreadyMatched) continue;

            try {
              final surahData = _cachedSurahData!
                  .firstWhere((s) => s['number'] == surah.number);

              if (surahData['ayahs'] != null) {
                final ayahs = surahData['ayahs'] as List;

                // Search in ayah text
                for (var ayah in ayahs) {
                  if (currentAyahCount >= maxAyahResults) break;

                  final ayahText = ayah['text'] as String?;
                  if (ayahText != null) {
                    bool matches = false;

                    // Search in original Arabic text
                    if (TextUtils.removeDiacriticsAndNormalize(ayahText)
                        .contains(
                            TextUtils.removeDiacriticsAndNormalize(query))) {
                      matches = true;
                    }
                    // Also search in the raw text (for exact matches)
                    else if (ayahText
                        .toLowerCase()
                        .contains(query.toLowerCase())) {
                      matches = true;
                    }

                    if (matches) {
                      ayahResults.add(AyahSearchResult(
                        surahNumber: surah.number!,
                        surahName: surah.name!,
                        surahEnglishName: surah.englishName!,
                        ayahNumber: ayah['numberInSurah'] ?? 0,
                        ayahText: ayahText,
                        highlightedText: ayahText,
                      ));
                      currentAyahCount++;
                    }
                  }
                }
              }
            } catch (e) {
              debugPrint('Error searching in surah ${surah.number}: $e');
            }
          }
        }

        // Add divider and ayah results if any found
        if (ayahResults.isNotEmpty) {
          if (results.isNotEmpty) {
            results.add(SearchResult.divider());
          }
          for (var ayahResult in ayahResults) {
            results.add(SearchResult.ayah(ayahResult));
          }
        }

        _searchResults = results;
        _filteredSurahs = matchingSurahs; // For fallback compatibility
      }
    });
  }

  void _navigateToSurah(QuranModel surah) {
    Navigator.pushNamed(context, AppRoute.surahScreen, arguments: {
      'surahInfo': surah,
      'shouldRestorePosition': false,
    });
  }

  void _navigateToAyah(AyahSearchResult ayahResult) {
    // Find the surah model for navigation
    final surah =
        _allSurahs.firstWhere((s) => s.number == ayahResult.surahNumber);

    Navigator.pushNamed(context, AppRoute.surahScreen, arguments: {
      'surahInfo': surah,
      'shouldRestorePosition': false,
      'scrollToAyah': ayahResult.ayahNumber,
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuranCubit()..loadQuran(),
      child: Scaffold(
        appBar: QuranAppBar(
          searchController: _searchController,
          onSearchChanged: _debouncedSearch,
          onSearchClear: () {
            _searchController.clear();
            _filterSurahs('');
            setState(() {
              _isSearching = false;
              _searchResults = [];
            });
          },
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      context.primaryColor.withValues(alpha: 0.1),
                      Theme.of(context).scaffoldBackgroundColor,
                    ]
                  : [
                      context.primaryColor.withValues(alpha: 0.05),
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

                  return _isSearching && _searchResults.isEmpty
                      ? const QuranEmptyState()
                      : _isSearching
                          ? SearchResultList(
                              searchResults: _searchResults,
                              animationController: _animationController,
                              onSurahTap: _navigateToSurah,
                              onAyahTap: _navigateToAyah,
                            )
                          : _filteredSurahs.isEmpty
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
