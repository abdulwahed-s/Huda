import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/book_languages/book_languages_cubit.dart';
import 'package:huda/data/models/books_detail_model.dart' as detail;
import 'package:huda/data/models/offline_book_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/book_detail/book_open_binding.dart';
import 'package:huda/presentation/widgets/books/book_cover.dart';
import 'package:huda/presentation/widgets/books/books_identity.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:intl/intl.dart' show Bidi, DateFormat;

/// Someone who prepared the book, by role.
typedef BookPerson = ({String role, String name});

/// One of the book's files.
class BookFile {
  const BookFile({
    required this.type,
    required this.description,
    required this.size,
    this.online,
    this.saved,
  });

  final String type;
  final String description;
  final String size;
  final detail.Attachment? online;
  final OfflineAttachment? saved;

  bool get isPdf => type.toUpperCase() == 'PDF';
}

/// What the page shows of a book, from the catalogue or a saved copy.
class BookView {
  const BookView({
    required this.title,
    required this.description,
    required this.people,
    required this.language,
    required this.files,
    this.savedOn,
  });

  factory BookView.online(
    detail.BookDetailModel book, {
    required String fallbackTitle,
  }) => BookView(
    title: (book.title ?? '').isEmpty ? fallbackTitle : book.title!,
    description: book.description ?? '',
    people: [
      for (final person in book.preparedBy ?? const <detail.PreparedBy>[])
        if ((person.title ?? '').isNotEmpty)
          (role: person.type ?? '', name: person.title!),
    ],
    language: book.translationLanguage ?? '',
    files: [
      for (final file in book.attachments ?? const <detail.Attachment>[])
        BookFile(
          type: file.extensionType ?? '',
          description: file.description ?? '',
          size: file.size ?? '',
          online: file,
        ),
    ],
  );

  factory BookView.offline(OfflineBookModel book) => BookView(
    title: book.title,
    description: book.description,
    people: [
      for (final person in book.preparedBy)
        if ((person.title ?? '').isNotEmpty)
          (role: person.type, name: person.title!),
    ],
    language: book.language,
    files: [
      for (final file in book.attachments)
        BookFile(
          type: file.extensionType,
          description: file.description,
          size: file.size,
          saved: file,
        ),
    ],
    savedOn: book.downloadedAt,
  );

  final String title;
  final String description;
  final List<BookPerson> people;

  /// The language this copy is in.
  final String language;
  final List<BookFile> files;

  /// When it was downloaded, for a saved copy read offline.
  final DateTime? savedOn;

  BookFile? get main => files.isEmpty ? null : files.first;
}

String bookRoleLabel(AppLocalizations l10n, String role) => switch (role) {
  'author' => l10n.booksRoleAuthor,
  'translator' => l10n.booksRoleTranslator,
  'editor' => l10n.booksRoleEditor,
  'publisher' => l10n.booksRolePublisher,
  'source' => l10n.booksRoleSource,
  _ => l10n.booksRoleOther,
};

/// The open binding with the book's title page: the title, a gilt rule,
/// who prepared it, and its language, format and size.
class BookBindingHero extends StatelessWidget {
  const BookBindingHero({super.key, required this.book, required this.seed});

  final BookView book;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final space = context.tokens.space;
    final paper = bookPaper(context);
    final main = book.main;
    final meta = [
      if (book.language.isNotEmpty) bookLanguageName(context, book.language),
      if (main != null && main.type.isNotEmpty) main.type.toUpperCase(),
      if (main != null && main.size.isNotEmpty) main.size,
    ].join(' · ');
    final people = book.people.take(3).toList();

