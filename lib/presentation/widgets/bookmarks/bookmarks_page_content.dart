import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/bookmark_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/cubit/audio/audio_cubit.dart';
import 'package:huda/cubit/bookmark/bookmarks_cubit.dart';
import 'package:huda/cubit/tafsir/tafsir_cubit.dart';
import 'package:huda/cubit/translation/translation_cubit.dart';
import 'package:huda/data/api/audio_services.dart';
import 'package:huda/data/api/tafsir_services.dart';
import 'package:huda/data/api/translation_services.dart';
import 'package:huda/data/models/bookmark_model.dart';
import 'package:huda/data/models/quran_model.dart';
import 'package:huda/data/repository/audio_repository.dart';
import 'package:huda/data/repository/tafsir_repository.dart';
import 'package:huda/data/repository/translation_repository.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/screens/surah_screen.dart';
import 'package:huda/presentation/widgets/bookmarks/bookmarks_app_bar.dart';
import 'package:huda/presentation/widgets/bookmarks/bookmarks_body.dart';
import 'package:huda/presentation/widgets/bookmarks/clear_all_confirmation_dialog.dart';
import 'package:huda/presentation/widgets/bookmarks/delete_confirmation_dialog.dart';
import 'package:huda/presentation/widgets/bookmarks/edit_note_dialog.dart';
import 'package:huda/presentation/widgets/bookmarks/navigate_confirmation_dialog.dart';
import 'package:huda/presentation/widgets/bookmarks/options_menu.dart';

class BookmarksPageContent extends StatefulWidget {
  const BookmarksPageContent({super.key});

  @override
  State<BookmarksPageContent> createState() => _BookmarksPageContentState();
}

class _BookmarksPageContentState extends State<BookmarksPageContent>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  BookmarkType? _currentFilter;
  String _searchQuery = '';
  StreamSubscription<BookmarkChange>? _bookmarkChangesSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _setupBookmarkChangeListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _bookmarkChangesSubscription?.cancel();
    super.dispose();
  }

  void _setupBookmarkChangeListener() {
    final bookmarkService = getIt<BookmarkService>();
    _bookmarkChangesSubscription =
        bookmarkService.bookmarkChanges.listen((change) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  change.action == BookmarkChangeAction.added
                      ? Icons.bookmark_add
                      : change.action == BookmarkChangeAction.removed
                          ? Icons.bookmark_remove
                          : Icons.edit,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  change.action == BookmarkChangeAction.added
                      ? AppLocalizations.of(context)!.bookmarkAdded
                      : change.action == BookmarkChangeAction.removed
                          ? AppLocalizations.of(context)!.bookmarkRemoved
                          : AppLocalizations.of(context)!.bookmarkUpdated,
                ),
              ],
            ),
            backgroundColor: change.action == BookmarkChangeAction.removed
                ? Colors.red
                : Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
            ),
          ),
        );
        context.read<BookmarksCubit>().loadBookmarks();
      }
    });
  }

  void _onTabChanged() {
    final filterTypes = [
      null,
      BookmarkType.bookmark,
      BookmarkType.note,
      BookmarkType.star
    ];
    final newFilter = filterTypes[_tabController.index];

    if (_currentFilter != newFilter) {
      _currentFilter = newFilter;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: BookmarksAppBar(
        isDark: isDark,
        searchController: _searchController,
        onSearchChanged: (query) => setState(() => _searchQuery = query),
        onOptionsPressed: _showOptionsMenu,
        tabController: _tabController,
      ),
      body: BookmarksBody(
        isDark: isDark,
        searchQuery: _searchQuery,
        currentFilter: _currentFilter,
        tabController: _tabController,
        onNavigateToAyah: _navigateToAyah,
        onHandleBookmarkAction: _handleBookmarkAction,
      ),
    );
  }

  void _navigateToAyah(BookmarkModel bookmark) {
    final surahInfo = QuranModel(
      number: bookmark.surahNumber,
      name: bookmark.surahName,
      englishName: bookmark.surahName,
      englishNameTranslation: bookmark.surahName,
      numberOfAyahs: 286,
      revelationType: 'Meccan',
    );

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
                      TafsirCubit(context.read<TafsirRepository>())),
              BlocProvider<TranslationCubit>(
                  create: (context) =>
                      TranslationCubit(context.read<TranslationRepository>())),
            ],
            child: SurahScreen(
              surahInfo: surahInfo,
              scrollToAyah: bookmark.ayahNumber,
            ),
          ),
        ),
      ),
    );
  }

  void _handleBookmarkAction(String action, BookmarkModel bookmark) {
    switch (action) {
      case 'edit':
        _showEditNoteDialog(bookmark);
        break;
      case 'navigate':
        _showNavigateConfirmation(bookmark);
        break;
      case 'delete':
        _showDeleteConfirmation(bookmark);
        break;
    }
  }

  void _showEditNoteDialog(BookmarkModel bookmark) {
    final noteController = TextEditingController(text: bookmark.note ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<BookmarksCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => EditNoteDialog(
        bookmark: bookmark,
        noteController: noteController,
        isDark: isDark,
        onSave: () {
          cubit.updateBookmarkNote(
            bookmark.surahNumber,
            bookmark.ayahNumber,
            noteController.text.trim(),
          );
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

  void _showNavigateConfirmation(BookmarkModel bookmark) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => NavigateConfirmationDialog(
        bookmark: bookmark,
        isDark: isDark,
        onConfirm: () {
          Navigator.pop(dialogContext);
          _navigateToAyah(bookmark);
        },
      ),
    );
  }

  void _showDeleteConfirmation(BookmarkModel bookmark) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<BookmarksCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => DeleteConfirmationDialog(
        bookmark: bookmark,
        isDark: isDark,
        onDelete: () {
          cubit.removeBookmark(
            bookmark.surahNumber,
            bookmark.ayahNumber,
            bookmark.type,
          );
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

  void _showOptionsMenu() {
    final cubit = context.read<BookmarksCubit>();

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => OptionsMenu(
        onRefresh: () {
          Navigator.pop(sheetContext);
          cubit.loadBookmarks();
        },
        onClearAll: () {
          Navigator.pop(sheetContext);
          _showClearAllConfirmation();
        },
      ),
    );
  }

  void _showClearAllConfirmation() {
    final cubit = context.read<BookmarksCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => ClearAllConfirmationDialog(
        onClearAll: () {
          Navigator.pop(dialogContext);
          cubit.clearAllBookmarks();
        },
      ),
    );
  }
}
