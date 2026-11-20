import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/athkar_details/athkar_details_cubit.dart';
import 'package:huda/data/models/athkar_detail_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/athkar/athkar_identity.dart';
import 'package:huda/presentation/widgets/athkar/athkar_tabletop.dart';
import 'package:huda/presentation/widgets/athkar%20details/athkar_audio_player.dart';
import 'package:huda/presentation/widgets/athkar%20details/athkar_chapter_header.dart';
import 'package:huda/presentation/widgets/athkar%20details/athkar_dhikr_card.dart';
import 'package:huda/presentation/widgets/athkar%20details/athkar_dhikr_columns.dart';
import 'package:huda/presentation/widgets/athkar%20details/athkar_share_handler.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';

class AthkarDetails extends StatefulWidget {
  const AthkarDetails({
    super.key,
    required this.athkarId,
    required this.title,
    required this.titleEn,
  });

  final String athkarId;

  final String title;

  final String titleEn;

  @visibleForTesting
  static AthkarDetailsCubit Function() createCubit = AthkarDetailsCubit.new;

  static Widget page({
    required String athkarId,
    required String title,
    required String titleEn,
  }) => BlocProvider<AthkarDetailsCubit>(
    create: (_) => createCubit(),
    child: AthkarDetails(athkarId: athkarId, title: title, titleEn: titleEn),
  );

  @override
  State<AthkarDetails> createState() => _AthkarDetailsState();
}

class _AthkarDetailsState extends State<AthkarDetails> {
  List<int>? _remaining;
  List<int>? _totals;

  final Set<int> _folded = {};
  final List<GlobalKey> _cardKeys = [];
  final _readerScroll = ScrollController();
  final _completionKey = GlobalKey();

  final _bottomHalf = GlobalKey();
  late final AthkarAudio _audio;

  bool _retrying = false;
  AthkarDetailsState? _failure;

  @override
  void initState() {
    super.initState();
    context.read<AthkarDetailsCubit>().loadAthkarDetail(widget.athkarId);
    _audio = AthkarAudio(
      audioAt: (index) {
        final details = _details;
        return details == null || index >= details.length
            ? null
            : details[index].audio;
      },
      onError: () {
        if (!mounted) return;
        showHudaToast(
          _toastContext,
          message: AppLocalizations.of(context)!.athkarAudioError,
          kind: HudaToastKind.failed,
        );
      },
    )..addListener(_onAudio);
  }

  @override
  void dispose() {
    _audio
      ..removeListener(_onAudio)
      ..dispose();
    _readerScroll.dispose();
    super.dispose();
  }

  void _onAudio() {
    if (mounted) setState(() {});
  }

  List<AthkarDetailModel>? get _details {
    final state = context.read<AthkarDetailsCubit>().state;
    return state is AthkarDetailsLoaded ? state.athkarCategory.details : null;
  }

  void _prepare(List<AthkarDetailModel> details) {
    if (_remaining != null) return;
    _totals = [for (final d in details) math.max(1, d.repeat ?? 1)];
    _remaining = List.of(_totals!);
    _cardKeys
      ..clear()
      ..addAll([for (final _ in details) GlobalKey()]);
  }

  void _count(int index) {
    final remaining = _remaining!;
    if (remaining[index] <= 0) return;
    setState(() => remaining[index]--);
    if (remaining[index] == 0) {
      HudaHaptics.medium(context);
      const motion = HudaMotion();
      final wait = motion.of(context, const Duration(milliseconds: 450));
      Timer(wait, () {
        if (!mounted || _remaining![index] != 0) return;
        setState(() => _folded.add(index));
        final next = _nextAfter(index);
        Timer(const HudaMotion().of(context, const HudaMotion().long), () {
          if (!mounted) return;
          if (next == null) {
            if (_remaining!.every((r) => r <= 0)) {
              _reveal(_completionKey, atEnd: true);
            }
          } else {
            _bringNext(_cardKeys[next]);
          }
        });
      });
    } else {
      HudaHaptics.selection(context);
    }
  }

  void _reset(int index) {
    final before = _remaining![index];
    final wasFolded = _folded.contains(index);
    setState(() {
      _remaining![index] = _totals![index];
      _folded.remove(index);
    });
    HudaHaptics.light(context);
    final l10n = AppLocalizations.of(context)!;
    showHudaToast(
      _toastContext,
      message: l10n.athkarCountReset,
      actionLabel: l10n.undo,
      onAction: () {
        if (!mounted) return;
        setState(() {
          _remaining![index] = before;
          if (wasFolded) _folded.add(index);
        });
      },
    );
  }

  void _startAgain() {
    setState(() {
      _remaining = List.of(_totals!);
      _folded.clear();
    });
    HudaHaptics.light(context);
    if (_readerScroll.hasClients) {
      const motion = HudaMotion();
      final duration = motion.of(context, motion.long);
      if (duration == Duration.zero) {
        _readerScroll.jumpTo(0);
      } else {
        _readerScroll.animateTo(
          0,
          duration: duration,
          curve: motion.emphasized,
        );
      }
    }
  }