    return Semantics(
      container: true,
      label: [
        book.title,
        for (final p in people) '${bookRoleLabel(l10n, p.role)}: ${p.name}',
        meta,
      ].join('. '),
      excludeSemantics: true,
      child: BookOpenBinding(
        seed: seed,
        coverTitle: book.title,
        titlePage: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: space.md,
            vertical: space.lg,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                book.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: paper.ink,
                  height: 1.3,
                ),
              ),
              SizedBox(height: space.sm),
              const BookTitleRule(),
              SizedBox(height: space.sm),
              for (final person in people) ...[
                Text(
                  bookRoleLabel(l10n, person.role),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: paper.inkMuted,
                  ),
                ),
                Text(
                  person.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: paper.ink),
                ),
                SizedBox(height: space.xs),
              ],
              if (meta.isNotEmpty) ...[
                SizedBox(height: space.sm),
                Text(
                  meta,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: paper.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Read (lit) and Download / Remove download (quiet), side by side, or
/// stacked when narrow or at large text. While a download runs, its button
/// is a progress bar that says how far it got.
class BookActions extends StatelessWidget {
  const BookActions({
    super.key,
    required this.book,
    required this.downloaded,
    required this.downloading,
    required this.progress,
    required this.onRead,
    required this.onDownload,
    required this.onRemove,
  });

  final BookView book;
  final bool downloaded;
  final bool downloading;
  final double progress;
  final VoidCallback onRead;

  /// Null hides Download (web, or a saved copy read offline).
  final VoidCallback? onDownload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final space = tokens.space;
    final main = book.main;
    if (main == null) return const SizedBox.shrink();
    final read = FilledButton.icon(
      onPressed: onRead,
      icon: Icon(
        main.isPdf ? Icons.menu_book_rounded : Icons.open_in_new_rounded,
      ),
      label: Text(main.isPdf ? l10n.readPdf : l10n.openFile),
    );

    Widget? second;
    if (downloading) {
      final percent = (progress * 100).clamp(0, 100).round();
      second = Semantics(
        liveRegion: true,
        label: l10n.booksDownloading(percent),
        excludeSemantics: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.radius.md),
              side: BorderSide(color: theme.colorScheme.outline),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: progress.clamp(0.0, 1.0)),
                  duration: tokens.motion.of(context, tokens.motion.medium),
                  builder: (context, value, _) => FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: value,
                    child: ColoredBox(
                      color: tokens.lit.withValues(alpha: 0.16),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: space.md,
                  vertical: space.sm,
                ),
                child: Text(
                  l10n.booksDownloading(percent),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (downloaded) {
      second = OutlinedButton.icon(
        onPressed: onRemove,
        icon: const Icon(Icons.delete_outline_rounded),
        label: Text(l10n.booksRemoveDownload),
      );
    } else if (onDownload != null) {
      second = OutlinedButton.icon(
        onPressed: onDownload,
        icon: const Icon(Icons.download_rounded),
        label: Text(l10n.download),
      );
    }

    final status = downloaded && !downloading
        ? Padding(
            padding: EdgeInsets.only(top: space.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.download_done_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: space.xs),
                Flexible(
                  child: Text(
                    book.savedOn == null
                        ? l10n.booksDownloadedNote
                        : l10n.booksDownloadedOn(
                            DateFormat.yMMMd(
                              Localizations.localeOf(context).toLanguageTag(),
                            ).format(book.savedOn!),
                          ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            second == null ||
            constraints.maxWidth < MediaQuery.textScalerOf(context).scale(380);
        final buttons = stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  read,
                  if (second != null) ...[SizedBox(height: space.sm), second],
                ],
              )
            : Row(
                children: [
                  Expanded(child: read),
                  SizedBox(width: space.sm),
                  Expanded(child: second),
                ],
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [buttons, ?status],
        );
      },
    );
  }
}

/// What the book is about, the languages it also comes in, and its other
/// formats (the first file is the Read button).
class BookDetails extends StatelessWidget {
  const BookDetails({
    super.key,
    required this.book,
    required this.selectedLanguage,
    required this.onLanguage,
    required this.originalLanguage,
    required this.onFile,
    required this.onSavedFile,
  });

  final BookView book;
  final String? selectedLanguage;

  /// Null for a saved copy read offline (no other languages then).
  final ValueChanged<String?>? onLanguage;
  final String originalLanguage;
  final ValueChanged<dynamic> onFile;
  final ValueChanged<OfflineAttachment> onSavedFile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final space = context.tokens.space;
    final others = book.files.skip(1).toList();
    final onLanguage = this.onLanguage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (book.description.trim().isNotEmpty) ...[
          HudaSectionHeader(l10n.bookDetails),
          SizedBox(height: space.xs),
          // Runs in the book's own direction, not the app's: an English
          // description in the Arabic app keeps its full stop at the end.
          SelectableText(
            book.description.trim(),
            style: theme.textTheme.bodyLarge,
            textDirection: Bidi.detectRtlDirectionality(book.description)
                ? TextDirection.rtl
                : TextDirection.ltr,
          ),
        ],
        if (onLanguage != null)
          _Languages(
            selected: selectedLanguage,
            original: originalLanguage,
            onSelected: onLanguage,
          ),
        if (others.isNotEmpty) ...[
          SizedBox(height: space.xl),
          HudaSectionHeader(l10n.booksOtherFormats),
          SizedBox(height: space.xs),
          HudaCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, file) in others.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  HudaContentRow(
                    leading: HudaIconMark(
                      file.isPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.description_rounded,
                    ),
                    title: file.description.isEmpty
                        ? file.type.toUpperCase()
                        : file.description,
                    meta: [
                      file.type.toUpperCase(),
                      if (file.size.isNotEmpty) file.size,
                    ].join(' · '),
                    trailing: Icon(
                      file.isPdf
                          ? Icons.menu_book_rounded
                          : Icons.open_in_new_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    onTap: () {
                      if (file.saved case final saved?) {
                        onSavedFile(saved);
                      } else {
                        onFile(file.online);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// "Also in": the book's own language first, then its translations, as
/// chips; the chosen one is lit.
class _Languages extends StatelessWidget {
  const _Languages({
    required this.selected,
    required this.original,
    required this.onSelected,
  });

  final String? selected;
  final String original;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    return BlocBuilder<BookLanguagesCubit, BookLanguagesState>(
      builder: (context, state) {
        if (state is BookTranslationsLoading) {
          return Padding(
            padding: EdgeInsets.only(top: space.xl),
            child: HudaSkeleton(
              child: Wrap(
                spacing: space.sm,
                runSpacing: space.sm,
                children: [
                  for (var i = 0; i < 5; i++)
                    const HudaSkeletonBlock(width: 88, height: 40),
                ],
              ),
            ),
          );
        }
        if (state is! BookTranslationsLoaded) return const SizedBox.shrink();
        final translations = [
          for (final t in state.translations)
            if (t.slang != original) t,
        ];
        if (translations.isEmpty) return const SizedBox.shrink();
        Widget chip(String? code, String language) => ChoiceChip(
          label: Text(bookLanguageName(context, language)),
          selected: selected == code,
          onSelected: (_) {
            if (selected != code) onSelected(code);
          },
        );
        return Padding(
          padding: EdgeInsets.only(top: space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HudaSectionHeader(l10n.booksAlsoIn),
              SizedBox(height: space.sm),
              Wrap(
                spacing: space.sm,
                runSpacing: space.sm,
                children: [
                  chip(null, original),
                  for (final t in translations) chip(t.slang, t.slang),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The page while the book loads: the binding's shape, the buttons, lines.
class BookPageSkeleton extends StatelessWidget {
  const BookPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return SingleChildScrollView(
      padding: EdgeInsets.all(space.gutter(MediaQuery.sizeOf(context).width)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: HudaSkeleton(
            announce: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BookAspect(
                  aspect: bookAspect * 2,
                  child: HudaSkeletonBlock(height: 0),
                ),
                SizedBox(height: space.lg),
                const HudaSkeletonBlock(height: 48),
                SizedBox(height: space.xl),
                const HudaSkeletonLines(lines: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
