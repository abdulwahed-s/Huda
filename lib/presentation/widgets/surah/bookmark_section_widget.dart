import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_tokens.dart';
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
    _noteEditor?.dispose();
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

  /// The note being written, while the editor is open.
  TextEditingController? _noteEditor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final editor = _noteEditor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _option(
          key: const ValueKey('quran-mark-bookmark'),
          icon: Icons.bookmark_rounded,
          label: l10n.bookmark,
          active: _isBookmarked,
          color: _selectedColor,
          onTap: _toggleBookmark,
        ),
        if (_isBookmarked) ...[
          SizedBox(height: space.sm),
          Padding(
            padding: EdgeInsetsDirectional.only(start: space.sm),
            child: Wrap(
              spacing: space.xs,
              runSpacing: space.xs,
              children: [
                for (final color in BookmarkColors.availableColors)
                  _swatch(color),
              ],
            ),
          ),
        ],
        SizedBox(height: space.sm),
        _option(
          key: const ValueKey('quran-mark-star'),
          icon: Icons.star_rounded,
          label: l10n.star,
          active: _isStarred,
          color: scheme.tertiary,
          onTap: _toggleStar,
        ),
        SizedBox(height: space.sm),
        if (editor != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const ValueKey('quran-mark-note-field'),
                controller: editor,
                autofocus: true,
                minLines: 3,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: l10n.yourNote,
                  hintText: l10n.noteHint,
                ),
              ),
              SizedBox(height: space.sm),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: space.xs,
                runSpacing: space.xs,
                children: [
                  if (_hasNote)
                    TextButton.icon(
                      onPressed: () {
                        _removeNote();
                        _closeEditor();
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(l10n.remove),
                    ),
                  OutlinedButton(
                    onPressed: _closeEditor,
                    child: Text(l10n.cancel),
                  ),
                  FilledButton.icon(
                    key: const ValueKey('quran-mark-note-save'),
                    onPressed: () {
                      _saveNote(editor.text);
                      _closeEditor();
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: Text(_hasNote ? l10n.update : l10n.save),
                  ),
                ],
              ),
            ],
          )
        else if (_hasNote)
          _option(
            key: const ValueKey('quran-mark-note'),
            icon: Icons.sticky_note_2_rounded,
            label: l10n.yourNote,
            detail: _currentNote,
            active: true,
            color: scheme.primary,
            onTap: _openEditor,
            trailing: Icon(Icons.edit_rounded, color: scheme.primary),
          )
        else
          _option(
            key: const ValueKey('quran-mark-note'),
            icon: Icons.sticky_note_2_outlined,
            label: l10n.addNote,
            active: false,
            color: scheme.primary,
            onTap: _openEditor,
            trailing: Icon(Icons.add_rounded, color: scheme.onSurfaceVariant),
          ),
      ],
    );
  }

  void _openEditor() =>
      setState(() => _noteEditor = TextEditingController(text: _currentNote));

  void _closeEditor() {
    final editor = _noteEditor;
    setState(() => _noteEditor = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => editor?.dispose());
  }

  /// A mark the ayah has or hasn't: a hairline tile, tinted in the mark's
  /// color with a filled icon when it has it.
  Widget _option({
    required Key key,
    required IconData icon,
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
    String? detail,
    Widget? trailing,
  }) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      key: key,
      button: true,
      toggled: trailing == null ? active : null,
      label: [label, ?detail].join(', '),
      excludeSemantics: true,
      child: Material(
        color: active
            ? color.withValues(alpha: 0.1)
            : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: tokens.radius.control,
          side: BorderSide(
            color: active ? color : scheme.outlineVariant,
            width: active ? tokens.stroke.fine : tokens.stroke.hairline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: EdgeInsets.all(tokens.space.sm),
              child: Row(
                children: [
                  Icon(icon, color: active ? color : scheme.onSurfaceVariant),
                  SizedBox(width: tokens.space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: theme.textTheme.labelLarge),
                        if (detail != null && detail.isNotEmpty)
                          Text(
                            detail,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                  trailing ??
                      Icon(
                        active
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        color: active ? color : scheme.onSurfaceVariant,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A bookmark color: a disc, ringed and checked when chosen.
  Widget _swatch(Color color) {
    final selected = _selectedColor.toARGB32() == color.toARGB32();
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: BookmarkColors.getColorName(color),
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => _changeBookmarkColor(color),
        radius: 24,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: AnimatedContainer(
              duration: context.tokens.motion.of(
                context,
                context.tokens.motion.short,
              ),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.onSurface : scheme.outlineVariant,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
        ),
      ),
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
