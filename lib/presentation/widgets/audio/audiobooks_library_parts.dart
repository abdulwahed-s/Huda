import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/audio_progress_service.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/audios/audio_languages_cubit.dart';
import 'package:huda/data/models/audio_languages_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/audio/audio_format.dart';
import 'package:huda/presentation/widgets/audio/audiobook_swatch.dart';
import 'package:huda/presentation/widgets/books/book_cover.dart'
    show bookLanguageName;
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_search_field.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

/// A recording in the library: its woven swatch, the title in ink under
/// it, who prepared it and how many chapters it has. Tapping it opens the
/// recording's page from the tile.
class AudiobookTile extends StatelessWidget {
  const AudiobookTile({
    super.key,
    required this.seed,
    required this.title,
    required this.onTap,
    this.author,
    this.chapters,
    this.downloaded = false,
  });

  final int seed;
  final String title;
  final String? author;
  final int? chapters;
  final bool downloaded;

  /// Called with the tile's context, so the page can open from it.
  final ValueChanged<BuildContext> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final author = this.author;
    final chapters = this.chapters;
    final meta = [
      if (chapters != null && chapters > 0)
        l10n.audiobooksChapterCount(chapters),
      if (downloaded) l10n.audiobookDownloaded,
    ].join(' · ');
    return Semantics(
      button: true,
      label: [
        title,
        if (author != null && author.isNotEmpty) author,
        if (meta.isNotEmpty) meta,
      ].join(', '),
      excludeSemantics: true,
      child: HudaPressable(
        child: Material(
          type: MaterialType.transparency,
          child: Builder(
            builder: (card) => InkWell(
              borderRadius: BorderRadius.circular(tokens.radius.md),
              onTap: () => onTap(card),
              child: Padding(
                padding: EdgeInsets.only(bottom: space.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AudiobookSwatch(seed: seed),
                    // Clear of the fringe (owner round 1).
                    SizedBox(height: space.lg),
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (author != null && author.isNotEmpty) ...[
                      SizedBox(height: space.xxs),
                      Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (meta.isNotEmpty) ...[
                      SizedBox(height: space.xxs),
                      Row(
                        children: [
                          if (downloaded) ...[
                            Icon(
                              Icons.download_done_rounded,
                              size: 16,
                              color: scheme.primary,
                            ),
                            SizedBox(width: space.xxs),
                          ],
                          Flexible(
                            child: Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The last recording listened to, at the top of the library: its swatch
/// with the chapters heard, the title and where it stopped.
class AudiobookContinueCard extends StatelessWidget {
  const AudiobookContinueCard({
    super.key,
    required this.progress,
    required this.onTap,
  });

  final AudiobookProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final space = context.tokens.space;
    final count = progress.trackCount;
    final where = [
      count != null && count > 0
          ? l10n.chapterProgress(progress.trackIndex + 1, count)
          : l10n.chapter(progress.trackIndex + 1),
      formatAudioDuration(progress.position),
    ].join(' · ');
    return Semantics(
      button: true,
      label: '${l10n.continueListening}: ${progress.title ?? ''}, $where',
      excludeSemantics: true,
      child: HudaCard(
        onTap: onTap,
        padding: EdgeInsets.all(space.md),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              child: AudiobookSwatch(
                seed: progress.audiobookId,
                chapters: count,
                current: count != null ? progress.trackIndex : null,
              ),
            ),
            SizedBox(width: space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HudaEyebrow(l10n.continueListening),
                  SizedBox(height: space.xxs),
                  Text(
                    progress.title ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: space.xxs),
                  Text(
                    where,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
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

/// You're offline: the library shows only the downloaded recordings.
class AudiobooksOfflineNotice extends StatelessWidget {
  const AudiobooksOfflineNotice({
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
          l10n.audiobooksShowingDownloaded(count),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
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
            final lead = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                mark,
                SizedBox(width: space.md),
                Expanded(child: text),
              ],
            );
            if (constraints.maxWidth <
                MediaQuery.textScalerOf(context).scale(420)) {
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

/// The language the library shows, as a quiet chip that opens the
/// language list: the filter's one control ("All languages" is the
/// list's first row). Like the Books library's.
class AudiobooksLanguageChip extends StatelessWidget {
  const AudiobooksLanguageChip({
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
    final languages = context.watch<AudioLanguagesCubit>().state;
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
    final cubit = context.read<AudioLanguagesCubit>();
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
    AudioLanguagesState state,
    String code,
  ) {
    if (state is AudioLanguagesLoaded) {
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
    return BlocBuilder<AudioLanguagesCubit, AudioLanguagesState>(
      builder: (context, state) {
        if (state is AudioLanguagesError || state is AudioLanguagesOffline) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: space.lg),
            child: Column(
              children: [
                HudaStatusBanner(
                  status: HudaStatus.failed,
                  message: l10n.booksLanguagesError,
                  onRetry: () =>
                      context.read<AudioLanguagesCubit>().fetchLanguages(
                        Localizations.localeOf(context).languageCode,
                      ),
                ),
                SizedBox(height: space.md),
                _row(context, null, l10n.allLanguages),
              ],
            ),
          );
        }
        if (state is! AudioLanguagesLoaded) {
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

  Widget _languageRow(BuildContext context, AudioLanguageModel lang) {
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
