import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/zakat_calculator/zakat_calculator_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/zakat_calculator/zakat_identity.dart';
import 'package:huda/presentation/widgets/zakat_calculator/zakat_ledger.dart';
import 'package:huda/presentation/widgets/zakat_calculator/zakat_parts.dart';
import 'package:huda/presentation/widgets/zakat_calculator/zakat_result.dart';

/// The zakat calculator: one ledger to fill in and the mizan that weighs it
/// against the nisab, live. Phones show the result card above the ledger
/// (and a result strip at the bottom once it's scrolled away); from 840
/// wide and on folds the ledger and the result sit side by side; tabletop
/// puts the result above the band and the ledger below it.
class ZakatCalculator extends StatefulWidget {
  const ZakatCalculator({super.key});

  @override
  State<ZakatCalculator> createState() => _ZakatCalculatorState();
}

class _ZakatCalculatorState extends State<ZakatCalculator> {
  final _fields = ZakatFields();
  final _scroll = ScrollController();
  final _resultKey = GlobalKey(debugLabel: 'zakat-result');
  final _summaryKey = GlobalKey(debugLabel: 'zakat-summary');
  bool _strip = false;
  bool? _wasDue;
  NisabType? _wasBasis;

  /// Set by Clear and Undo, which have their own haptic: the crossing
  /// they cause stays quiet (one haptic per action).
  bool _quietCross = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateStrip);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _fields.dispose();
    super.dispose();
  }

  /// The strip shows while the result card is above the screen and the
  /// ledger's own summary at the end isn't on it yet.
  void _updateStrip() {
    if (!_scroll.hasClients) return;
    final view = context.findRenderObject() as RenderBox?;
    final card = _resultKey.currentContext?.findRenderObject() as RenderBox?;
    final summary =
        _summaryKey.currentContext?.findRenderObject() as RenderBox?;
    if (view == null || card == null || !card.attached) return;
    final top = view.localToGlobal(Offset.zero).dy;
    final cardBottom = card.localToGlobal(Offset(0, card.size.height)).dy;
    final bottom = top + view.size.height;
    final summaryTop = summary != null && summary.attached
        ? summary.localToGlobal(Offset.zero).dy
        : double.infinity;
    final show = cardBottom < top + 48 && summaryTop > bottom - 96;
    if (show != _strip) setState(() => _strip = show);
  }

  void _showResult() {
    _scroll.animateTo(
      0,
      duration: context.tokens.motion.of(context, context.tokens.motion.long),
      curve: context.tokens.motion.emphasized,
    );
  }

  void _clear(ZakatCalculatorLoaded state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ZakatCalculatorCubit>();
    final saved = Map.of(state.calculation.assets);
    _fields.clearAmounts();
    _quietCross = true;
    cubit.resetCalculation();
    HudaHaptics.light(context);
    showHudaToast(
      context,
      message: l10n.zakatAmountsCleared,
      actionLabel: l10n.undo,
      onAction: () {
        _quietCross = true;
        // The listener clears the flag when the restored state arrives.
        saved.forEach(cubit.updateAssetValue);
        final restored = cubit.state;
        if (restored is ZakatCalculatorLoaded) _fields.fill(restored);
      },
    );
  }

  void _retryPrices() => context.read<ZakatCalculatorCubit>().retryPrices();

  /// Retrying starts the calculation again from empty amounts.
  void _retry() {
    _fields.clearAmounts();
    context.read<ZakatCalculatorCubit>().resetCalculation();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<ZakatCalculatorCubit>().state;
    final loaded = state is ZakatCalculatorLoaded ? state : null;
    if (loaded != null) _fields.fill(loaded);

    final actions = [
      // Disabled (never missing) while loading or with nothing to clear.
      IconButton(
        tooltip: l10n.zakatClearAmounts,
        onPressed: loaded != null && zakatHasAmounts(loaded.calculation)
            ? () => _clear(loaded)
            : null,
        icon: const Icon(Icons.restart_alt_rounded),
      ),
      IconButton(
        tooltip: l10n.aboutZakat,
        onPressed: () => showZakatAbout(context),
        icon: const Icon(Icons.info_outline_rounded),
      ),
    ];

    final width = MediaQuery.sizeOf(context).width;
    final wide = AdaptivePanes.showsTwoPanes(width, FoldInfo.of(context));

    // Something clicks into place: the balance tips across the nisab.
    Widget listen(Widget child) =>
        BlocListener<ZakatCalculatorCubit, ZakatCalculatorState>(
          listener: (context, state) {
            if (state is! ZakatCalculatorLoaded) return;
            final due = state.calculation.isZakatDue;
            // A basis switch has its segment's tick already.
            final quiet = _quietCross || _wasBasis != state.nisabType;
            if (_wasDue != null && _wasDue != due && !quiet) {
              HudaHaptics.selection(context);
            }
            _wasDue = due;
            _wasBasis = state.nisabType;
            _quietCross = false;
          },
          child: HudaRevealScope(child: child),
        );

    final loading =
        state is ZakatCalculatorLoading || state is ZakatCalculatorInitial;
    if ((loaded != null || loading) &&
        !wide &&
        TabletopSplit.applies(context)) {
      // Loading splits at the band like the content it stands for.
      return listen(
        TabletopSplit(
          top: HudaScaffold(
            title: l10n.zakatCalculator,
            actions: actions,
            body: loaded == null
                ? _pane(
                    (context) =>
                        const ZakatSkeleton(ledger: false, totals: false),
                  )
                : _resultPane(loaded, totals: false),
          ),
          // The totals go under the ledger, so the top half is the card.
          bottom: Scaffold(
            backgroundColor: Colors.transparent,
            body: loaded == null
                ? _pane((context) => const ZakatSkeleton(result: false))
                : _ledgerPane(loaded, revealFrom: 1, totals: true),
          ),
        ),
      );
    }

    return listen(
      HudaScaffold(
        title: l10n.zakatCalculator,
        actions: actions,
        body: HudaStateSwitcher(
          stateKey: state.runtimeType,
          child: switch (state) {
            ZakatCalculatorLoaded() when wide => AdaptivePanes(
              primary: _ledgerPane(state, revealFrom: 0),
              secondary: _resultPane(state),
              // The ledger leads and takes the larger share; the result
              // sits beside it like a receipt.
              primaryFraction: 0.56,
              minPrimaryWidth: 420,
              maxPrimaryWidth: 720,
            ),
            ZakatCalculatorLoaded() => _single(context, state),
            ZakatCalculatorError() => HudaErrorState(
              identity: zakatIdentity,
              message: l10n.zakatCalcError,
              onRetry: _retry,
            ),
            // Loading takes the shape of the layout that's coming.
            _ when wide => AdaptivePanes(
              primary: _pane((context) => const ZakatSkeleton(result: false)),
              secondary: _pane((context) => const ZakatSkeleton(ledger: false)),
              primaryFraction: 0.56,
              minPrimaryWidth: 420,
              maxPrimaryWidth: 720,
            ),
            _ => _scrollFrame(context, const ZakatSkeleton()),
          },
        ),
      ),
    );
  }

  /// A scrolling, readable column for the skeleton and the narrow layout.
  Widget _scrollFrame(BuildContext context, Widget child) {
    final space = context.tokens.space;
    final gutter = space.gutter(MediaQuery.sizeOf(context).width);
    return SingleChildScrollView(
      padding: context.scrollPadding(
        EdgeInsets.fromLTRB(gutter, space.md, gutter, space.xxl),
      ),
      child: ReadableWidth(maxWidth: 720, child: child),
    );
  }

  /// Phones and portrait tablets: the result card, the ledger, then the
  /// ledger's totals; a strip keeps the result in view in between.
  Widget _single(BuildContext context, ZakatCalculatorLoaded state) {
    final space = context.tokens.space;
    final short = MediaQuery.sizeOf(context).height < 480;
    final gutter = space.gutter(MediaQuery.sizeOf(context).width);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateStrip();
    });
    return Stack(
      children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (_) {
            _updateStrip();
            return false;
          },
          child: SingleChildScrollView(
            controller: _scroll,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: context.scrollPadding(
              EdgeInsets.fromLTRB(gutter, space.md, gutter, space.xxl),
            ),
            child: ReadableWidth(
              maxWidth: 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!short)
                    ZakatPriceBanner(state: state, onRetry: _retryPrices),
                  HudaReveal(
                    child: ZakatResultCard(key: _resultKey, state: state),
                  ),
                  // Short windows keep the amount due in view: the banner
                  // goes under the card.
                  if (short)
                    ZakatPriceBanner(
                      state: state,
                      onRetry: _retryPrices,
                      below: true,
                    ),
                  SizedBox(height: space.xl),
                  ZakatLedger(
                    state: state,
                    fields: _fields,
                    overlayContext: this.context,
                    revealFrom: 1,
                  ),
                  SizedBox(height: space.xl),
                  KeyedSubtree(
                    key: _summaryKey,
                    child: ZakatLedgerCard(state: state),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ZakatResultStrip(
            state: state,
            visible: _strip,
            onTap: _showResult,
          ),
        ),
      ],
    );
  }

  /// A pane's scroll view, built in the pane's own context, so its
  /// gutter and insets are the pane's (each pane of [AdaptivePanes] sees
  /// only its own size and edges).
  Widget _pane(WidgetBuilder content, {Key? key}) => Builder(
    builder: (context) {
      final space = context.tokens.space;
      final gutter = space.gutter(MediaQuery.sizeOf(context).width);
      return SingleChildScrollView(
        key: key,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: context.scrollPadding(
          EdgeInsets.fromLTRB(gutter, space.md, gutter, space.xxl),
        ),
        child: content(context),
      );
    },
  );

  Widget _ledgerPane(
    ZakatCalculatorLoaded state, {
    required int revealFrom,
    bool totals = false,
  }) => _pane(
    key: const PageStorageKey('zakat-ledger'),
    (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ZakatLedger(
          state: state,
          fields: _fields,
          overlayContext: this.context,
          revealFrom: revealFrom,
        ),
        if (totals) ...[
          SizedBox(height: context.tokens.space.xl),
          ZakatLedgerCard(state: state),
        ],
      ],
    ),
  );

  /// The result beside (or above) the ledger: the card and the ledger's
  /// totals, side by side where the pane is wide.
  Widget _resultPane(
    ZakatCalculatorLoaded state, {
    bool totals = true,
  }) => _pane(
    key: const PageStorageKey('zakat-result'),
    (context) => LayoutBuilder(
      builder: (context, constraints) {
        final space = context.tokens.space;
        final short = MediaQuery.sizeOf(context).height < 480;
        final card = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!short) ZakatPriceBanner(state: state, onRetry: _retryPrices),
            HudaReveal(child: ZakatResultCard(state: state)),
            // Short panes keep the amount due in view.
            if (short)
              ZakatPriceBanner(
                state: state,
                onRetry: _retryPrices,
                below: true,
              ),
          ],
        );
        // Tabletop's top half: the card centered in it, the thing to
        // look at above the band.
        if (!totals) {
          final insets = context.scrollPadding(
            EdgeInsets.only(top: space.md, bottom: space.xxl),
          );
          final room = MediaQuery.sizeOf(context).height - insets.vertical;
          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: room),
            child: Center(child: card),
          );
        }
        final ledger = HudaReveal(
          index: 1,
          child: ZakatLedgerCard(state: state),
        );
        final scale = MediaQuery.textScalerOf(context).scale(1);
        if (constraints.maxWidth >= 640 * scale.clamp(1.0, 1.4)) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: card),
                  SizedBox(width: space.xl),
                  Expanded(flex: 2, child: ledger),
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            card,
            SizedBox(height: space.xl),
            ledger,
          ],
        );
      },
    ),
  );
}
