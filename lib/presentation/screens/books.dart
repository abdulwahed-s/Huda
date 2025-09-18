import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/books/books_cubit.dart';
import 'package:huda/cubit/books/languages_cubit.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/presentation/widgets/books/books_app_bar.dart';
import 'package:huda/presentation/widgets/books/books_error_widget.dart';
import 'package:huda/presentation/widgets/books/books_loaded_widget.dart';
import 'package:huda/presentation/widgets/books/books_loading_widget.dart';
import 'package:huda/presentation/widgets/books/books_offline_widget.dart';
import 'package:huda/presentation/widgets/books/language_selection_fab.dart';
import 'package:huda/presentation/widgets/books/offline_empty_state_widget.dart';
import 'package:huda/presentation/widgets/books/offline_state_widget.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen>
    with TickerProviderStateMixin {
  String? selectedLanguage;
  final ScrollController _booksScrollController = ScrollController();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupAnimations();
  }

  void _loadInitialData() {
    final languageCode =
        context.read<LocalizationCubit>().state.locale.languageCode;
    context.read<BooksCubit>().fetchBooks('showall', 1, languageCode);
    context.read<LanguagesCubit>().fetchLanguages(languageCode);
  }

  void _setupAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _booksScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: BooksAppBar(isDark: isDark),
      body: BlocBuilder<BooksCubit, BooksState>(
        builder: (context, state) {
          return _buildContentForState(context, state, isDark);
        },
      ),
      floatingActionButton: LanguageSelectionFab(
        animation: _fabAnimation,
        selectedLanguage: selectedLanguage,
        onLanguageSelected: _handleLanguageChange,
      ),
    );
  }

  Widget _buildContentForState(
      BuildContext context, BooksState state, bool isDark) {
    if (state is BooksLoading || state is BooksOfflineLoading) {
      return BooksLoadingWidget(isDark: isDark);
    } else if (state is BooksLoaded) {
      return BooksLoadedWidget(
        state: state,
        isDark: isDark,
        selectedLanguage: selectedLanguage,
        onLanguageChanged: _handleLanguageChange,
        scrollController: _booksScrollController,
      );
    } else if (state is BooksOfflineLoaded) {
      return BooksOfflineWidget(
        state: state,
        isDark: isDark,
        onRetry: _retryLoading,
      );
    } else if (state is BooksOfflineEmpty) {
      return OfflineEmptyStateWidget(isDark: isDark, onRetry: _retryLoading);
    } else if (state is BooksOffline) {
      return OfflineStateWidget(isDark: isDark, onRetry: _retryLoading);
    } else if (state is BooksError) {
      return BooksErrorWidget(
        message: state.message,
        isDark: isDark,
        onRetry: _retryLoading,
      );
    }
    return const SizedBox.shrink();
  }

  void _handleLanguageChange(String? language) {
    setState(() {
      selectedLanguage = language;
    });
    final languageCode =
        context.read<LocalizationCubit>().state.locale.languageCode;
    context
        .read<BooksCubit>()
        .fetchBooks(language ?? 'showall', 1, languageCode);
  }

  void _retryLoading() {
    final languageCode =
        context.read<LocalizationCubit>().state.locale.languageCode;
    context
        .read<BooksCubit>()
        .fetchBooks(selectedLanguage ?? 'showall', 1, languageCode);
    context.read<LanguagesCubit>().fetchLanguages(languageCode);
  }
}
