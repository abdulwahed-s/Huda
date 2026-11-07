import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/book_progress_service.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/books/languages_cubit.dart';
import 'package:huda/data/models/books_languages_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/books/book_cover.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_search_field.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

/// The library's content column: the gutters and side insets, capped at
/// [maxWidth] and centered, ending above the bottom inset.
class BooksPage extends StatelessWidget {
  const BooksPage({super.key, required this.children, this.maxWidth = 1280});

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final insets = MediaQuery.paddingOf(context);
        final width = constraints.crossAxisExtent;
        final gutter = space.gutter(width);
        final extra = math.max(0.0, (width - maxWidth) / 2);
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            gutter + insets.left + extra,
            space.md,
            gutter + insets.right + extra,
            space.xxl + insets.bottom,
          ),
          sliver: SliverMainAxisGroup(slivers: children),
        );
      },
    );
  }
}

/// The language the library shows, as a quiet chip that opens the
/// language list. It is the filter's one control: "All languages" is the
/// list's first row.
class BooksLanguageChip extends StatelessWidget {
  const BooksLanguageChip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// A language code, or null for all languages.
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final space = context.tokens.space;
    final selected = this.selected;
    final languages = context.watch<LanguagesCubit>().state;
    final name = selected == null
        ? l10n.allLanguages
        : _nameOf(context, languages, selected);
    return Semantics(
      button: true,
      label: '${l10n.language}: $name',
      excludeSemantics: true,
      child: OutlinedButton(
        onPressed: () => _open(context),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsetsDirectional.only(start: space.md, end: space.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate_rounded, size: 18, color: scheme.primary),
            SizedBox(width: space.sm),
            Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
            SizedBox(width: space.xs),
            const Icon(Icons.expand_more_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final cubit = context.read<LanguagesCubit>();
    final l10n = AppLocalizations.of(context)!;
    final picked = await showHudaSheet<_Pick>(
      context: context,
      title: l10n.chooseLanguage,
      sideSheet: true,
      maxDialogWidth: 480,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _LanguageList(selected: selected),
      ),
    );
    if (picked != null && picked.code != selected) onSelected(picked.code);
  }

  static String _nameOf(
    BuildContext context,
    LanguagesState state,
    String code,
  ) {
    if (state is LanguagesLoaded) {
      for (final lang in state.languages) {
        final name = lang.langtranslation;
        if (lang.langsymbol == code && name != null && name.isNotEmpty) {
          return name;
        }
      }
    }
    return bookLanguageName(context, code);
  }
}

/// A choice from the language list (null code: all languages).
class _Pick {
  const _Pick(this.code);
  final String? code;
}

class _LanguageList extends StatefulWidget {
  const _LanguageList({required this.selected});

  final String? selected;

