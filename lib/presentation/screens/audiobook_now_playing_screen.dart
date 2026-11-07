import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/tabletop_split.dart';
import 'package:huda/core/theme/huda_theme_scope.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_state.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/audio/audiobook_bar.dart';
import 'package:huda/presentation/widgets/audio/audiobook_player_parts.dart';
import 'package:huda/presentation/widgets/audio/audiobook_swatch.dart';
import 'package:huda/presentation/widgets/audio/audiobooks_identity.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';

/// The player, a night focus screen: the recording's swatch whose plait is
/// the book (an eye per chapter, the heard ones filled, the current one
/// filling), the chapter, the seek slider, the transport, speed and the
/// sleep timer, then the chapters. Chapters beside the player from 840
/// wide and on open folds (split at a vertical fold); swatch beside the
/// controls on short windows; swatch above a tabletop fold. See
/// `design/features/audiobooks/brief.md`.
class AudiobookNowPlayingScreen extends StatefulWidget {
  const AudiobookNowPlayingScreen({super.key});

  @override
  State<AudiobookNowPlayingScreen> createState() =>
      _AudiobookNowPlayingScreenState();
}

class _AudiobookNowPlayingScreenState extends State<AudiobookNowPlayingScreen> {
  bool _closing = false;

  void _close() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HudaNight(
      child: BlocConsumer<AudiobookPlayerCubit, AudiobookPlayerState>(
        listener: (context, state) {
          // Stopped from elsewhere (the notification, another audio).
          if (state is AudiobookPlayerInitial) _close();
        },
        builder: (context, state) {
          final playing = state is AudiobookPlayerPlaying ? state : null;
          return HudaImmersiveScaffold(
            leading: IconButton(
              tooltip: l10n.quranAudioHidePlayer,
              onPressed: _close,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
            actions: [
              if (playing != null)
                IconButton(
                  tooltip: l10n.stop,
                  onPressed: () {
                    stopAudiobook(context);
                    _close();
                  },
                  icon: const Icon(Icons.stop_rounded),
                ),
            ],
            body: HudaStateSwitcher(
              stateKey: switch (state) {
                AudiobookPlayerPlaying() => 'playing',
                AudiobookPlayerError() => 'error',
                _ => 'loading',
              },
              child: switch (state) {
                AudiobookPlayerPlaying() => StreamBuilder<int?>(
                  stream: state.audioPlayer.currentIndexStream,
                  builder: (context, snap) => _PlayerBody(
                    state: state,
                    index: snap.data ?? state.audioPlayer.currentIndex ?? 0,
                  ),
                ),
                AudiobookPlayerError() => Padding(
                  // The state view scrolls and keeps off folds itself.
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top + kToolbarHeight,
                  ),
                  child: HudaStateView(
                    identity: audiobooksIdentity,
                    mark: HudaStateMark.alert,
                    title: l10n.somethingWentWrong,
                    message: l10n.audiobooksStartFailed,
                    actions: [
                      FilledButton.icon(
                        onPressed: _close,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        label: Text(l10n.back),
                      ),
                    ],
                  ),
                ),
                AudiobookPlayerLoading(:final audiobookId) => _Preparing(
                  seed: audiobookId,
                ),
                _ => const _Centered(child: HudaLampSpinner(size: 32)),
              },
            ),
          );
        },
      ),
    );
  }
}

