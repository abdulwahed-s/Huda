import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huda/core/services/bookmark_service.dart';
import 'package:huda/core/services/khatma_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/bookmark_model.dart';
import 'package:huda/l10n/app_localizations.dart';

/// What a reader has marked on an ayah, beside it: a bookmark (in its
/// color), a note, a star, and where today's khatma portion (wird) starts
/// and ends. Empty when there's nothing. Follows bookmark and khatma
/// changes while it's on screen.
///
/// It replaces the old number circle that showed one of these *instead*
/// of the ayah's number; the number now stays in its rosette.
class QuranAyahMarks extends StatefulWidget {
  const QuranAyahMarks({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
  });

  final int surahNumber;
  final int ayahNumber;

  @override
  State<QuranAyahMarks> createState() => _QuranAyahMarksState();
}

class _QuranAyahMarksState extends State<QuranAyahMarks> {
  BookmarkModel? _bookmark;
  bool _note = false;
  bool _star = false;
  bool _wirdStart = false;
  bool _wirdEnd = false;
  StreamSubscription<BookmarkChange>? _bookmarks;
  StreamSubscription<void>? _khatma;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _loadKhatma();
    try {
      _bookmarks = getIt<BookmarkService>().bookmarkChanges.listen((change) {
        if (change.surahNumber == widget.surahNumber &&
            change.ayahNumber == widget.ayahNumber) {
          _loadBookmarks();
        }
      });
    } catch (_) {}
    try {
      _khatma = getIt<KhatmaService>().khatmaChanges.listen(
        (_) => _loadKhatma(),
      );
    } catch (_) {}
  }

  @override
  void didUpdateWidget(QuranAyahMarks old) {
    super.didUpdateWidget(old);
    if (old.surahNumber != widget.surahNumber ||
        old.ayahNumber != widget.ayahNumber) {
      _loadBookmarks();
      _loadKhatma();
    }
  }

  @override
  void dispose() {
    _bookmarks?.cancel();
    _khatma?.cancel();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    try {
      final service = getIt<BookmarkService>();
      final s = widget.surahNumber;
      final a = widget.ayahNumber;
      final bookmark = await service.getBookmark(s, a, BookmarkType.bookmark);
      final note = await service.hasBookmarkType(s, a, BookmarkType.note);
      final star = await service.hasBookmarkType(s, a, BookmarkType.star);
      if (!mounted) return;
      setState(() {
        _bookmark = bookmark;
        _note = note;
        _star = star;
      });
    } catch (error) {
      debugPrint('Ayah marks: bookmarks unavailable: $error');
    }
  }

  void _loadKhatma() {
    var start = false;
    var end = false;
    try {
      final khatma = getIt<KhatmaService>();
      if (khatma.enabled && !khatma.isCompleted) {
        final day = khatma.rangeDetailsForDay(
          khatma.currentDayIndex,
          khatma.planDays,
        );
        start =
            widget.surahNumber == day.startSurah &&
            widget.ayahNumber == day.startVerse;
        end =
            widget.surahNumber == day.endSurah &&
            widget.ayahNumber == day.endVerse;
      }
    } catch (_) {}
    if (mounted && (start != _wirdStart || end != _wirdEnd)) {
      setState(() {
        _wirdStart = start;
        _wirdEnd = end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final scheme = Theme.of(context).colorScheme;
    final marks = <(IconData, Color, String)>[
      if (_wirdStart)
        (Icons.flag_rounded, scheme.primary, l10n.quranWirdStartsHere),
      if (_wirdEnd)
        (Icons.check_circle_rounded, scheme.primary, l10n.quranWirdEndsHere),
      if (_bookmark != null)
        (
          Icons.bookmark_rounded,
          _bookmark!.color ?? scheme.primary,
          l10n.bookmark,
        ),
      if (_note) (Icons.sticky_note_2_rounded, scheme.primary, l10n.note),
      if (_star) (Icons.star_rounded, scheme.tertiary, l10n.stars),
    ];
    if (marks.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: space.xxs,
      children: [
        for (final (icon, color, label) in marks)
          Icon(icon, size: 18, color: color, semanticLabel: label),
      ],
    );
  }
}
