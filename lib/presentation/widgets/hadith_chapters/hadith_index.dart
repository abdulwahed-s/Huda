import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/hadith/hadith_identity.dart';
import 'package:huda/presentation/widgets/hadith/hadith_refs.dart';

class HadithCollectionHeader extends StatefulWidget {
  const HadithCollectionHeader({
    super.key,
    required this.collection,
    this.bookCount,
  });

  final HadithCollectionRef collection;

  final int? bookCount;

  @override
  State<HadithCollectionHeader> createState() => _HadithCollectionHeaderState();
}

class _HadithCollectionHeaderState extends State<HadithCollectionHeader> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final collection = widget.collection;
    final arabicUi = Localizations.localeOf(context).languageCode == 'ar';
    final arabic = collection.arabicTitle;
    final count = collection.hadithCount;
    final books = widget.bookCount;
    final meta = [
      if (books != null && books > 0) l10n.hadithBookCount(books),
      if (count != null && count > 0) l10n.hadithCount(count),
    ].join('  ·  ');
    final intro = collection.intro;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!arabicUi && arabic != null)
          Text(
            arabic,
            textDirection: TextDirection.rtl,
            style: context.type.arabicTitle.copyWith(
              fontSize: 26,
              color: scheme.onSurface,
            ),
          ),
        if (meta.isNotEmpty)
          Text(
            meta,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        if (intro != null) ...[
          SizedBox(height: tokens.space.sm),
          AnimatedSize(
            duration: tokens.motion.of(context, tokens.motion.medium),
            curve: tokens.motion.standard,
            alignment: AlignmentDirectional.topStart,
            child: Text(
              intro,
              maxLines: _open ? null : 3,
              overflow: _open ? null : TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const ValueKey('hadith-intro-more'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: tokens.space.xs),
              ),
              onPressed: () => setState(() => _open = !_open),
              child: Text(_open ? l10n.showLess : l10n.readMore),
            ),
          ),
        ],
      ],
    );
  }
}

class HadithBookSearchField extends StatelessWidget {
  const HadithBookSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  void _clear() {
    controller.clear();
    onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: tokens.radius.control,
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _clear},
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          key: const ValueKey('hadith-book-search'),
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.hadithSearchBooks,
            filled: true,
            fillColor: scheme.surfaceContainerLowest,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.athkarClearSearch,
                    onPressed: _clear,
                    icon: const Icon(Icons.close_rounded),
                  ),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: scheme.primary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

class HadithBookRow extends StatelessWidget {
  const HadithBookRow({
    super.key,
    required this.book,
    required this.onTap,
    this.selected = false,
  });

  final HadithBookRef book;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final arabicUi = Localizations.localeOf(context).languageCode == 'ar';
    final first = book.firstHadith;
    final last = book.lastHadith;
    final arabic = book.arabicTitle;
    return Semantics(
      selected: selected,
      child: HudaContentRow(
        key: ValueKey('hadith-book-${book.number}'),
        selected: selected,
        onTap: onTap,
        arabicTitle: arabicUi || arabic == book.title ? null : arabic,
        title: book.title,
        meta: first == null || last == null
            ? null
            : first == last
            ? l10n.hadithNumber('$first')
            : l10n.hadithRange('$first', '$last'),
        leading: SizedBox.square(
          dimension: 40,
          child: CustomPaint(
            painter: RuledFramePainter(
              style: OrnamentStyle.of(context, quiet: !selected),
              rules: const [0, 3],
              corners: CornerMark.none,
            ),
            child: Center(
              child: Text(
                book.shownNumber,
                maxLines: 1,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HadithBookRowSkeleton extends StatelessWidget {
  const HadithBookRowSkeleton({super.key, this.announce = false});

  final bool announce;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: space.md, vertical: space.sm),
      child: HudaSkeleton(
        announce: announce,
        child: Row(
          children: [
            const HudaSkeletonBlock(width: 40, height: 40),
            SizedBox(width: space.md),
            Expanded(
              child: HudaSkeletonLines(
                lines: 2,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HadithTitlePage extends StatelessWidget {
  const HadithTitlePage({
    super.key,
    required this.collection,
    this.bookCount,
    this.showArt = true,
    this.canChoose = true,
  });

  final HadithCollectionRef collection;
  final int? bookCount;

  final bool showArt;

  final bool canChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final space = context.tokens.space;
    final arabicUi = Localizations.localeOf(context).languageCode == 'ar';
    final arabic = collection.arabicTitle;
    final count = collection.hadithCount;
    final books = bookCount;
    final meta = [
      if (books != null && books > 0) l10n.hadithBookCount(books),
      if (count != null && count > 0) l10n.hadithCount(count),
    ].join('  ·  ');
    final intro = collection.intro;
    final short = MediaQuery.sizeOf(context).height < 480;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          space.xl,
          short ? space.lg : space.xxl,
          space.xl,
          (short ? space.lg : space.xxl) + MediaQuery.paddingOf(context).bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                if (showArt && !short) ...[
                  HadithInk(
                    builder: (context, ink) => SizedBox(
                      width: 132,
                      height: 160,
                      child: Ornament(
                        painter: HadithFolioPainter(
                          style: OrnamentStyle.of(context),
                          inkOf: ink,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: space.xl),
                ],
                if (!arabicUi && arabic != null)
                  Text(
                    arabic,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: context.type.arabicTitle.copyWith(
                      fontSize: 30,
                      color: scheme.onSurface,
                    ),
                  ),
                Text(
                  collection.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  SizedBox(height: space.xs),
                  Text(
                    meta,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (intro != null) ...[
                  SizedBox(height: space.lg),
                  Text(
                    intro,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ],
                if (canChoose) ...[
                  SizedBox(height: space.xl),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                      SizedBox(width: space.xs),
                      Flexible(
                        child: Text(
                          l10n.hadithChooseBook,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
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
    );
  }
}
