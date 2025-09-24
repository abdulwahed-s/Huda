import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/bookmark_model.dart';
import 'package:huda/cubit/bookmark/bookmarks_cubit.dart';
import 'package:huda/core/services/bookmark_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/l10n/app_localizations.dart';

class BookmarkSection extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final String ayahText;
  final String surahName;
  final double Function()? getCurrentScrollPosition;

  const BookmarkSection({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.ayahText,
    required this.surahName,
    this.getCurrentScrollPosition,
  });

  @override
  State<BookmarkSection> createState() => _BookmarkSectionState();
}

class _BookmarkSectionState extends State<BookmarkSection> {
  bool _isBookmarked = false;
  bool _hasNote = false;
  bool _isStarred = false;
  String _currentNote = '';
  Color _selectedColor = BookmarkColors.getDefaultColor();

  // Create a local BookmarksCubit if one isn't available in the context
  BookmarksCubit? _localBookmarksCubit;
  BookmarksCubit get _bookmarksCubit {
    try {
      return context.read<BookmarksCubit>();
    } catch (e) {
      // If no cubit is found in context, create a local one
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

  Future<void> _checkBookmarkStatus() async {
    final bookmarksCubit = _bookmarksCubit;

    final isBookmarked = await bookmarksCubit.hasBookmarkType(
      widget.surahNumber,
      widget.ayahNumber,
      BookmarkType.bookmark,
    );

    final hasNote = await bookmarksCubit.hasBookmarkType(
      widget.surahNumber,
      widget.ayahNumber,
      BookmarkType.note,
    );

    final isStarred = await bookmarksCubit.hasBookmarkType(
      widget.surahNumber,
      widget.ayahNumber,
      BookmarkType.star,
    );

    // Get existing note if any
    if (hasNote) {
      final noteBookmark = await bookmarksCubit.getBookmark(
        widget.surahNumber,
        widget.ayahNumber,
        BookmarkType.note,
      );
      _currentNote = noteBookmark?.note ?? '';
    }

    // Get existing bookmark color if any
    if (isBookmarked) {
      final bookmark = await bookmarksCubit.getBookmark(
        widget.surahNumber,
        widget.ayahNumber,
        BookmarkType.bookmark,
      );
      if (bookmark?.color != null) {
        _selectedColor = bookmark!.color!;
      }
    }

    if (mounted) {
      setState(() {
        _isBookmarked = isBookmarked;
        _hasNote = hasNote;
        _isStarred = isStarred;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: context.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.bookmark_outline,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? context.accentColor
                      : context.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.bookmarkAyah,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? context.accentColor
                      : context.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bookmark options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Regular Bookmark
              _buildBookmarkOption(
                icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                label: AppLocalizations.of(context)!.bookmark,
                isActive: _isBookmarked,
                color: _selectedColor,
                onTap: () => _toggleBookmark(),
              ),
              const SizedBox(width: 10),
              // Note
              _buildBookmarkOption(
                icon: _hasNote ? Icons.note : Icons.note_outlined,
                label: AppLocalizations.of(context)!.note,
                isActive: _hasNote,
                color: Colors.orange,
                onTap: () => _showNoteDialog(),
              ),
              const SizedBox(width: 10),
              // Star
              _buildBookmarkOption(
                icon: _isStarred ? Icons.star : Icons.star_outline,
                label: AppLocalizations.of(context)!.star,
                isActive: _isStarred,
                color: Colors.amber,
                onTap: () => _toggleStar(),
              ),
            ],
          ),

          // Show color picker for bookmark if bookmarked
          if (_isBookmarked) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        size: 16,
                        color: _selectedColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.bookmarkColor,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildColorPicker(),
                ],
              ),
            ),
          ],

