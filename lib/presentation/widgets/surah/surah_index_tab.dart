import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/surah/surah_index_grid_tile.dart';
import 'package:huda/presentation/widgets/surah/surah_index_header.dart';
import 'package:huda/presentation/widgets/surah/surah_search_empty_state.dart';
import 'package:huda/presentation/widgets/surah/surah_search_field.dart';

class SurahIndexTab extends StatefulWidget {
  final bool isDark;
  final Color accent;
  final List<int> visibleSurahs;
  final ScrollController scrollController;

  final ValueChanged<int> onSurahSelected;

  final VoidCallback onCurrentSurahTapped;

  const SurahIndexTab({
    super.key,
    required this.isDark,
    required this.accent,
    required this.visibleSurahs,
    required this.scrollController,
    required this.onSurahSelected,
    required this.onCurrentSurahTapped,
  });

  @override
  State<SurahIndexTab> createState() => _SurahIndexTabState();
}

class _SurahIndexTabState extends State<SurahIndexTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final allSurahs = List.generate(114, (i) => i + 1);
    final filteredSurahs = _searchQuery.isEmpty
        ? allSurahs
        : allSurahs.where((n) {
            final q = _searchQuery;
            return quran.getSurahNameArabic(n).contains(q) ||
                quran.getSurahName(n).toLowerCase().contains(q.toLowerCase()) ||
                n.toString() == q;
          }).toList();

    final currentSurahName = widget.visibleSurahs.isNotEmpty
        ? quran.getSurahNameArabic(widget.visibleSurahs.first)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurahIndexHeader(
          isDark: widget.isDark,
          accent: widget.accent,
          title: l.surahsLabel,
          subtitle: l.surahIndexSubtitle,
          currentSurahArabicName: currentSurahName,
        ),
        SizedBox(height: 10.h),
        SurahSearchField(
          controller: _searchController,
          searchQuery: _searchQuery,
          hintText: l.searchSurahHint,
          isDark: widget.isDark,
          accent: widget.accent,
          onChanged: (v) => setState(() => _searchQuery = v),
          onClear: () {
            _searchController.clear();
            setState(() => _searchQuery = '');
          },
        ),
        SizedBox(height: 10.h),
        if (filteredSurahs.isEmpty)
          Expanded(
            child: SurahSearchEmptyState(
              isDark: widget.isDark,
              message: l.surahNoResults,
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 16.h),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
                childAspectRatio: 2.5,
              ),
              itemCount: filteredSurahs.length,
              itemBuilder: (gridCtx, index) {
                final surahNumber = filteredSurahs[index];
                final isSelected = widget.visibleSurahs.contains(surahNumber);
                final isMakki =
                    quran.getPlaceOfRevelation(surahNumber) == 'Makkah';
                final verseCount = quran.getVerseCount(surahNumber);

                return SurahIndexGridTile(
                  surahNumber: surahNumber,
                  arabicName: quran.getSurahNameArabic(surahNumber),
                  isMakki: isMakki,
                  revelationLabel: isMakki ? l.meccan : l.medinan,
                  verseCountLabel: l.verseCountLabel(verseCount),
                  isSelected: isSelected,
                  isDark: widget.isDark,
                  accent: widget.accent,
                  onTap: () {
                    if (isSelected) {
                      widget.onCurrentSurahTapped();
                    } else {
                      widget.onSurahSelected(surahNumber);
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
