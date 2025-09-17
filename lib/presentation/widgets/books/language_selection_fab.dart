import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/books/languages_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/books/language_selection_sheet.dart';

class LanguageSelectionFab extends StatelessWidget {
  final Animation<double> animation;
  final String? selectedLanguage;
  final ValueChanged<String?> onLanguageSelected;

  const LanguageSelectionFab({
    super.key,
    required this.animation,
    required this.selectedLanguage,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animation,
      child: BlocBuilder<LanguagesCubit, LanguagesState>(
        builder: (context, state) {
          return FloatingActionButton.extended(
            onPressed: state is LanguagesLoaded
                ? () => _showLanguageBottomSheet(context, state.languages)
                : null,
            icon: const Icon(Icons.language_rounded),
            label: Text(
              selectedLanguage?.toUpperCase() ??
                  AppLocalizations.of(context)!.all,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: context.primaryColor,
            foregroundColor: Colors.white,
            elevation: 8,
          );
        },
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context, List languages) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LanguageSelectionSheet(
        languages: languages,
        onLanguageSelected: onLanguageSelected,
      ),
    );
  }
}