/// The recording being prepared: its swatch, dimmed, over the lamp and
/// "Preparing…".
class _Preparing extends StatelessWidget {
  const _Preparing({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    return _Centered(
      child: Semantics(
        liveRegion: true,
        label: l10n.quranAudioPreparing,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Opacity(opacity: 0.5, child: AudiobookSwatch(seed: seed)),
            ),
            SizedBox(height: space.xl),
            const HudaLampSpinner(size: 28),
            SizedBox(height: space.sm),
            Text(
              l10n.quranAudioPreparing,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.onChromeMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clear of the bar and the insets, centered, scrolling when it must.
class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final space = context.tokens.space;
    final sideChrome = HudaChromeFrame.hasSideChrome(context);
    return _Scrolling(
      padding: EdgeInsets.fromLTRB(
        media.padding.left + space.lg,
        media.padding.top + (sideChrome ? space.md : kToolbarHeight),
        media.padding.right + space.lg,
        media.padding.bottom + space.lg,
      ),
      child: child,
    );
  }
}

class _PlayerBody extends StatelessWidget {
  const _PlayerBody({required this.state, required this.index});

  final AudiobookPlayerPlaying state;
  final int index;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final space = context.tokens.space;
    final cubit = context.read<AudiobookPlayerCubit>();
    final player = state.audioPlayer;
    final sideChrome = HudaChromeFrame.hasSideChrome(context);
    final top = media.padding.top + (sideChrome ? space.md : kToolbarHeight);
    final size = media.size;

    // The swatch keeps to about a third of the height, so the controls
    // and the speed and sleep pills fit below it without scrolling.
    final room = size.height - top - media.padding.bottom;
    final byHeight = room * 0.34 * AudiobookSwatch.aspect;
    Widget art({double maxWidth = 320, bool capped = true}) =>
        AudiobookPlayerArt(
          state: state,
          index: index,
          maxWidth: capped
              ? maxWidth.clamp(140.0, byHeight.clamp(140.0, 480.0))
              : maxWidth,
        );
    final shortWindow = size.height < 560;
    final titles = AudiobookPlayerTitles(
      state: state,
      index: index,
      compact: shortWindow,
    );
    final controls = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AudiobookSeek(player: player, onSeek: cubit.seek),
        SizedBox(height: space.sm),
        AudiobookTransport(player: player, cubit: cubit),
        SizedBox(height: space.lg),
        AudiobookPlayerOptions(
          player: player,
          cubit: cubit,
          sheetContext: context,
        ),
      ],
    );
    Widget chapters({Key? currentKey}) => AudiobookPlayerChapters(
      state: state,
      index: index,
      cubit: cubit,
      currentKey: currentKey,
    );

    if (TabletopSplit.applies(context)) {
      // What to look at above the fold, the controls and chapters below.
      return TabletopSplit(
        top: Builder(
          builder: (context) {
            final m = MediaQuery.of(context);
            return _Scrolling(
              padding: EdgeInsets.fromLTRB(
                m.padding.left + space.lg,
                top,
                m.padding.right + space.lg,
                space.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: art(maxWidth: 260)),
                  SizedBox(width: space.xl),
                  Flexible(child: titles),
                ],
              ),
            );
          },
        ),
        bottom: Builder(
          builder: (context) {
            final m = MediaQuery.of(context);
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                m.padding.left + space.lg,
                space.md,
                m.padding.right + space.lg,
                m.padding.bottom + space.lg,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    children: [
                      controls,
                      SizedBox(height: space.xl),
                      chapters(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    final twoPanes = AdaptivePanes.showsTwoPanes(
      size.width,
      FoldInfo.of(context),
    );
    final short = size.height < 480;
    if (twoPanes && !short) {
      return AdaptivePanes(
        primaryFraction: 0.5,
        minPrimaryWidth: 400,
        maxPrimaryWidth: 640,
        primary: Builder(
          builder: (context) {
            final m = MediaQuery.of(context);
            return _Scrolling(
              padding: EdgeInsets.fromLTRB(
                m.padding.left + space.xl,
                top,
                m.padding.right + space.xl,
                m.padding.bottom + space.lg,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    art(maxWidth: 360),
                    SizedBox(height: space.xl),
                    titles,
                    SizedBox(height: space.xl),
                    controls,
                  ],
                ),
              ),
            );
          },
        ),
        secondary: _ChaptersPane(
          index: index,
          top: top,
          builder: (key) => chapters(currentKey: key),
        ),
      );
    }

    if (size.width >= 600 && size.width > size.height * 1.2) {
      // Short and wide: the swatch on the leading side, sized to the
      // height; everything else scrolls beside it.
      final artWidth =
          ((size.height - top - media.padding.bottom) *
                  AudiobookSwatch.aspect *
                  0.8)
              .clamp(160.0, 320.0);
      return Padding(
        padding: EdgeInsets.only(
          left: media.padding.left + space.lg,
          right: media.padding.right + space.lg,
        ),
        child: Row(
          children: [
            SizedBox(
              width: artWidth,
              child: _Scrolling(
                padding: EdgeInsets.only(
                  top: top,
                  bottom: media.padding.bottom + space.lg,
                ),
                child: art(maxWidth: artWidth, capped: false),
              ),
            ),
            SizedBox(width: space.xl),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: top,
                  bottom: media.padding.bottom + space.lg,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      children: [
                        titles,
                        SizedBox(height: space.md),
                        controls,
                        SizedBox(height: space.xl),
                        chapters(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        media.padding.left + space.lg,
        top,
        media.padding.right + space.lg,
        media.padding.bottom + space.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              SizedBox(height: size.height >= 760 ? space.md : 0),
              art(
                maxWidth: size.width >= 600 && size.height >= 900
                    ? 440
                    : (size.height >= 760 ? 320 : 260),
              ),
              SizedBox(height: size.height >= 760 ? space.xl : space.md),
              titles,
              SizedBox(height: space.lg),
              controls,
              SizedBox(height: space.xxl),
              chapters(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The chapters beside the player: scrolls the current one into view
/// when the chapter changes.
class _ChaptersPane extends StatefulWidget {
  const _ChaptersPane({
    required this.index,
    required this.top,
    required this.builder,
  });

  final int index;
  final double top;
  final Widget Function(Key currentKey) builder;

  @override
  State<_ChaptersPane> createState() => _ChaptersPaneState();
}

class _ChaptersPaneState extends State<_ChaptersPane> {
  final _current = GlobalKey();

  @override
  void initState() {
    super.initState();
    _reveal(animate: false);
  }

  @override
  void didUpdateWidget(_ChaptersPane old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _reveal(animate: true);
  }

  void _reveal({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final row = _current.currentContext;
      if (!mounted || row == null) return;
      final motion = context.tokens.motion;
      Scrollable.ensureVisible(
        row,
        alignment: 0.3,
        duration: animate ? motion.of(context, motion.medium) : Duration.zero,
        curve: motion.standard,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = MediaQuery.of(context);
    final space = context.tokens.space;
    // The pane starts below the bar, so rows never scroll under its
    // buttons.
    return Padding(
      padding: EdgeInsets.only(top: widget.top),
      child: ClipRect(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            m.padding.left + space.lg,
            space.xs,
            m.padding.right + space.xl,
            m.padding.bottom + space.lg,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: widget.builder(_current),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centers [child] in the room it has, and scrolls when it doesn't fit.
class _Scrolling extends StatelessWidget {
  const _Scrolling({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - padding.vertical).clamp(
              0.0,
              double.infinity,
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