          // Show note preview if has note
          if (_hasNote && _currentNote.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.note_outlined,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.yourNote,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _showNoteDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.edit,
                                size: 12,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!.edit,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[850]
                          : Colors.orange.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _currentNote,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookmarkOption({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.12)
                : (isDark
                    ? Colors.grey[850]
                    : Colors.grey.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.4)
                  : (isDark
                      ? Colors.grey[700]!
                      : Colors.grey.withValues(alpha: 0.2)),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey('$icon-$isActive'),
                  color: isActive
                      ? color
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? color
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: BookmarkColors.availableColors.map((color) {
        final isSelected = _selectedColor.toARGB32() == color.toARGB32();
        return GestureDetector(
          onTap: () => _changeBookmarkColor(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : color.withValues(alpha: 0.3),
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        spreadRadius: 0,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  void _toggleBookmark() {
    final bookmarksCubit = _bookmarksCubit;

    if (_isBookmarked) {
      bookmarksCubit.removeBookmark(
        widget.surahNumber,
        widget.ayahNumber,
        BookmarkType.bookmark,
      );
    } else {
      final currentPosition = widget.getCurrentScrollPosition?.call();
      bookmarksCubit.addBookmark(
        surahNumber: widget.surahNumber,
        ayahNumber: widget.ayahNumber,
        ayahText: widget.ayahText,
        surahName: widget.surahName,
        type: BookmarkType.bookmark,
        color: _selectedColor,
        ayahPosition: currentPosition,
      );
    }

    setState(() {
      _isBookmarked = !_isBookmarked;
    });
  }

  void _toggleStar() {
    final bookmarksCubit = _bookmarksCubit;

    if (_isStarred) {
      bookmarksCubit.removeBookmark(
        widget.surahNumber,
        widget.ayahNumber,
        BookmarkType.star,
      );
    } else {
      final currentPosition = widget.getCurrentScrollPosition?.call();
      bookmarksCubit.addBookmark(
        surahNumber: widget.surahNumber,
        ayahNumber: widget.ayahNumber,
        ayahText: widget.ayahText,
        surahName: widget.surahName,
        type: BookmarkType.star,
        ayahPosition: currentPosition,
      );
    }

    setState(() {
      _isStarred = !_isStarred;
    });
  }

  void _changeBookmarkColor(Color color) {
    setState(() {
      _selectedColor = color;
    });

    // Update the bookmark with new color
    if (_isBookmarked) {
      final bookmarksCubit = _bookmarksCubit;
      final currentPosition = widget.getCurrentScrollPosition?.call();
      bookmarksCubit.addBookmark(
        surahNumber: widget.surahNumber,
        ayahNumber: widget.ayahNumber,
        ayahText: widget.ayahText,
        surahName: widget.surahName,
        type: BookmarkType.bookmark,
        color: color,
        ayahPosition: currentPosition,
      );
    }
  }

  void _showNoteDialog() {
    final noteController = TextEditingController(text: _currentNote);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_note,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasNote
                              ? AppLocalizations.of(context)!.editNote
                              : AppLocalizations.of(context)!.addNote,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF2C2C2C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.surahAyahReference(
                            widget.surahName,
                            widget.ayahNumber.toString(),
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Note input field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    width: 1.5,
                  ),
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
                ),
                child: TextField(
                  controller: noteController,
                  maxLines: 6,
                  autofocus: !_hasNote,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.noteHint,
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Remove button (only if note exists)
                  if (_hasNote) ...[
                    TextButton.icon(
                      onPressed: () {
                        _removeNote();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      label: Text(
                        AppLocalizations.of(context)!.remove,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Save button
                  ElevatedButton.icon(
                    onPressed: () {
                      _saveNote(noteController.text);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(
                      Icons.save_outlined,
                      size: 18,
                    ),
                    label: Text(
                      _hasNote
                          ? AppLocalizations.of(context)!.update
                          : AppLocalizations.of(context)!.save,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveNote(String note) {
    if (note.trim().isEmpty) {
      _removeNote();
      return;
    }

    final bookmarksCubit = _bookmarksCubit;
    final currentPosition = widget.getCurrentScrollPosition?.call();
    bookmarksCubit.addBookmark(
      surahNumber: widget.surahNumber,
      ayahNumber: widget.ayahNumber,
      ayahText: widget.ayahText,
      surahName: widget.surahName,
      type: BookmarkType.note,
      note: note,
      ayahPosition: currentPosition,
    );

    setState(() {
      _hasNote = true;
      _currentNote = note;
    });
  }

  void _removeNote() {
    final bookmarksCubit = _bookmarksCubit;
    bookmarksCubit.removeBookmark(
      widget.surahNumber,
      widget.ayahNumber,
      BookmarkType.note,
    );

    setState(() {
      _hasNote = false;
      _currentNote = '';
    });
  }
}
