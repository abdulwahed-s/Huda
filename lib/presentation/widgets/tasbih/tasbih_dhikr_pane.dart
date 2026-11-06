import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_dhikr_list.dart';

/// The dhikr list beside or below the counter wherever there is room for
/// it: pick what to count, see every count and the total, add and remove
/// dhikr. Everything about the list happens here; these layouts have no
/// dhikr sheet and no list button in the bar.
class TasbihDhikrPane extends StatelessWidget {
  const TasbihDhikrPane({
    super.key,
    required this.state,
    required this.undo,
    this.belowToolbar = true,
  });

  final TasbihLoaded state;
  final TasbihUndo undo;

  /// Whether the pane starts under the transparent app bar (side by side),
  /// or below the counter (tabletop).
  final bool belowToolbar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<TasbihCubit>();
    final total = state.notes.fold<int>(0, (sum, n) => sum + n.count);
    return LayoutBuilder(
      builder: (context, constraints) {
        // A pane, but in a big window: at least the medium gutter.
        final gutter = math.max(space.gutter(constraints.maxWidth), space.xl);
        // The scaffold's top padding already clears the transparent bar.
        final padding = context.scrollPadding(
          EdgeInsets.fromLTRB(gutter, space.md, gutter, space.md),
          includeTop: belowToolbar,
        );
        return SingleChildScrollView(
          padding: padding,
          // Top-aligned: the list runs down the pane and scrolls.
          child: ReadableWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The total rides on the header line, so it's in view at
                // rest however long the list is.
                HudaReveal(
                  child: HudaSectionHeader(
                    l10n.tasbihYourDhikr,
                    trailing: state.notes.isEmpty
                        ? null
                        : Semantics(
                            container: true,
                            label: '${l10n.total}: $total',
                            excludeSemantics: true,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  l10n.total,
                                  style: text.labelMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(width: space.xs),
                                HudaNumberRoll(
                                  value: total,
                                  style: text.titleMedium!.copyWith(
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                // Adding comes first, as in the phone sheet: it stays in
                // view however long the list grows.
                HudaReveal(index: 1, child: TasbihDhikrComposer(cubit: cubit)),
                SizedBox(height: space.md),
                // Keyed: it keeps its Undo when the list empties.
                TasbihDhikrList(
                  key: const ValueKey('tasbih-dhikr-list'),
                  state: state,
                  cubit: cubit,
                  undo: undo,
                  revealFrom: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