  @override
  State<_LanguageList> createState() => _LanguageListState();
}

class _LanguageListState extends State<_LanguageList> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    return BlocBuilder<LanguagesCubit, LanguagesState>(
      builder: (context, state) {
        if (state is LanguagesError || state is LanguagesOffline) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: space.lg),
            child: Column(
              children: [
                HudaStatusBanner(
                  status: HudaStatus.failed,
                  message: l10n.booksLanguagesError,
                  onRetry: () => context.read<LanguagesCubit>().fetchLanguages(
                    Localizations.localeOf(context).languageCode,
                  ),
                ),
                SizedBox(height: space.md),
                _row(context, null, l10n.allLanguages),
              ],
            ),
          );
        }
        if (state is! LanguagesLoaded) {
          return Column(
            children: [
              for (var i = 0; i < 6; i++)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: space.sm),
                  child: HudaSkeleton(
                    announce: i == 0,
                    child: const HudaSkeletonBlock(height: 40),
                  ),
                ),
            ],
          );
        }
        final query = _query.trim().toLowerCase();
        final matches = [
          for (final lang in state.languages)
            if (query.isEmpty ||
                (lang.langtranslation ?? '').toLowerCase().contains(query) ||
                (lang.langsymbol ?? '').toLowerCase().contains(query))
              lang,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HudaSearchField(
              controller: _search,
              hintText: l10n.searchLanguages,
              onChanged: (value) => setState(() => _query = value),
            ),
            SizedBox(height: space.sm),
            if (query.isEmpty) _row(context, null, l10n.allLanguages),
            for (final lang in matches) _languageRow(context, lang),
            if (matches.isEmpty)
              Padding(
                padding: EdgeInsets.all(space.lg),
                child: Text(
                  l10n.booksNoLanguageMatches(_query.trim()),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _languageRow(BuildContext context, BooksLanguagesModel lang) {
    final code = lang.langsymbol ?? '';
    final name = (lang.langtranslation ?? '').isEmpty
        ? bookLanguageName(context, code)
        : lang.langtranslation!;
    return _row(context, code, name);
  }

  Widget _row(BuildContext context, String? code, String name) {
    final scheme = Theme.of(context).colorScheme;
    final selected = code == widget.selected;
    return HudaSettingsRow(
      icon: code == null ? Icons.public_rounded : Icons.translate_rounded,
      title: name,
      subtitle: code?.toUpperCase(),
      selected: selected,
      trailing: selected
          ? Icon(Icons.check_rounded, color: scheme.primary)
          : null,
      onTap: () => Navigator.of(context).pop(_Pick(code)),
    );
  }
}

/// The last book read, at the top of the library.
class BooksContinueCard extends StatelessWidget {
  const BooksContinueCard({
    super.key,
    required this.progress,
    required this.onTap,
  });

  final BookProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final space = context.tokens.space;
    final total = progress.totalPages;
    final page = progress.pageNumber;
    final where = total > 0
        ? l10n.booksPageOf(page, total)
        : l10n.resumePage(page);
    return Semantics(
      button: true,
      label: '${l10n.continueBook}: ${progress.title ?? ''}, $where',
      excludeSemantics: true,
      child: HudaCard(
        onTap: onTap,
        padding: EdgeInsets.all(space.md),
        child: Row(
          children: [
            BookMark(seed: progress.bookId),
            SizedBox(width: space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HudaEyebrow(l10n.continueBook),
                  SizedBox(height: space.xxs),
                  Text(
                    progress.title ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: space.xs),
                  Text(
                    where,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (total > 0) ...[
                    SizedBox(height: space.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (page / total).clamp(0.0, 1.0),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: space.sm),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// You're offline: the library shows only downloaded books.
class BooksOfflineNotice extends StatelessWidget {
  const BooksOfflineNotice({
    super.key,
    required this.count,
    required this.onRetry,
    required this.retrying,
  });

  final int count;
  final VoidCallback onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final space = context.tokens.space;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.noInternetConnection, style: theme.textTheme.titleSmall),
        SizedBox(height: space.xxs),
        Text(
          l10n.showingDownloadedBooks(count),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    final button = HudaRetryButton(
      onRetry: onRetry,
      retrying: retrying,
      filled: false,
    );
    return Semantics(
      container: true,
      liveRegion: true,
      child: HudaCard(
        padding: EdgeInsets.all(space.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow =
                constraints.maxWidth <
                MediaQuery.textScalerOf(context).scale(420);
            final mark = Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHighest,
              ),
              alignment: Alignment.center,
              child: HudaKhatamMark(color: scheme.onSurfaceVariant, size: 18),
            );
            final lead = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                mark,
                SizedBox(width: space.md),
                Expanded(child: text),
              ],
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  lead,
                  SizedBox(height: space.sm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: button,
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: lead),
                SizedBox(width: space.md),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Moves between the catalogue's pages: Previous, "Page n of m" (opens the
/// page jump), Next. Labels drop to icons when the row is narrow.
class BooksPager extends StatelessWidget {
  const BooksPager({
    super.key,
    required this.page,
    required this.pages,
    required this.onPage,
  });

  final int page;
  final int pages;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    // Chevrons mirror themselves in RTL (matchTextDirection).
    const back = Icons.chevron_left_rounded;
    const forward = Icons.chevron_right_rounded;
    final hasPrevious = page > 1;
    final hasNext = page < pages;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow =
            constraints.maxWidth < MediaQuery.textScalerOf(context).scale(440);
        Widget step(bool forwards) {
          final enabled = forwards ? hasNext : hasPrevious;
          final target = forwards ? page + 1 : page - 1;
          final label = forwards ? l10n.next : l10n.previous;
          final icon = Icon(forwards ? forward : back);
          final onPressed = enabled ? () => onPage(target) : null;
          if (narrow) {
            return IconButton.outlined(
              tooltip: label,
              onPressed: onPressed,
              icon: icon,
            );
          }
          return forwards
              ? OutlinedButton.icon(
                  onPressed: onPressed,
                  iconAlignment: IconAlignment.end,
                  icon: icon,
                  label: Text(label),
                )
              : OutlinedButton.icon(
                  onPressed: onPressed,
                  icon: icon,
                  label: Text(label),
                );
        }

        return Row(
          children: [
            step(false),
            SizedBox(width: space.sm),
            Expanded(
              child: Center(
                child: Tooltip(
                  message: l10n.goToPage,
                  child: TextButton(
                    key: const ValueKey('books-pager-page'),
                    onPressed: pages > 1
                        ? () async {
                            final target = await showBooksPageJump(
                              context,
                              current: page,
                              count: pages,
                            );
                            if (target != null && target != page) {
                              onPage(target);
                            }
                          }
                        : null,
                    child: Text(
                      l10n.booksPageOf(page, pages),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: space.sm),
            step(true),
          ],
        );
      },
    );
  }
}

/// Asks for a page number from 1 to [count]; null when dismissed. Used by
/// the library's pager and the reader's page pill.
Future<int?> showBooksPageJump(
  BuildContext context, {
  required int current,
  required int count,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showHudaSheet<int>(
    context: context,
    title: l10n.goToPageTitle,
    maxDialogWidth: 400,
    builder: (_) => _PageJump(current: current, count: count),
  );
}

class _PageJump extends StatefulWidget {
  const _PageJump({required this.current, required this.count});

  final int current;
  final int count;

  @override
  State<_PageJump> createState() => _PageJumpState();
}

class _PageJumpState extends State<_PageJump> {
  late final _field = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _go() {
    final value = int.tryParse(_field.text.trim());
    if (value == null || value < 1 || value > widget.count) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    return Padding(
      padding: EdgeInsets.only(bottom: space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('books-page-jump-field'),
            controller: _field,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _go(),
            onChanged: (_) {
              if (_invalid) setState(() => _invalid = false);
            },
            decoration: InputDecoration(
              labelText: l10n.pageNumber,
              hintText: '${widget.current}',
              helperText: _invalid
                  ? null
                  : l10n.enterPageNumber(widget.count.toString()),
              errorText: _invalid
                  ? l10n.enterPageNumber(widget.count.toString())
                  : null,
            ),
          ),
          SizedBox(height: space.md),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(onPressed: _go, child: Text(l10n.go)),
          ),
        ],
      ),
    );
  }
}
