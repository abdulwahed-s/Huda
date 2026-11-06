import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:intl/intl.dart' show Bidi;

/// The direction a dhikr's own text runs in: people write them in Arabic
/// or in their own language.
TextDirection tasbihTextDirection(String text) =>
    Bidi.detectRtlDirectionality(text) ? TextDirection.rtl : TextDirection.ltr;

/// A dhikr in a list: Arabic in the Arabic title role, other languages in
/// a Latin title (the Arabic line height leaves gaps between Latin lines).
TextStyle tasbihDhikrTitleStyle(BuildContext context, String text) =>
    tasbihTextDirection(text) == TextDirection.rtl
    ? context.type.arabicTitle.copyWith(fontWeight: FontWeight.w400)
    : Theme.of(
        context,
      ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w400);

/// A dhikr on a chip: the Arabic label role, or a Latin label.
TextStyle tasbihDhikrLabelStyle(BuildContext context, String text) =>
    tasbihTextDirection(text) == TextDirection.rtl
    ? context.type.arabicLabel
    : Theme.of(
        context,
      ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w400);

/// One dhikr with its count. The selected one is lit (the chrome, a step
/// brighter than the night page). With [onDelete] it can be removed.
class TasbihDhikrRow extends StatelessWidget {
  const TasbihDhikrRow({
    super.key,
    required this.note,
    required this.selected,
    required this.onTap,
    this.onDelete,
  });

  final TasbihNote note;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final scheme = Theme.of(context).colorScheme;
    final duration = tokens.motion.of(context, tokens.motion.short);
    final foreground = selected ? tokens.onChrome : scheme.onSurface;
    final onDelete = this.onDelete;
    return Semantics(
      selected: selected,
      child: AnimatedContainer(
        duration: duration,
        curve: tokens.motion.standard,
        decoration: ShapeDecoration(
          color: selected
              ? tokens.lit
              : scheme.onSurface.withValues(alpha: 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: tokens.radius.card,
            side: BorderSide(
              color: selected ? tokens.lit : scheme.outlineVariant,
            ),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: RoundedRectangleBorder(borderRadius: tokens.radius.card),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: space.md,
                  end: onDelete == null ? space.md : space.xxs,
                  top: space.xs,
                  bottom: space.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.text,
                        textDirection: tasbihTextDirection(note.text),
                        // Lines up with the rest of the list, whatever
                        // the dhikr's own direction.
                        textAlign:
                            Directionality.of(context) == TextDirection.rtl
                            ? TextAlign.right
                            : TextAlign.left,
                        style: tasbihDhikrTitleStyle(
                          context,
                          note.text,
                        ).copyWith(color: foreground),
                      ),
                    ),
                    SizedBox(width: space.sm),
                    Text(
                      '${note.count}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected
                            ? tokens.onChrome
                            : scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (onDelete != null)
                      // Read with its dhikr, so five Delete buttons aren't
                      // announced alike.
                      Semantics(
                        button: true,
                        label: '${l10n.delete}: ${note.text}',
                        onTap: onDelete,
                        excludeSemantics: true,
                        child: IconButton(
                          tooltip: l10n.delete,
                          onPressed: onDelete,
                          color: selected
                              ? tokens.onChromeMuted
                              : scheme.onSurfaceVariant,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                          ),
                        ),
                      ),
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
