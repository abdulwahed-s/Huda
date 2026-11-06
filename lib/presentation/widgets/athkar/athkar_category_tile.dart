import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/ahtkar_item_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/screens/athkar_details.dart';
import 'package:huda/presentation/widgets/athkar/athkar_identity.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

/// Hisn al-Muslim chapters read every day, in the order they lead the
/// list: morning and evening, waking up, before sleeping, after the
/// prayer. Chapters missing from the API are skipped.
const athkarDailyChapters = [27, 1, 28, 25];

/// A chapter of athkar. It grows into the chapter's page when tapped.
class AthkarCategoryTile extends StatelessWidget {
  const AthkarCategoryTile({super.key, required this.item});

  final AthkarItem item;

  @override
  Widget build(BuildContext context) {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final english = item.titleEn.trim();
    final title = arabic || english.isEmpty ? item.titleAr : english;
    return HudaCard(
      key: ValueKey('athkar-chapter-${item.id}'),
      padding: EdgeInsets.zero,
      child: Builder(
        builder: (tileContext) => HudaContentRow(
          onTap: () => pushFromCard(
            tileContext,
            (_) => AthkarDetails.page(
              athkarId: '${item.id}',
              title: item.titleAr,
              titleEn: item.titleEn,
            ),
          ),
          arabicTitle: arabic ? null : item.titleAr,
          title: title,
          // The medallion's 8-petal rosette, with no horizon or rays: a
          // chapter isn't a time of day (owner round 1).
          leading: SizedBox.square(
            dimension: 40,
            child: Ornament(
              painter: RosettePainter(
                style: OrnamentStyle.of(
                  context,
                ).copyWith(stroke: context.tokens.stroke.hairline),
                count: athkarPetals,
                rings: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A loading tile shaped like [AthkarCategoryTile].
/// The sheen runs inside the card, so it keeps its surface.
class AthkarCategoryTileSkeleton extends StatelessWidget {
  const AthkarCategoryTileSkeleton({super.key, this.announce = false});

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
            const HudaSkeletonBlock(width: 40, height: 40, circle: true),
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

/// The chapter search: always in the page, so finding a chapter is typing.
/// Esc or the clear button empties it.
class AthkarSearchField extends StatelessWidget {
  const AthkarSearchField({
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
          key: const ValueKey('athkar-search'),
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchAthkarHint,
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
