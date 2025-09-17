import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/books/language_search_field.dart';
import 'package:huda/presentation/widgets/books/language_selection_list.dart';

class LanguageSelectionSheet extends StatefulWidget {
  final List languages;
  final ValueChanged<String?> onLanguageSelected;

  const LanguageSelectionSheet({
    super.key,
    required this.languages,
    required this.onLanguageSelected,
  });

  @override
  State<LanguageSelectionSheet> createState() => _LanguageSelectionSheetState();
}

class _LanguageSelectionSheetState extends State<LanguageSelectionSheet> {
  late List<MapEntry<String, dynamic>> _filteredLanguages;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredLanguages = List<MapEntry<String, dynamic>>.from(
      widget.languages.map((lang) => MapEntry(lang.langsymbol as String, lang)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? context.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.chooseLanguage,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? context.darkText : context.lightText,
                    fontFamily: 'Amiri',
                  ),
                ),
                SizedBox(height: 16.h),
                LanguageSearchField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _filteredLanguages = List<MapEntry<String, dynamic>>.from(
                        widget.languages
                            .where((lang) =>
                                (lang.langtranslation?.toLowerCase() ?? '')
                                    .contains(value.toLowerCase()) ||
                                (lang.langsymbol?.toLowerCase() ?? '')
                                    .contains(value.toLowerCase()))
                            .map((lang) =>
                                MapEntry(lang.langsymbol as String, lang)),
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: LanguageSelectionList(
              languages: _filteredLanguages,
              onLanguageSelected: (lang) {
                widget.onLanguageSelected(lang.langsymbol);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
