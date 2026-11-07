import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/checklist/checklist_cubit.dart';
import 'package:huda/data/models/checklist_item.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/checklist/checklist_add_sheet.dart';
import 'package:huda/presentation/widgets/checklist/checklist_day.dart';
import 'package:huda/presentation/widgets/checklist/checklist_identity.dart';
import 'package:huda/presentation/widgets/checklist/checklist_items.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';

/// The daily checklist: the day's inlaid star with how much is done and
/// the streak, then the day's items in groups. Phones stack them; from
/// 840 wide and on folds the day sits beside the items; tabletop puts the
/// day above the band and the items below. ‹ › and a swipe change the day;
/// only today's items can be checked.
class IslamicChecklistScreen extends StatefulWidget {
  const IslamicChecklistScreen({super.key});

  @override
  State<IslamicChecklistScreen> createState() => _IslamicChecklistScreenState();
}

class _IslamicChecklistScreenState extends State<IslamicChecklistScreen> {
  // The route provides the cubit (and closes it).
  late final ChecklistCubit _cubit = context.read<ChecklistCubit>();
  Locale? _locale;
  bool _retrying = false;

  /// Custom items removed but still undoable: hidden now, removed from
  /// storage when their toast ends.
  final Map<String, Timer> _pending = {};

  /// Which way the last day change went, for the slide.
  bool _forward = true;

