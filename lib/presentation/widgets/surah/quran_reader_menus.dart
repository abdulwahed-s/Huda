import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/mushaf_pack_service.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/memorization/memorization_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_search_field.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/quran_home/quran_index_widgets.dart';
import 'package:huda/presentation/widgets/surah/quran_mushaf_page_view.dart';
import 'package:huda/presentation/widgets/surah/quran_reader_parts.dart';

/// The 114 surahs while reading, the open one selected, in the Surahs
/// sheet (a side sheet on wide windows). Typing filters by name or number.
/// It opens scrolled to the open surah.
class QuranIndexList extends StatefulWidget {
  const QuranIndexList({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final int current;
  final ValueChanged<int> onSelect;

  @override
  State<QuranIndexList> createState() => _QuranIndexListState();
}

class _QuranIndexListState extends State<QuranIndexList> {
  final _search = TextEditingController();
  final _currentKey = GlobalKey();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  @override
  void didUpdateWidget(QuranIndexList old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    }
  }

  void _reveal() {
    final tile = _currentKey.currentContext;
    if (tile == null || !mounted) return;
    // The first surahs are already in view under the search field; don't
    // scroll the field away for them.
    if (widget.current <= 4) return;
    Scrollable.ensureVisible(tile, alignment: 0.3);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final language = Localizations.localeOf(context).languageCode;
    final q = _query.trim().toLowerCase();
    final surahs = [
      for (final model in QuranSurahRef.index)
        if (q.isEmpty ||
            '${model.number}' == q ||
            (model.transliteration?.toLowerCase().contains(q) ?? false) ||
            (model.englishName?.toLowerCase().contains(q) ?? false) ||
            model.localizedName(language).toLowerCase().contains(q) ||
            (model.translits?.values.any((t) => t.toLowerCase().contains(q)) ??
                false) ||
            (model.name?.contains(_query.trim()) ?? false))
          QuranSurahRef.of(model, language),
    ];
    final children = <Widget>[
      Padding(
        padding: EdgeInsets.only(bottom: space.sm),
        child: HudaSearchField(
          key: const ValueKey('quran-index-search'),
          controller: _search,
          onChanged: (value) => setState(() => _query = value),
          hintText: l10n.searchSurahHint,
        ),
      ),
      if (surahs.isEmpty)
        Padding(
          padding: EdgeInsets.all(space.lg),
          child: Text(
            l10n.surahNoResults,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      for (final surah in surahs)
        QuranSurahTile(
          key: surah.number == widget.current ? _currentKey : null,
          surah: surah,
          dense: true,
          selected: surah.number == widget.current,
          onTap: (_) => widget.onSelect(surah.number),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// How the Quran is shown: the reading mode (scrolling text, or a Mushaf
/// of page images that may need a download first), the Mushaf's layout and
/// page turn, and the scrolling text's font. The Mushaf's pages: one or
/// two (showing what's on the screen; until the reader chooses, two on
/// wide windows and open foldables, one on phones; two only on landscape
/// windows and open foldables) and a separate zoom.
class QuranDisplaySettings extends StatelessWidget {
  const QuranDisplaySettings({
    super.key,
    required this.readingMode,
    required this.twoPages,
    this.twoPagesAvailable = true,
    required this.zoomed,
    required this.pageFillsWidth,
    required this.flipDirection,
    required this.font,
    required this.fonts,
    required this.packFor,
    required this.onReadingMode,
    required this.onTwoPages,
    required this.onZoomed,
    required this.onFlipDirection,
    required this.onFont,
  });

  final QuranReadingMode readingMode;

  /// Two pages side by side on the screen now.
  final bool twoPages;

  /// Two pages can show on this screen: false on a portrait screen, where
  /// Two pages is off and the hint says to turn the screen.
  final bool twoPagesAvailable;

  /// The pages fill the width and scroll.
  final bool zoomed;

  /// One page on a portrait screen: it already fills the width, so zoom
  /// changes little here.
  final bool pageFillsWidth;
  final MushafFlipDirection flipDirection;
  final String font;

  /// Font family → label.
  final Map<String, String> fonts;
  final MushafPackService? Function(QuranReadingMode mode) packFor;
  final ValueChanged<QuranReadingMode> onReadingMode;
  final ValueChanged<bool> onTwoPages;
  final ValueChanged<bool> onZoomed;
  final ValueChanged<MushafFlipDirection> onFlipDirection;
  final ValueChanged<String> onFont;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    Widget section(String title, Widget child) => Padding(
      padding: EdgeInsets.only(top: space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HudaSectionHeader(title),
          SizedBox(height: space.xs),
          child,
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        section(
          l10n.settingsReadingMode,
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 360 ? 2 : 1;
              final width =
                  (constraints.maxWidth - space.sm * (columns - 1)) / columns;
              return Wrap(
                spacing: space.sm,
                runSpacing: space.sm,
                children: [
                  for (final mode in QuranReadingMode.values)
                    SizedBox(
                      width: width,
                      child: _ReadingModeTile(
                        mode: mode,
                        selected: mode == readingMode,
                        pack: packFor(mode),
                        onTap: () => onReadingMode(mode),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        if (readingMode.isMushaf) ...[
          // Pages and zoom are two choices: one or two pages, zoomed or
          // whole (owner round 3). Two pages only stand side by side on a
          // landscape screen or an open foldable (owner round 4).
          section(
            l10n.quranPages,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Choices<bool>(
                  key: const ValueKey('quran-display-pages'),
                  values: const [false, true],
                  selected: twoPages,
                  icon: (two) => two
                      ? HorizontalPageDisplayMode.doublePage.icon
                      : HorizontalPageDisplayMode.normal.icon,
                  label: (two) =>
                      two ? l10n.mushafDisplayDouble : l10n.mushafDisplaySingle,
                  enabled: (two) => !two || twoPagesAvailable,
                  onSelected: (two) {
                    HudaHaptics.selection(context);
                    onTwoPages(two);
                  },
                ),
                if (!twoPagesAvailable) ...[
                  SizedBox(height: space.xs),
                  Text(
                    l10n.quranTwoPagesSideways,
                    key: const ValueKey('quran-display-sideways'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                SizedBox(height: space.xs),
                SwitchListTile(
                  key: const ValueKey('quran-display-zoom'),
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(HorizontalPageDisplayMode.zoomed.icon),
                  title: Text(l10n.mushafDisplayZoomed),
                  subtitle: Text(
                    pageFillsWidth
                        ? l10n.quranZoomFillsAlready
                        : l10n.quranZoomHint,
                  ),
                  value: zoomed,
                  onChanged: (on) {
                    HudaHaptics.selection(context);
                    onZoomed(on);
                  },
                ),
              ],
            ),
          ),
          section(
            l10n.settingsFlipDirection,
            _Choices<MushafFlipDirection>(
              key: const ValueKey('quran-display-flip'),
              values: MushafFlipDirection.values,
              selected: flipDirection,
              icon: (direction) => direction.icon,
              label: (direction) => direction.localizedLabel(context),
              onSelected: onFlipDirection,
            ),
          ),
        ] else
          section(
            l10n.settingsQuranFont,
            Column(
              children: [
                for (final MapEntry(key: family, value: label) in fonts.entries)
                  Padding(
                    padding: EdgeInsets.only(bottom: space.xs),
                    child: _FontTile(
                      family: family,
                      label: label,
                      selected: family == font,
                      onTap: () => onFont(family),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One of a few options as choice chips that wrap (so a long label moves
/// to the next line whole, never breaks); an option that can't apply here
/// is off.
class _Choices<T> extends StatelessWidget {
  const _Choices({
    super.key,
    required this.values,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onSelected,
    this.enabled,
  });

  final List<T> values;
  final T selected;
  final IconData Function(T value) icon;
  final String Function(T value) label;
  final bool Function(T value)? enabled;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return Wrap(
      spacing: space.xs,
      runSpacing: space.xs,
      children: [
        for (final value in values)
          ChoiceChip(
            key: ValueKey('quran-choice-$value'),
            // Lit when chosen: the mark takes the chip's warm text.
            avatar: Icon(
              icon(value),
              size: 18,
              color: value == selected ? context.tokens.onChrome : null,
            ),
            label: Text(label(value)),
            showCheckmark: false,
            selected: value == selected,
            onSelected: (enabled?.call(value) ?? true)
                ? (_) {
                    if (value != selected) onSelected(value);
                  }
                : null,
          ),
      ],
    );
  }
}

/// A selectable option on the page: a hairline tile that turns lit-tinted
/// with a check when chosen.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.selected,
    required this.onTap,
    required this.child,
    required this.semanticsLabel,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: tokens.radius.control,
      side: BorderSide(
        color: selected ? scheme.primary : scheme.outlineVariant,
        width: selected ? tokens.stroke.fine : tokens.stroke.hairline,
      ),
    );
    return Semantics(
      selected: selected,
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surfaceContainerLowest,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: EdgeInsets.all(tokens.space.sm),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A reading mode, with its pack's state when it reads page images: the
/// download size, the progress, or "preparing".
class _ReadingModeTile extends StatelessWidget {
  const _ReadingModeTile({
    required this.mode,
    required this.selected,
    required this.onTap,
    this.pack,
  });

  final QuranReadingMode mode;
  final bool selected;
  final VoidCallback onTap;
  final MushafPackService? pack;

  @override
  Widget build(BuildContext context) {
    final pack = this.pack;
    if (pack == null) return _tile(context, null);
    return StreamBuilder<MushafPackState>(
      stream: pack.stateStream,
      initialData: pack.currentState,
      builder: (context, _) => _tile(context, pack),
    );
  }

  Widget _tile(BuildContext context, MushafPackService? pack) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = pack?.currentState;
    final busy =
        state != null &&
        !pack!.isReady &&
        (state.status == MushafPackStatus.downloading ||
            state.status == MushafPackStatus.extracting ||
            state.status == MushafPackStatus.loading);
    final String? status;
    if (pack == null || pack.isReady) {
      status = null;
    } else if (busy) {
      status = switch (state.status) {
        MushafPackStatus.downloading => '${(state.progress * 100).round()}%',
        MushafPackStatus.extracting => l10n.fontExtractingLabel,
        _ => l10n.fontLoadingLabel,
      };
    } else {
      status = l10n.mushafPackDownload(pack.pack.sizeLabel);
    }
    final label = mode.localizedLabel(context);
    return _OptionTile(
      selected: selected,
      onTap: busy ? () {} : onTap,
      semanticsLabel: [label, ?status].join(', '),
      child: Row(
        children: [
          Icon(mode.icon, color: selected ? scheme.primary : null),
          SizedBox(width: space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: theme.textTheme.labelLarge),
                if (status != null)
                  Text(
                    status,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (busy)
            const HudaLampSpinner(size: 20)
          else if (selected)
            Icon(Icons.check_rounded, color: scheme.primary, size: 20)
          else if (status != null)
            Icon(
              Icons.download_rounded,
              color: scheme.onSurfaceVariant,
              size: 20,
            ),
        ],
      ),
    );
  }
}

/// A font for the scrolling text, previewed with the bismillah.
class _FontTile extends StatelessWidget {
  const _FontTile({
    required this.family,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String family;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sample = Text(
      quranBismillah,
      textDirection: TextDirection.rtl,
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      style: context.type.ayah.copyWith(
        fontFamily: family,
        fontSize: 20,
        height: 1.6,
      ),
    );
    final check = Icon(Icons.check_rounded, color: scheme.primary, size: 20);
    // At large text the name and the sample stack.
    if (MediaQuery.textScalerOf(context).scale(10) > 14) {
      return _OptionTile(
        selected: selected,
        onTap: onTap,
        semanticsLabel: label,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.labelLarge),
                  sample,
                ],
              ),
            ),
            if (selected) ...[SizedBox(width: space.xs), check],
          ],
        ),
      );
    }
    return _OptionTile(
      selected: selected,
      onTap: onTap,
      semanticsLabel: label,
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
          SizedBox(width: space.sm),
          Expanded(
            child: Text(
              quranBismillah,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: context.type.ayah.copyWith(
                fontFamily: family,
                fontSize: 20,
                height: 1.6,
              ),
            ),
          ),
          if (selected) ...[
            SizedBox(width: space.xs),
            Icon(Icons.check_rounded, color: scheme.primary, size: 20),
          ],
        ],
      ),
    );
  }
}

/// Memorizing: hide the ayat and recite each to reveal it (speech
/// recognition, in beta). Start and stop, and while it runs, whether the
/// microphone is listening.
class QuranMemorizePanel extends StatelessWidget {
  const QuranMemorizePanel({
    super.key,
    required this.onStart,
    required this.onStop,
  });

  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return BlocBuilder<MemorizationCubit, MemorizationState>(
      builder: (context, state) {
        final active =
            state is MemorizationModeUpdated && state.isMemorizationMode;
        final listening = active && state.isListening;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: HudaEyebrow(l10n.beta),
            ),
            SizedBox(height: space.xs),
            Text(
              l10n.memorizationDescription,
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: space.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                SizedBox(width: space.xs),
                Expanded(
                  child: Text(
                    l10n.speechRecognitionDisclaimer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (active) ...[
              SizedBox(height: space.md),
              Row(
                children: [
                  Icon(
                    listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: listening ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  SizedBox(width: space.sm),
                  Expanded(
                    child: Text(
                      listening ? l10n.listening : l10n.microphoneIdle,
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
              SizedBox(height: space.xxs),
              Text(
                l10n.reciteToReveal,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            SizedBox(height: space.lg),
            if (active)
              OutlinedButton.icon(
                key: const ValueKey('quran-memorize-stop'),
                onPressed: onStop,
                icon: const Icon(Icons.stop_rounded),
                label: Text(l10n.stopMemorization),
              )
            else
              FilledButton.icon(
                key: const ValueKey('quran-memorize-start'),
                onPressed: onStart,
                icon: const Icon(Icons.psychology_rounded),
                label: Text(l10n.startMemorization),
              ),
          ],
        );
      },
    );
  }
}
