import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/bookmark/bookmarks_cubit.dart';
import 'package:huda/data/models/bookmark_model.dart';
import 'package:huda/core/services/bookmark_service.dart';
import 'package:huda/core/services/service_locator.dart';

class BookmarkIndicator extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final double size;

  const BookmarkIndicator({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    this.size = 16.0,
  });

  @override
  State<BookmarkIndicator> createState() => _BookmarkIndicatorState();
}

class _BookmarkIndicatorState extends State<BookmarkIndicator> {
  bool _hasBookmark = false;
  bool _hasNote = false;
  bool _hasStar = false;
  Color? _bookmarkColor;

  BookmarksCubit? _localBookmarksCubit;
  BookmarksCubit get _bookmarksCubit {
    try {
      return context.read<BookmarksCubit>();
    } catch (e) {
      _localBookmarksCubit ??= BookmarksCubit(
        bookmarkService: getIt<BookmarkService>(),
      );
      return _localBookmarksCubit!;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  @override
  void dispose() {
    _localBookmarksCubit?.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(BookmarkIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahNumber != widget.surahNumber ||
        oldWidget.ayahNumber != widget.ayahNumber) {
      _checkBookmarkStatus();
    }
  }

  Future<void> _checkBookmarkStatus() async {
    if (!mounted) return;

    final bookmarksCubit = _bookmarksCubit;

    try {
      final hasBookmark = await bookmarksCubit.hasBookmarkType(
        widget.surahNumber,
        widget.ayahNumber,
        BookmarkType.bookmark,
      );

      final hasNote = await bookmarksCubit.hasBookmarkType(
        widget.surahNumber,
        widget.ayahNumber,
        BookmarkType.note,
      );

      final hasStar = await bookmarksCubit.hasBookmarkType(
        widget.surahNumber,
        widget.ayahNumber,
        BookmarkType.star,
      );

      Color? bookmarkColor;
      if (hasBookmark) {
        final bookmark = await bookmarksCubit.getBookmark(
          widget.surahNumber,
          widget.ayahNumber,
          BookmarkType.bookmark,
        );
        bookmarkColor = bookmark?.color;
      }

      if (mounted) {
        setState(() {
          _hasBookmark = hasBookmark;
          _hasNote = hasNote;
          _hasStar = hasStar;
          _bookmarkColor = bookmarkColor;
        });
      }
    } catch (e) {
      debugPrint('Error checking bookmark status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasBookmark && !_hasNote && !_hasStar) {
      return const SizedBox.shrink();
    }

    Widget child = Wrap(
      spacing: 2.0,
      children: [
        if (_hasBookmark)
          Icon(
            Icons.bookmark,
            size: widget.size,
            color: _bookmarkColor ?? context.primaryColor,
          ),
        if (_hasNote)
          Icon(
            Icons.note,
            size: widget.size - 2,
            color: Colors.orange,
          ),
        if (_hasStar)
          Icon(
            Icons.star,
            size: widget.size - 2,
            color: Colors.amber,
          ),
      ],
    );

    try {
      return BlocListener<BookmarksCubit, BookmarksState>(
        listener: (context, state) {
          if (state is BookmarkOperationSuccess) {
            _checkBookmarkStatus();
          }
        },
        child: child,
      );
    } catch (e) {
      return child;
    }
  }
}
