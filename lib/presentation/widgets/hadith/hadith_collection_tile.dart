import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/screens/hadith_chapters.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/hadith/hadith_identity.dart';
import 'package:huda/presentation/widgets/hadith/hadith_refs.dart';

/// A hadith collection. It grows into the collection's screen when tapped.
/// A collection whose hadith aren't in yet is a quiet tile that says so
/// (it used to answer a tap with a "Coming soon" snackbar).
class HadithCollectionTile extends StatelessWidget {
  const HadithCollectionTile({super.key, required this.collection});

  final HadithCollectionRef collection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final arabicUi = Localizations.localeOf(context).languageCode == 'ar';
    final available = collection.available;
    final count = collection.hadithCount;
    return HudaCard(
      key: ValueKey('hadith-collection-${collection.slug}'),
      padding: EdgeInsets.zero,
      child: Builder(
        builder: (tileContext) => HudaContentRow(
          onTap: available
              ? () => pushFromCard(
                  tileContext,
                  (_) => HadithChapters.page(collection: collection),
                )
              : null,
          arabicTitle: arabicUi ? null : collection.arabicTitle,
          title: collection.title,
          meta: !available
              ? l10n.comingSoon
              : count == null
              ? null
              : l10n.hadithCount(count),
          leading: HadithFolioMark(quiet: !available),
        ),
      ),
    );
  }
}

/// A loading tile shaped like [HadithCollectionTile].
class HadithCollectionTileSkeleton extends StatelessWidget {
  const HadithCollectionTileSkeleton({super.key, this.announce = false});

  /// Reads "Loading" (one tile per screen does).
  final bool announce;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return HudaCard(
      padding: EdgeInsets.symmetric(horizontal: space.md, vertical: space.sm),
      child: HudaSkeleton(
        announce: announce,
        child: Row(
          children: [
            const HudaSkeletonBlock(width: 40, height: 44),
            SizedBox(width: space.md),
            Expanded(
              child: HudaSkeletonLines(
                lines: 3,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
