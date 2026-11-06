import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_theme_scope.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_counter_pane.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_dhikr_list.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_dhikr_pane.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_dhikr_sheet.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_identity.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_reset_dialog.dart';

/// The Tasbih counter: an immersive night focus screen (see
/// `design/features/tasbih/brief.md`). Phones count with the dhikr as
/// chips; portrait tablets put the list under the counter; landscape
/// tablets, laptops and open folds put it beside the counter; tabletop
/// puts the counter above the fold and the list below.
class Tasbih extends StatefulWidget {
  const Tasbih({super.key});

  @override
  State<Tasbih> createState() => _TasbihState();
}

class _TasbihState extends State<Tasbih> {
  bool _retrying = false;

  /// A just-removed dhikr, kept here so its Undo outlives the list or the
  /// sheet that showed it.
  final _undo = TasbihUndo();

  @override
  void dispose() {
    _undo.dispose();
    super.dispose();
  }

  /// Very wide windows keep the bar, the list and the counter one
  /// composition.
  static const double _maxCompositionWidth = 1280;

  void _retry() {
    setState(() => _retrying = true);
    context.read<TasbihCubit>().loadTasbih();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    return HudaNight(
      child: _NightOverlays(
        child: HudaRevealScope(
          child: BlocConsumer<TasbihCubit, TasbihState>(
            listenWhen: (_, state) => state is! TasbihLoading,
            listener: (_, _) {
              if (_retrying) setState(() => _retrying = false);
            },
            builder: (context, state) {
              final loaded = state is TasbihLoaded && state.notes.isNotEmpty
                  ? state
                  : null;
              Widget page = HudaImmersiveScaffold(
                actions: [if (loaded != null) ..._actions(context, loaded)],
                body: HudaStateSwitcher(
                  stateKey: switch (state) {
                    // Where the list is a pane, it stays through the last
                    // dhikr's removal (its Undo lives there) and adds the
                    // first one.
                    TasbihLoaded(:final notes)
                        when notes.isEmpty &&
                            !_TasbihArrangement.listInline(context) =>
                      'empty',
                    TasbihLoading() when _retrying => TasbihError,
                    _ => state.runtimeType,
                  },
                  child: SizedBox.expand(child: _body(context, state)),
                ),
              );
              // No title on screen (the page is plainly Tasbih); screen
              // readers still hear its name.
              page = Semantics(
                container: true,
                explicitChildNodes: true,
                label: l10n.tasbih,
                child: page,
              );
              // Always wrapped, so the tree (and the pane's Undo) survives
              // the list emptying.
              page = _Keys(state: loaded, child: page);
              if (size.width <= _maxCompositionWidth ||
                  FoldInfo.of(context).hasFold) {
                return page;
              }
              return Center(
                child: SizedBox(
                  width: _maxCompositionWidth,
                  child: MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(size: Size(_maxCompositionWidth, size.height)),
                    child: page,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context, TasbihLoaded state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<TasbihCubit>();
    return [
      // One way to the list per layout: where it's on the screen (the
      // pane), it's edited there and the bar has no list button.
      if (!_TasbihArrangement.listInline(context))
        IconButton(
          tooltip: l10n.tasbihYourDhikr,
          onPressed: () => showTasbihDhikrSheet(context, _undo),
          icon: const Icon(Icons.format_list_bulleted_rounded),
        ),
      // Only devices that can vibrate offer the setting (by the theme's
      // platform, as the haptics themselves decide).
      if (HudaHaptics.available(context))
        // The icon says the state (vibrating or silent) and looks like
        // the other actions in the bar and in the Duo's side column alike;
        // screen readers hear it as a toggle.
        Semantics(
          toggled: state.mode,
          child: IconButton(
            tooltip: state.mode ? l10n.vibrate : l10n.silent,
            onPressed: () {
              cubit.changeMode(!state.mode);
              // A switch flip; felt only when switching vibration on.
              HudaHaptics.selection(context, enabled: !state.mode);
            },
            icon: Icon(
              state.mode ? Icons.vibration_rounded : Icons.mobile_off_rounded,
            ),
          ),
        ),
      IconButton(
        tooltip: l10n.reset,
        onPressed: state.currentCount > 0
            ? () => showTasbihResetDialog(context)
            : null,
        icon: const Icon(Icons.restart_alt_rounded),
      ),
    ];
  }

  Widget _body(BuildContext context, TasbihState state) {
    final l10n = AppLocalizations.of(context)!;
    switch (state) {
      case TasbihLoaded(:final notes) when notes.isNotEmpty:
        return _TasbihArrangement(
          counter: ({required showChips, required sideBySide}) => _CounterSlot(
            empty: false,
            child: TasbihCounterPane(
              state: state,
              undo: _undo,
              showChips: showChips,
              sideBySide: sideBySide,
            ),
          ),
          list: ({required belowToolbar}) => TasbihDhikrPane(
            state: state,
            undo: _undo,
            belowToolbar: belowToolbar,
          ),
        );
      case TasbihLoaded() when _TasbihArrangement.listInline(context):
        // The empty counter beside the pane, which adds the first dhikr.
        return _TasbihArrangement(
          counter: ({required showChips, required sideBySide}) => _CounterSlot(
            empty: true,
            child: _BelowBar(
              child: HudaEmptyState(
                identity: tasbihIdentity,
                title: l10n.noDhikrYet,
                message: l10n.tasbihEmptyMessage,
              ),
            ),
          ),
          list: ({required belowToolbar}) => TasbihDhikrPane(
            state: state,
            undo: _undo,
            belowToolbar: belowToolbar,
          ),
        );
      case TasbihLoaded():
        // Phones: add the first dhikr, or put back the one just removed
        // (the empty state is where it was; no toast over it).
        return _BelowBar(
          child: ListenableBuilder(
            listenable: _undo,
            builder: (context, _) => HudaStateView(
              identity: tasbihIdentity,
              title: l10n.noDhikrYet,
              message: l10n.tasbihEmptyMessage,
              actions: [
                FilledButton(
                  onPressed: () => showTasbihDhikrSheet(context, _undo),
                  child: Text(l10n.addDhikr),
                ),
                if (_undo.pending)
                  Tooltip(
                    message: '${l10n.undo}: ${_undo.note?.text ?? ''}',
                    child: TextButton.icon(
                      onPressed: () => _undo.undo(context.read<TasbihCubit>()),
                      icon: const Icon(Icons.undo_rounded),
                      label: Text(l10n.undo),
                    ),
                  ),
              ],
            ),
          ),
        );
      case TasbihError():
      case TasbihLoading() when _retrying:
        return _BelowBar(
          child: HudaErrorState(
            message: l10n.tasbihLoadError,
            onRetry: _retry,
            retrying: _retrying,
          ),
        );
      case TasbihLoading():
      case TasbihInitial():
        return const _TasbihSkeleton();
    }
  }
}

/// The dhikr sheet and the reset dialog sit a step above the night page,
/// in its own hue rather than neutral gray, edged with a gilt hairline.
class _NightOverlays extends StatelessWidget {
  const _NightOverlays({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final surface = tasbihOverlaySurface(context);
    final edge = BorderSide(
      color: tokens.gilt.withValues(alpha: 0.28),
      width: tokens.stroke.hairline,
    );
    final radius = Radius.circular(tokens.radius.xl);
    return Theme(
      data: theme.copyWith(
        dialogTheme: theme.dialogTheme.copyWith(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(radius),
            side: edge,
          ),
        ),
        bottomSheetTheme: theme.bottomSheetTheme.copyWith(
          backgroundColor: surface,
          modalBackgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: radius),
            side: edge,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// Counting from the keyboard: Space or Enter counts, Backspace or minus
/// steps back.
class _Keys extends StatelessWidget {
  const _Keys({required this.state, required this.child});

  final TasbihLoaded? state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TasbihCubit>();
    final state = this.state;
    // Keys typed into the list pane's add field are text, not counts.
    bool typing() =>
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorStateOfType<EditableTextState>() !=
        null;
    void count() {
      if (state != null && !typing()) countTasbih(context, state);
    }

    void back() {
      if (state != null && !typing()) cubit.decrement();
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): count,
        const SingleActivator(LogicalKeyboardKey.enter): count,
        const SingleActivator(LogicalKeyboardKey.numpadAdd): count,
        const SingleActivator(LogicalKeyboardKey.backspace): back,
        const SingleActivator(LogicalKeyboardKey.minus): back,
        const SingleActivator(LogicalKeyboardKey.numpadSubtract): back,
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}

typedef _CounterBuilder =
    Widget Function({required bool showChips, required bool sideBySide});
typedef _ListBuilder = Widget Function({required bool belowToolbar});

/// Picks the arrangement for the space and the fold. The content and its
/// skeleton share it, so nothing pops in when the list arrives.
class _TasbihArrangement extends StatelessWidget {
  const _TasbihArrangement({required this.counter, required this.list});

  final _CounterBuilder counter;
  final _ListBuilder list;

  /// The list joins the counter from small-tablet width: the counter alone
  /// would be a phone layout floating in a tablet.
  static const double _twoPaneMinWidth = 720;

  static _Layout _layoutOf(BuildContext context) {
    final fold = FoldInfo.of(context);
    final size = MediaQuery.sizeOf(context);
    // Any horizontal fold, flat or half open: the counter above it, the
    // list below, so nothing moves when the device bends.
    if (fold.separatorAxis == Axis.horizontal) {
      return _Layout.tabletop;
    }
    final tall = size.height >= size.width * 1.15;
    if (!fold.hasFold && size.width >= 600 && tall) return _Layout.stacked;
    // Side by side, except on short windows without a fold (phone
    // landscape), where the counter and its chips fit better.
    if (AdaptivePanes.showsTwoPanes(
          size.width,
          fold,
          twoPaneMinWidth: _twoPaneMinWidth,
        ) &&
        (!context.windowClass.isCompactHeight || fold.splitsHorizontally)) {
      return _Layout.panes;
    }
    return _Layout.counter;
  }

  /// Whether the dhikr list is on the screen (a pane) rather than behind
  /// the bar's list button (phones).
  static bool listInline(BuildContext context) =>
      _layoutOf(context) != _Layout.counter;

  @override
  Widget build(BuildContext context) {
    final fold = FoldInfo.of(context);
    final data = MediaQuery.of(context);

    // Two stacked halves: [top] gets the status bar, [bottom] the
    // navigation bar.
    Widget stack(Widget top, Widget bottom, {double? split, double gap = 0}) {
      Widget half(Widget child, {required bool upper}) => MediaQuery(
        data: data.copyWith(
          padding: upper
              ? data.padding.copyWith(bottom: 0)
              : data.padding.copyWith(top: 0),
          viewPadding: upper
              ? data.viewPadding.copyWith(bottom: 0)
              : data.viewPadding.copyWith(top: 0),
        ),
        child: child,
      );
      return Column(
        children: [
          if (split != null)
            SizedBox(height: split, child: half(top, upper: true))
          else
            Expanded(flex: 11, child: half(top, upper: true)),
          SizedBox(height: gap),
          Expanded(flex: 9, child: half(bottom, upper: false)),
        ],
      );
    }

    switch (_layoutOf(context)) {
      case _Layout.tabletop:
        // Look at the top half, touch the bottom half; also for a flat
        // horizontal band, so the ring never sits on it.
        return stack(
          counter(showChips: false, sideBySide: true),
          list(belowToolbar: false),
          split: fold.start,
          gap: fold.end - fold.start,
        );
      case _Layout.stacked:
        // Portrait tablets: the counter above, the whole list below.
        return stack(
          counter(showChips: false, sideBySide: false),
          list(belowToolbar: false),
        );
      case _Layout.panes:
        return AdaptivePanes(
          twoPaneMinWidth: _twoPaneMinWidth,
          primaryFraction: 0.4,
          minPrimaryWidth: 360,
          maxPrimaryWidth: 480,
          divider: const SizedBox(width: 1),
          primary: list(belowToolbar: true),
          secondary: counter(showChips: false, sideBySide: false),
        );
      case _Layout.counter:
        return counter(showChips: true, sideBySide: false);
    }
  }
}

/// How the counter and the dhikr list share the window.
enum _Layout {
  /// A horizontal fold (tabletop, or flat): the counter above the fold,
  /// the list below.
  tabletop,

  /// Portrait tablets: the counter over the list.
  stacked,

  /// The list beside the counter.
  panes,

  /// The counter alone with dhikr chips (phones, short windows).
  counter,
}

/// The counter's side of an inline layout: removing the last dhikr or
/// adding the first cross-fades between the counter and the empty state,
/// while the list pane beside it stays.
class _CounterSlot extends StatelessWidget {
  const _CounterSlot({required this.empty, required this.child});

  final bool empty;
  final Widget child;

  @override
  Widget build(BuildContext context) => HudaStateSwitcher(
    stateKey: empty,
    sequential: true,
    child: SizedBox.expand(child: child),
  );
}

/// A full-page state under the transparent immersive bar.
class _BelowBar extends StatelessWidget {
  const _BelowBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      // The scaffold's top padding already clears the transparent bar.
      top: MediaQuery.paddingOf(context).top,
    ),
    child: child,
  );
}

/// Loading: the counter's own arrangement with an unlit strand, and the
/// list's rows, in tones of the night chrome.
class _TasbihSkeleton extends StatelessWidget {
  const _TasbihSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    // The shared skeleton draws in surface containers; on the night
    // chrome they are tints of the warm text instead of neutral gray.
    final tinted = theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        surfaceContainerHighest: tokens.onChrome.withValues(alpha: 0.1),
        surfaceContainerLow: tokens.onChrome.withValues(alpha: 0.04),
      ),
    );
    Widget block(double width, double height) =>
        HudaSkeletonBlock(width: width, height: height);
    return Theme(
      data: tinted,
      child: HudaSkeleton(
        child: _TasbihArrangement(
          counter: ({required showChips, required sideBySide}) =>
              TasbihCounterFrame(
                sideBySide: sideBySide,
                words: Center(child: block(180, 32)),
                medallion: (diameter) => SizedBox.square(
                  dimension: diameter,
                  child: Ornament(
                    painter: TasbihBeadRingPainter(
                      style: OrnamentStyle.of(context, onChrome: true),
                      empty: tokens.gilt.withValues(alpha: 0.22),
                      filled: 0,
                      clockwise:
                          Directionality.of(context) == TextDirection.ltr,
                    ),
                  ),
                ),
                minus: const Center(
                  child: HudaSkeletonBlock(width: 48, height: 48, circle: true),
                ),
                chips: showChips
                    ? (padding) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: padding,
                        child: Row(
                          children: [
                            for (var i = 0; i < 3; i++) ...[
                              if (i > 0) SizedBox(width: space.xs),
                              block(88, 40),
                            ],
                          ],
                        ),
                      )
                    : null,
              ),
          list: ({required belowToolbar}) => SafeArea(
            top: belowToolbar,
            bottom: false,
            // Never taller than the pane; the rows just run out of view.
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(space.xl, space.md, space.xl, 0),
              child: ReadableWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: block(96, 14),
                    ),
                    SizedBox(height: space.md),
                    for (var i = 0; i < 4; i++) ...[
                      block(double.infinity, 56),
                      SizedBox(height: space.xs),
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