  int? _nextAfter(int index) {
    final remaining = _remaining!;
    for (var i = index + 1; i < remaining.length; i++) {
      if (remaining[i] > 0) return i;
    }
    return null;
  }

  void _bringNext(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = key.currentContext;
      final scrollable = target == null ? null : Scrollable.maybeOf(target);
      if (target == null || scrollable == null || !mounted) return;
      final card = target.findRenderObject() as RenderBox?;
      final view = scrollable.context.findRenderObject() as RenderBox?;
      if (card == null || view == null) return;
      final top = card.localToGlobal(Offset.zero, ancestor: view).dy;
      final height = view.size.height;
      if (top >= 0 && top <= height * 0.4) return;
      const motion = HudaMotion();
      Scrollable.ensureVisible(
        target,
        alignment: 0.1,
        duration: motion.of(context, motion.long),
        curve: motion.emphasized,
      );
    });
  }

  BuildContext get _toastContext => _bottomHalf.currentContext ?? context;

  void _reveal(GlobalKey key, {bool atEnd = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = key.currentContext;
      if (target == null || !mounted) return;
      const motion = HudaMotion();
      Scrollable.ensureVisible(
        target,
        alignment: atEnd ? 1 : 0.05,
        alignmentPolicy: atEnd
            ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
            : ScrollPositionAlignmentPolicy.explicit,
        duration: motion.of(context, motion.long),
        curve: motion.emphasized,
      );
    });
  }

  void _retry() {
    setState(() => _retrying = true);
    context.read<AthkarDetailsCubit>().loadAthkarDetail(widget.athkarId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<AthkarDetailsCubit>().state;
    if (AthkarTabletop.applies(context) &&
        (state is AthkarDetailsLoaded || state is AthkarDetailsLoading)) {
      final details = state is AthkarDetailsLoaded
          ? state.athkarCategory.details
          : null;
      if (details != null) _prepare(details);
      return HudaRevealScope(
        child: AthkarTabletop(
          top: HudaScaffold(
            title: l10n.athkar,
            body: _panelPane(
              context,
              details == null
                  ? const AthkarChapterPanelSkeleton()
                  : _panel(details),
            ),
          ),
          bottom: ScaffoldMessenger(
            child: Scaffold(
              key: _bottomHalf,
              backgroundColor: Colors.transparent,
              body: details == null
                  ? _readerSkeleton(context)
                  : _reader(context, details, columns: 1, header: false),
            ),
          ),
        ),
      );
    }
    return HudaRevealScope(
      child: HudaScaffold(
        title: l10n.athkar,
        body: BlocConsumer<AthkarDetailsCubit, AthkarDetailsState>(
          listener: (context, state) {
            if (state is! AthkarDetailsLoading && _retrying) {
              setState(() => _retrying = false);
            }
          },
          builder: (context, state) {
            if (state is AthkarDetailsError || state is AthkarDetailsOffline) {
              _failure = state;
            }
            final failure = _failure;
            final shown =
                _retrying && state is AthkarDetailsLoading && failure != null
                ? failure
                : state;
            return HudaStateSwitcher(
              stateKey: shown.runtimeType,
              child: switch (shown) {
                AthkarDetailsLoaded(:final athkarCategory) => _loaded(
                  context,
                  athkarCategory.details,
                ),
                AthkarDetailsError() => HudaErrorState(
                  identity: athkarIdentity,
                  message: l10n.athkarLoadError,
                  onRetry: _retry,
                  retrying: _retrying,
                ),
                AthkarDetailsOffline() => HudaOfflineState(
                  onRetry: _retry,
                  retrying: _retrying,
                ),
                _ => _skeleton(context),
              },
            );
          },
        ),
      ),
    );
  }

  int _columns(BuildContext context, double width) {
    if (context.windowClass.isCompactHeight) return 1;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final room = width / scale;
    if (FoldInfo.of(context).splitsHorizontally && room >= 600) return 2;
    if (room >= 1400) return 3;
    if (room >= 840) return 2;
    return 1;
  }

  static const double _maxColumnsWidth = 1600;

  Widget _centered(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxColumnsWidth),
      child: child,
    ),
  );

  Widget _banner(Widget child) => LayoutBuilder(
    builder: (context, constraints) {
      final fold = FoldInfo.of(context);
      var cap = double.infinity;
      if (fold.isBook) {
        final window = MediaQuery.sizeOf(context).width;
        final left = (window - constraints.maxWidth) / 2;
        final leading = Directionality.of(context) == TextDirection.rtl
            ? left + constraints.maxWidth - fold.end
            : fold.start - left;
        cap = math.min(cap, leading - context.tokens.space.md / 2);
      }
      return Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: math.max(240.0, cap)),
          child: child,
        ),
      );
    },
  );

  Widget _skeleton(BuildContext context) {
    final space = context.tokens.space;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columns(context, constraints.maxWidth);
        final gutter = space.gutter(constraints.maxWidth);
        return ListView(
          padding: context.scrollPadding(
            EdgeInsets.fromLTRB(gutter, space.md, gutter, space.xxl),
          ),
          children: [
            if (columns == 1)
              const ReadableWidth(child: AthkarChapterSkeleton())
            else
              _centered(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _banner(const AthkarChapterPanelSkeleton(horizontal: true)),
                    SizedBox(height: space.xl),
                    AthkarDhikrColumns(
                      columns: columns,
                      spacing: space.md,
                      children: [
                        for (var i = 0; i < columns * 3; i++)
                          const AthkarDhikrCardSkeleton(),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _readerSkeleton(BuildContext context) {
    final space = context.tokens.space;
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = space.gutter(constraints.maxWidth);
        return ListView(
          padding: context.scrollPadding(
            EdgeInsets.fromLTRB(gutter, space.md, gutter, space.xxl),
          ),
          children: const [
            ReadableWidth(child: AthkarChapterSkeleton(header: false)),
          ],
        );
      },
    );
  }

  AthkarChapterPanel _panel(
    List<AthkarDetailModel> details, {
    bool horizontal = false,
  }) => AthkarChapterPanel(
    title: widget.title,
    titleEn: widget.titleEn,
    done: _remaining!.where((r) => r <= 0).length,
    total: details.length,
    horizontal: horizontal,
  );

  Widget _header(List<AthkarDetailModel> details) => AthkarChapterHeader(
    title: widget.title,
    titleEn: widget.titleEn,
    compact: context.windowClass.isCompactHeight,
    done: _remaining!.where((r) => r <= 0).length,
    total: details.length,
  );

  Widget _loaded(BuildContext context, List<AthkarDetailModel> details) {
    _prepare(details);
    return LayoutBuilder(
      builder: (context, constraints) => _reader(
        context,
        details,
        columns: _columns(context, constraints.maxWidth),
        header: true,
      ),
    );
  }

  Widget _panelPane(BuildContext context, Widget panel) {
    final space = context.tokens.space;
    return ListView(
      key: const PageStorageKey('athkar-panel'),
      padding: context.scrollPadding(
        EdgeInsets.fromLTRB(space.lg, space.lg, space.lg, space.xxl),
      ),
      children: [HudaReveal(child: panel)],
    );
  }

  Widget _reader(
    BuildContext context,
    List<AthkarDetailModel> details, {
    required int columns,
    required bool header,
  }) {
    final space = context.tokens.space;
    final remaining = _remaining!;
    final allDone = remaining.every((r) => r <= 0);
    final arabicUi = Localizations.localeOf(context).languageCode == 'ar';
    final cards = [
      for (var i = 0; i < details.length; i++)
        HudaReveal(
          index: i + 1,
          child: KeyedSubtree(
            key: _cardKeys[i],
            child: AthkarDhikrCard(
              dhikr: details[i],
              remaining: remaining[i],
              total: _totals![i],
              folded: _folded.contains(i),
              showTranslation: !arabicUi,
              audio: AthkarCardAudio(
                current: _audio.playingIndex == i,
                playing: _audio.isPlaying,
                position: _audio.position,
                duration: _audio.duration,
              ),
              onCount: () => _count(i),
              onUnfold: () => setState(() => _folded.remove(i)),
              onReset: () => _reset(i),
              onShare: () => shareAthkar(
                this.context,
                dhikr: details[i],
                index: i,
                title: widget.title,
                titleEn: widget.titleEn,
              ),
              onPlay: (details[i].audio ?? '').isEmpty
                  ? null
                  : () => _audio.play(i),
              onSeek: _audio.seek,
            ),
          ),
        ),
    ];
    final completion = HudaStateSwitcher(
      stateKey: allDone,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: double.infinity,
        child: allDone
            ? Padding(
                padding: EdgeInsets.only(top: space.xl),
                child: AthkarCompletion(
                  key: _completionKey,
                  onStartAgain: _startAgain,
                ),
              )
            : null,
      ),
    );
    final Widget content;
    if (columns == 1) {
      content = ReadableWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header) ...[
              HudaReveal(child: _header(details)),
              SizedBox(height: space.xl),
            ],
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) SizedBox(height: space.md),
              cards[i],
            ],
            completion,
          ],
        ),
      );
    } else {
      content = _centered(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _banner(HudaReveal(child: _panel(details, horizontal: true))),
            SizedBox(height: space.xl),
            AthkarDhikrColumns(
              columns: columns,
              spacing: space.md,
              children: cards,
            ),
            ReadableWidth(child: completion),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = space.gutter(constraints.maxWidth);
        return SingleChildScrollView(
          key: const PageStorageKey('athkar-reader'),
          controller: _readerScroll,
          padding: context.scrollPadding(
            EdgeInsets.fromLTRB(gutter, space.md, gutter, space.xxl),
          ),
          child: content,
        );
      },
    );
  }
}
