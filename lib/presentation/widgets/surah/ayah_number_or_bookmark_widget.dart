import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/bookmark/bookmarks_cubit.dart';
import 'package:huda/data/models/bookmark_model.dart';
import 'package:huda/core/services/bookmark_service.dart';
import 'package:huda/core/services/service_locator.dart';

class AyahNumberOrBookmarkWidget extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final double size;
  final Color textColor;
  final String fontFamily;
  final FontWeight fontWeight;

  const AyahNumberOrBookmarkWidget({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.size,
    required this.textColor,
    this.fontFamily = 'Amiri',
    this.fontWeight = FontWeight.bold,
  });

  @override
  State<AyahNumberOrBookmarkWidget> createState() =>
      _AyahNumberOrBookmarkWidgetState();
}

class _AyahNumberOrBookmarkWidgetState
    extends State<AyahNumberOrBookmarkWidget> {
  bool _hasBookmark = false;
  bool _hasNote = false;
  bool _hasStar = false;
  Color? _bookmarkColor;

  StreamSubscription<BookmarkChange>? _bookmarkChangesSubscription;

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
    _subscribeToBookmarkChanges();
  }

  @override
  void dispose() {
    _bookmarkChangesSubscription?.cancel();
    _localBookmarksCubit?.close();
    super.dispose();
  }

  void _subscribeToBookmarkChanges() {
    final bookmarkService = getIt<BookmarkService>();
    _bookmarkChangesSubscription =
        bookmarkService.bookmarkChanges.listen((change) {
      if (change.surahNumber == widget.surahNumber &&
          change.ayahNumber == widget.ayahNumber) {
        _checkBookmarkStatus();
      }
    });
  }

  @override
  void didUpdateWidget(AyahNumberOrBookmarkWidget oldWidget) {
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

  Widget _buildContent() {
    if (_hasStar) {
      return Icon(
        Icons.star,
        size: widget.size,
        color: Colors.amber,
      );
    } else if (_hasNote) {
      return Icon(
        Icons.edit_note,
        size: widget.size,
        color: Colors.orange,
      );
    } else if (_hasBookmark) {
      return Icon(
        Icons.bookmark,
        size: widget.size,
        color: _bookmarkColor ?? widget.textColor,
      );
    } else {
      return Text(
        '${widget.ayahNumber}',
        style: TextStyle(
          color: widget.textColor,
          fontSize: widget.size,
          fontWeight: widget.fontWeight,
          fontFamily: widget.fontFamily,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Center(child: _buildContent());

    try {
      return BlocListener<BookmarksCubit, BookmarksState>(
        listener: (context, state) {
          if (state is BookmarkOperationSuccess ||
              state is BookmarksLoaded ||
              state is BookmarkOperationFailure) {
            _checkBookmarkStatus();
          }
        },
        child: child,
      );
    } catch (e) {
      if (_localBookmarksCubit != null) {
        return StreamBuilder<BookmarksState>(
          stream: _localBookmarksCubit!.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final state = snapshot.data!;
              if (state is BookmarkOperationSuccess ||
                  state is BookmarksLoaded ||
                  state is BookmarkOperationFailure) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _checkBookmarkStatus();
                });
              }
            }
            return child;
          },
        );
      }
      return child;
    }
  }
}
