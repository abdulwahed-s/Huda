import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_dhikr_chips.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_dhikr_list.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_dhikr_row.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_identity.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_medallion.dart';

void countTasbih(BuildContext context, TasbihLoaded state) {
  final focus = FocusManager.instance.primaryFocus;
  if (focus?.context?.findAncestorStateOfType<EditableTextState>() != null) {
    focus!.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
  }
  final milestone = (state.currentCount + 1) % tasbihBeads == 0;
  context.read<TasbihCubit>().increment();
  if (milestone) {
    HudaHaptics.medium(context, enabled: state.mode);
  } else {
    HudaHaptics.count(context, enabled: state.mode);
  }
}

class TasbihCounterPane extends StatelessWidget {
  const TasbihCounterPane({
    super.key,
    required this.state,
    required this.undo,
    required this.showChips,
    this.sideBySide = false,
  });

  final TasbihLoaded state;

  final TasbihUndo undo;
  final bool showChips;
  final bool sideBySide;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TasbihCubit>();
    final note = state.notes[state.selectedNoteIndex];
    final count = state.currentCount;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: () => countTasbih(context, state),
      child: TasbihCounterFrame(
        sideBySide: sideBySide,
        words: TasbihWords(index: state.selectedNoteIndex, text: note.text),
        medallion: (diameter) => TasbihMedallion(
          count: count,
          dhikrIndex: state.selectedNoteIndex,
          diameter: diameter,
          onCount: () => countTasbih(context, state),
        ),
        minus: _Minus(onMinus: count > 0 ? cubit.decrement : null),
        chips: showChips
            ? (padding) => TasbihDhikrChips(
                notes: state.notes,
                selected: state.selectedNoteIndex,
                onSelected: cubit.selectNote,
                undo: undo,
                onUndo: () => undo.undo(cubit),
                padding: padding,
              )
            : null,
      ),
    );
  }
}

class TasbihCounterFrame extends StatelessWidget {
  const TasbihCounterFrame({
    super.key,
    required this.words,
    required this.medallion,
    required this.minus,
    this.chips,
    this.sideBySide = false,
  });

  final Widget words;
  final Widget Function(double diameter) medallion;
  final Widget minus;

  final Widget Function(EdgeInsets padding)? chips;
  final bool sideBySide;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final sideBySide = this.sideBySide || context.windowClass.isCompactHeight;
    final insets = MediaQuery.paddingOf(context);
    final sides = EdgeInsets.only(left: insets.left, right: insets.right);
    return SafeArea(
      left: false,
      right: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = space.gutter(constraints.maxWidth - insets.horizontal);
          final maxDiameter =
              context.windowClass.height >= WindowHeightClass.expanded
              ? 520.0
              : 380.0;

          if (sideBySide) {
            final diameter = math
                .min(
                  constraints.maxHeight - space.md,
                  (constraints.maxWidth - insets.horizontal) * 0.55,
                )
                .clamp(120.0, maxDiameter);
            final rtl = Directionality.of(context) == TextDirection.rtl;
            final trailingInset = rtl ? insets.left : insets.right;
            final trailing = EdgeInsetsDirectional.only(end: gutter);
            final chips = this.chips?.call(
              EdgeInsetsDirectional.only(
                end: gutter,
              ).resolve(Directionality.of(context)),
            );
            return Padding(
              padding: EdgeInsetsDirectional.only(
                start: gutter + (rtl ? insets.right : insets.left),
                end: trailingInset,
                bottom: space.md,
              ),
              child: Row(
                children: [
                  HudaReveal(index: 1, child: medallion(diameter)),
                  SizedBox(width: space.xl),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: trailing,
                              child: HudaReveal(child: words),
                            ),
                            SizedBox(height: space.md),
                            Padding(
                              padding: trailing,
                              child: HudaReveal(index: 2, child: minus),
                            ),
                            if (chips != null) ...[
                              SizedBox(height: space.md),
                              HudaReveal(index: 3, child: chips),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final chips = this.chips?.call(
            EdgeInsets.only(
              left: gutter + insets.left,
              right: gutter + insets.right,
            ),
          );
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: sides,
                  child: LayoutBuilder(
                    builder: (context, inner) {
                      final reserved = 170 * math.min(textScale, 2.0);
                      final diameter = math
                          .min(
                            math.min(inner.maxWidth - gutter * 2, maxDiameter),
                            inner.maxHeight - reserved,
                          )
                          .clamp(168.0, maxDiameter);
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: inner.maxHeight,
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: HudaChromeFrame.hasSideChrome(context)
                                  ? space.xxl
                                  : space.md,
                              bottom: space.md,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: gutter,
                                  ),
                                  child: ReadableWidth(
                                    maxWidth: 560,
                                    alignment: Alignment.center,
                                    child: HudaReveal(child: words),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: chips != null
                                            ? space.xs
                                            : space.xl,
                                        bottom: space.md,
                                      ),
                                      child: HudaReveal(
                                        index: 1,
                                        child: medallion(diameter),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: gutter,
                                      ),
                                      child: HudaReveal(index: 2, child: minus),
                                    ),
                                  ],
                                ),
                                const SizedBox.shrink(),
                                if (chips != null) const SizedBox.shrink(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (chips != null)
                Padding(
                  padding: EdgeInsets.only(bottom: space.md),
                  child: HudaReveal(index: 3, child: chips),
                ),
            ],
          );
        },
      ),
    );
  }
}

class TasbihWords extends StatelessWidget {
  const TasbihWords({super.key, required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final direction = tasbihTextDirection(text);
    final scheme = Theme.of(context).colorScheme;
    final style = direction == TextDirection.rtl
        ? context.type.dhikr
        : Theme.of(context).textTheme.headlineSmall!;
    return HudaStateSwitcher(
      stateKey: index,
      alignment: Alignment.center,
      sequential: true,
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: direction,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: style.copyWith(color: scheme.onSurface),
      ),
    );
  }
}

class _Minus extends StatelessWidget {
  const _Minus({required this.onMinus});

  final VoidCallback? onMinus;

  @override
  Widget build(BuildContext context) => Center(
    child: IconButton.outlined(
      tooltip: AppLocalizations.of(context)!.minus,
      onPressed: onMinus,
      icon: const Icon(Icons.remove_rounded),
    ),
  );
}
