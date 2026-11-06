import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/bookmark_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/quran_home/quran_index_widgets.dart';

/// What a bookmark's ⋮ offers.
enum QuranBookmarkAction { editNote, delete }

/// The mark for a kind of saved ayah: a bookmark in its color, a note, a
/// star.
IconData quranBookmarkIcon(BookmarkType type) => switch (type) {
  BookmarkType.bookmark => Icons.bookmark_rounded,
  BookmarkType.note => Icons.sticky_note_2_rounded,
  BookmarkType.star => Icons.star_rounded,
};

/// A saved ayah: where it is, its kind, the ayah, and the note. Tapping it
/// opens the ayah in the reader; ⋮ edits the note or deletes it.
class QuranBookmarkCard extends StatelessWidget {
  const QuranBookmarkCard({
    super.key,
    required this.bookmark,
    required this.onOpen,
    required this.onAction,
  });

  final BookmarkModel bookmark;
  final VoidCallback onOpen;
  final ValueChanged<QuranBookmarkAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final surah = QuranSurahRef.number(bookmark.surahNumber, language);
    final reference =
        '${surah.title} · ${l10n.ayahNumber(bookmark.ayahNumber)}';
    final note = bookmark.note;
    final kindColor = switch (bookmark.type) {
      BookmarkType.bookmark => bookmark.color ?? scheme.primary,
      BookmarkType.note => scheme.primary,
      BookmarkType.star => scheme.tertiary,
    };
    final kindLabel = switch (bookmark.type) {
      BookmarkType.bookmark => l10n.bookmark,
      BookmarkType.note => l10n.note,
      BookmarkType.star => l10n.stars,
    };
    return Semantics(
      key: ValueKey('quran-bookmark-${bookmark.id}'),
      container: true,
      child: HudaCard(
        onTap: onOpen,
        padding: EdgeInsetsDirectional.fromSTEB(
          space.md,
          space.xs,
          space.xxs,
          space.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  quranBookmarkIcon(bookmark.type),
                  color: kindColor,
                  size: 20,
                  semanticLabel: kindLabel,
                ),
                SizedBox(width: space.xs),
                Expanded(
                  child: Text(
                    reference,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                PopupMenuButton<QuranBookmarkAction>(
                  tooltip: l10n.quranMore,
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: onAction,
                  itemBuilder: (_) => [
                    if (bookmark.type == BookmarkType.note)
                      PopupMenuItem(
                        value: QuranBookmarkAction.editNote,
                        child: ListTile(
                          leading: const Icon(Icons.edit_rounded),
                          title: Text(l10n.editNote),
                        ),
                      ),
                    PopupMenuItem(
                      value: QuranBookmarkAction.delete,
                      child: ListTile(
                        leading: const Icon(Icons.delete_outline_rounded),
                        title: Text(l10n.delete),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(end: space.sm),
              child: Text(
                bookmark.ayahText,
                textDirection: TextDirection.rtl,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: context.type.ayah.copyWith(
                  fontSize: 22,
                  color: scheme.onSurface,
                ),
              ),
            ),
            if (note != null && note.isNotEmpty) ...[
              SizedBox(height: space.sm),
              Padding(
                padding: EdgeInsetsDirectional.only(end: space.sm),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: BorderDirectional(
                      start: BorderSide(
                        color: scheme.tertiary,
                        width: tokens.stroke.bold,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(start: space.sm),
                    child: Text(note, style: theme.textTheme.bodyMedium),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A bookmark card while they load, in its shape.
class QuranBookmarkCardSkeleton extends StatelessWidget {
  const QuranBookmarkCardSkeleton({super.key, this.announce = false});

  final bool announce;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return HudaCard(
      child: HudaSkeleton(
        announce: announce,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HudaSkeletonBlock(width: 140, height: 14),
            SizedBox(height: space.md),
            HudaSkeletonLines(lines: 2, style: context.type.ayah),
          ],
        ),
      ),
    );
  }
}