  /// The day card, so completing the day can bring it into view.
  final _cardKey = GlobalKey(debugLabel: 'checklist-day-card');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    final first = _locale == null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _locale == locale) return;
      _locale = locale;
      try {
        await _cubit.updateLocalizedTitles(AppLocalizations.of(context)!);
      } catch (_) {}
      if (first && _cubit.state is ChecklistInitial) _cubit.loadChecklist();
    });
  }

  @override
  void dispose() {
    // Leaving ends the Undo window.
    for (final entry in _pending.entries) {
      entry.value.cancel();
      _cubit.removeCustomItem(entry.key);
    }
    super.dispose();
  }

  List<ChecklistItem> _visible(ChecklistLoaded state) => [
    for (final item in state.dailyChecklist.items)
      if (!_pending.containsKey(item.id)) item,
  ];

  int _done(ChecklistLoaded state, List<ChecklistItem> items) => items
      .where((item) => state.dailyChecklist.completedItems[item.id] == true)
      .length;

  void _toggle(ChecklistLoaded state, ChecklistItem item, bool done) {
    final items = _visible(state);
    final after = items
        .where(
          (other) => other.id == item.id
              ? done
              : state.dailyChecklist.completedItems[other.id] == true,
        )
        .length;
    if (!done) {
      HudaHaptics.selection(context);
    } else if (after == items.length) {
      // The day is complete.
      HudaHaptics.medium(context);
      _showCard();
    } else {
      HudaHaptics.light(context);
    }
    _cubit.toggleItemCompletion(item.id, done);
  }

  /// The day completes where the star can be seen: on phones the last
  /// item is often far below the card, so the card scrolls back in view
  /// (only when it's away).
  void _showCard() {
    final card = _cardKey.currentContext;
    if (card == null) return;
    final tokens = context.tokens;
    Scrollable.ensureVisible(
      card,
      duration: tokens.motion.of(context, tokens.motion.long),
      curve: tokens.motion.emphasized,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
  }

  void _remove(ChecklistItem item) {
    final l10n = AppLocalizations.of(context)!;
    HudaHaptics.light(context);
    const window = Duration(seconds: 5);
    setState(() {
      _pending[item.id] = Timer(window, () => _commit(item.id));
    });
    showHudaToast(
      context,
      message: l10n.checklistRemoved(item.title),
      actionLabel: l10n.undo,
      duration: window,
      onAction: () {
        _pending.remove(item.id)?.cancel();
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _commit(String id) async {
    if (!_pending.containsKey(id)) return;
    await _cubit.removeCustomItem(id);
    if (mounted) setState(() => _pending.remove(id));
  }

  Future<void> _add() async {
    final item = await showChecklistAddSheet(context);
    if (item == null || !mounted) return;
    HudaHaptics.light(context);
    await _cubit.addCustomItem(
      title: item.title,
      type: item.type,
      frequency: item.frequency,
    );
  }

  void _step(int days) {
    if (_cubit.state is! ChecklistLoaded) return;
    setState(() => _forward = days > 0);
    days > 0 ? _cubit.navigateToNextDay() : _cubit.navigateToPreviousDay();
  }

  void _today() {
    final state = _cubit.state;
    if (state is ChecklistLoaded) {
      setState(() => _forward = state.currentDate.isBefore(DateTime.now()));
    }
    _cubit.navigateToToday();
  }

  void _retry() {
    setState(() => _retrying = true);
    _cubit.loadChecklist();
  }

  /// A swipe on the items changes the day, in reading direction.
  void _swiped(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 300) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final towardStart = rtl ? velocity < 0 : velocity > 0;
    _step(towardStart ? -1 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<ChecklistCubit>().state;
    final loaded = state is ChecklistLoaded ? state : null;
    final today = loaded != null && checklistIsToday(loaded.currentDate);
    final tokens = context.tokens;

    // One slot: New item on today, Back to today on any other day.
    final actions = [
      AnimatedSwitcher(
        duration: tokens.motion.of(context, tokens.motion.short),
        child: loaded != null && !today
            ? IconButton(
                key: const ValueKey('checklist-today'),
                tooltip: l10n.backToToday,
                onPressed: _today,
                icon: const Icon(Icons.today_rounded),
              )
            : IconButton(
                key: const ValueKey('checklist-add'),
                tooltip: l10n.checklistNewItem,
                onPressed: today ? _add : null,
                icon: const Icon(Icons.add_rounded),
              ),
      ),
    ];

    final width = MediaQuery.sizeOf(context).width;
    // Short windows (phone and Duo closed landscape) put the day beside
    // the items from 600, so the items are in view without scrolling.
    final short = MediaQuery.sizeOf(context).height < 480;
    final twoPaneMin = short ? 600.0 : 840.0;
    final fold = FoldInfo.of(context);
    final wide = AdaptivePanes.showsTwoPanes(
      width,
      fold,
      twoPaneMinWidth: twoPaneMin,
    );

    // Very wide windows without a fold keep the panes together in the
    // middle instead of spreading them to the window's edges.
    Widget panes({required Widget primary, required Widget secondary}) {
      final split = AdaptivePanes(
        primary: primary,
        secondary: secondary,
        twoPaneMinWidth: twoPaneMin,
      );
      if (width <= 1440 || fold.posture != FoldPosture.none) return split;
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: split,
        ),
      );
    }

    final rtl = Directionality.of(context) == TextDirection.rtl;

    Widget frame(Widget child) => BlocListener<ChecklistCubit, ChecklistState>(
      listener: (context, state) {
        if (state is! ChecklistError && _retrying) {
          setState(() => _retrying = false);
        }
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              _step(rtl ? 1 : -1),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _step(rtl ? -1 : 1),
        },
        child: Focus(autofocus: true, child: HudaRevealScope(child: child)),
      ),
    );

    final loading = state is ChecklistLoading || state is ChecklistInitial;
    if ((loaded != null || loading) &&
        !wide &&
        TabletopSplit.applies(context)) {
      return frame(
        TabletopSplit(
          top: HudaScaffold(
            title: l10n.islamicChecklistTitle,
            actions: actions,
            body: _pane(
              (context) => loaded == null
                  ? const ChecklistSkeleton(rows: false)
                  : _overview(loaded),
            ),
          ),
          bottom: Scaffold(
            backgroundColor: Colors.transparent,
            body: _pane(
              (context) => loaded == null
                  ? const ChecklistSkeleton(card: false)
                  : _items(context, loaded, revealFrom: 2),
              swipe: true,
            ),
          ),
        ),
      );
    }

    return frame(
      HudaScaffold(
        title: l10n.islamicChecklistTitle,
        actions: actions,
        body: HudaStateSwitcher(
          stateKey: state.runtimeType,
          child: switch (state) {
            ChecklistLoaded() when _visible(state).isEmpty => _empty(state),
            ChecklistLoaded() when wide => panes(
              primary: _pane((context) => _overview(state, large: !short)),
              secondary: _pane(
                (context) => _items(context, state, revealFrom: 2),
                swipe: true,
                key: const PageStorageKey('checklist-items'),
              ),
            ),
            ChecklistLoaded() => _single(state),
            ChecklistError() => HudaErrorState(
              identity: checklistIdentity,
              message: l10n.checklistLoadError,
              onRetry: _retry,
              retrying: _retrying,
            ),
            _ when wide => panes(
              primary: _pane((context) => const ChecklistSkeleton(rows: false)),
              secondary: _pane(
                (context) => const ChecklistSkeleton(card: false),
              ),
            ),
            _ => _pane(
              (context) => const ReadableWidth(
                maxWidth: 720,
                child: ChecklistSkeleton(),
              ),
            ),
          },
        ),
      ),
    );
  }

  /// A scroll view built in its pane's own context, so its gutter and
  /// insets are the pane's.
  Widget _pane(WidgetBuilder content, {bool swipe = false, Key? key}) =>
      Builder(
        builder: (context) {
          final space = context.tokens.space;
          final gutter = space.gutter(MediaQuery.sizeOf(context).width);
          final scroll = SingleChildScrollView(
            key: key,
            padding: context.scrollPadding(
              EdgeInsets.fromLTRB(gutter, space.md, gutter, space.xxl),
            ),
            child: content(context),
          );
          // The state switcher passes loose constraints; a scroll view would
          // shrink-wrap its width and leave the column off-center.
          final full = SizedBox(width: double.infinity, child: scroll);
          return swipe
              ? GestureDetector(onHorizontalDragEnd: _swiped, child: full)
              : full;
        },
      );

  /// Phones and portrait tablets: the day, then its items.
  Widget _single(ChecklistLoaded state) => _pane(
    (context) => ReadableWidth(
      maxWidth: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _overview(state),
          SizedBox(height: context.tokens.space.xl),
          _items(context, state, revealFrom: 2),
        ],
      ),
    ),
    swipe: true,
  );

  /// The date row and the day card.
  Widget _overview(ChecklistLoaded state, {bool large = false}) {
    final items = _visible(state);
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HudaReveal(
            child: ChecklistDateRow(
              date: state.currentDate,
              onPrevious: () => _step(-1),
              onNext: () => _step(1),
            ),
          ),
          SizedBox(height: context.tokens.space.md),
          if (items.isNotEmpty)
            HudaReveal(
              key: _cardKey,
              index: 1,
              child: _daySwitch(
                state.currentDate,
                ChecklistDayCard(
                  date: state.currentDate,
                  done: _done(state, items),
                  total: items.length,
                  streak: state.streakCount,
                  large: large,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _items(
    BuildContext context,
    ChecklistLoaded state, {
    required int revealFrom,
  }) {
    final items = _visible(state);
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: _daySwitch(
            state.currentDate,
            ChecklistGroups(
              items: items,
              completed: state.dailyChecklist.completedItems,
              editable: checklistIsToday(state.currentDate),
              columns: constraints.maxWidth >= 640 ? 2 : 1,
              revealFrom: revealFrom,
              onToggle: (item, done) => _toggle(state, item, done),
              onRemove: _remove,
            ),
          ),
        ),
      ),
    );
  }

  /// A day with nothing to do: the date row to move on, then the state.
  Widget _empty(ChecklistLoaded state) => Builder(
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      final space = context.tokens.space;
      final gutter = space.gutter(MediaQuery.sizeOf(context).width);
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, space.md, gutter, 0),
            child: ReadableWidth(
              maxWidth: 720,
              child: ChecklistDateRow(
                date: state.currentDate,
                onPrevious: () => _step(-1),
                onNext: () => _step(1),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: _swiped,
              child: HudaEmptyState(
                identity: checklistIdentity,
                title: l10n.noTasksForDay,
                message: l10n.checklistEmptyMessage,
              ),
            ),
          ),
        ],
      );
    },
  );

  /// A new day slides in from the side it comes from (mirrored in RTL);
  /// the old one fades.
  Widget _daySwitch(DateTime date, Widget child) {
    final key = ValueKey('${date.year}-${date.month}-${date.day}');
    return Builder(
      builder: (context) {
        final tokens = context.tokens;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final from = (_forward ? 1 : -1) * (rtl ? -1 : 1) * 0.06;
        return AnimatedSwitcher(
          duration: tokens.motion.of(context, tokens.motion.medium),
          switchInCurve: tokens.motion.emphasized,
          switchOutCurve: Curves.easeOut,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          transitionBuilder: (child, animation) {
            final fade = FadeTransition(opacity: animation, child: child);
            if (child.key != key) return fade;
            return SlideTransition(
              position: Tween(
                begin: Offset(from, 0),
                end: Offset.zero,
              ).animate(animation),
              child: fade,
            );
          },
          child: KeyedSubtree(key: key, child: child),
        );
      },
    );
  }
}
