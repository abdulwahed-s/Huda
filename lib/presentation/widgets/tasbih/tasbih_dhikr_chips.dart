import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_dhikr_list.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_dhikr_row.dart';

/// The dhikr to count, as one scrolling row of chips (the selected one is
/// lit). Phones only: switching happens here, and the bar's list button
/// opens the sheet for adding and removing. Wider windows show the list.
///
/// After a dhikr is removed in the sheet, the row starts with an "Undo"
/// chip for the rest of its time, so Undo stays where the dhikr live
/// instead of floating over them.
class TasbihDhikrChips extends StatefulWidget {
  const TasbihDhikrChips({
    super.key,
    required this.notes,
    required this.selected,
    required this.onSelected,
    required this.undo,
    required this.onUndo,
    this.padding = EdgeInsets.zero,
  });

  final List<TasbihNote> notes;
  final int selected;
  final ValueChanged<int> onSelected;
  final TasbihUndo undo;
  final VoidCallback onUndo;

  /// Scroll padding: the gutter plus any side inset, so the row scrolls
  /// under an inset and comes to rest clear of it.
  final EdgeInsets padding;

  @override
  State<TasbihDhikrChips> createState() => _TasbihDhikrChipsState();
}

class _TasbihDhikrChipsState extends State<TasbihDhikrChips> {
  final _selectedKey = GlobalKey();
  final _scroll = ScrollController();
  bool _undoShown = false;

  @override
  void dispose() {
    widget.undo.removeListener(_undoChanged);
    _scroll.dispose();
    super.dispose();
  }

  /// Undo shows once the sheet it was removed in has closed (this page is
  /// the current route again), so it arrives where people can see it.
  bool get _wantUndo =>
      widget.undo.pending && (ModalRoute.of(context)?.isCurrent ?? true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(rebuild: false);
  }

  void _undoChanged() => _sync(rebuild: true);

  /// Brings a new Undo chip into view at the row's start.
  void _sync({required bool rebuild}) {
    if (!mounted) return;
    final shown = _wantUndo;
    if (shown == _undoShown) return;
    if (rebuild) {
      setState(() => _undoShown = shown);
    } else {
      _undoShown = shown;
    }
    if (!shown) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final motion = context.tokens.motion;
      final duration = motion.of(context, motion.medium);
      final start = _scroll.position.minScrollExtent;
      if (duration == Duration.zero) {
        _scroll.jumpTo(start);
      } else {
        _scroll.animateTo(start, duration: duration, curve: motion.standard);
      }
    });
  }

  /// Whether chips run past the row's left and right ends (physical, as
  /// the fade is), so only an edge with more to scroll to fades.
  bool _moreLeft = false;
  bool _moreRight = false;

  bool _onMetrics(ScrollMetrics metrics) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final before = metrics.pixels > metrics.minScrollExtent + 0.5;
    final after = metrics.pixels < metrics.maxScrollExtent - 0.5;
    // In RTL the row starts at the right.
    final left = rtl ? after : before;
    final right = rtl ? before : after;
    if (left != _moreLeft || right != _moreRight) {
      setState(() {
        _moreLeft = left;
        _moreRight = right;
      });
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    widget.undo.addListener(_undoChanged);
    _reveal(animate: false);
  }

  @override
  void didUpdateWidget(TasbihDhikrChips old) {
    super.didUpdateWidget(old);
    if (old.undo != widget.undo) {
      old.undo.removeListener(_undoChanged);
      widget.undo.addListener(_undoChanged);
    }
    if (old.selected != widget.selected) _reveal(animate: true);
  }

  /// Keeps the selected chip in view.
  void _reveal({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chip = _selectedKey.currentContext;
      if (chip == null || !chip.mounted) return;
      final motion = chip.tokens.motion;
      Scrollable.ensureVisible(
        chip,
        alignment: 0.5,
        duration: animate ? motion.of(chip, motion.medium) : Duration.zero,
        curve: motion.standard,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final scheme = Theme.of(context).colorScheme;
    final notes = widget.notes;
    const clear = Color(0x00000000);
    const shown = Color(0xFF000000);
    final removed = widget.undo.note?.text ?? '';
    // An action, not another dhikr: a tonal pill with no outline.
    final undoSlot = _UndoChipIn(
      visible: _undoShown,
      child: Padding(
        padding: EdgeInsetsDirectional.only(end: space.xs),
        // Names what it brings back: the sheet that said so is closed.
        child: Tooltip(
          message: '${l10n.undo}: $removed',
          excludeFromSemantics: true,
          child: Semantics(
            label: '${l10n.tasbihDhikrRemoved}: $removed. ${l10n.undo}',
            button: true,
            excludeSemantics: true,
            child: ActionChip(
              onPressed: widget.onUndo,
              shape: const StadiumBorder(),
              side: BorderSide.none,
              // `color`, not `backgroundColor`: the theme's chip color
              // (transparent when unselected) would win over the latter.
              color: WidgetStatePropertyAll(
                tokens.onChrome.withValues(alpha: 0.14),
              ),
              avatar: Icon(Icons.undo_rounded, color: scheme.onSurface),
              label: Text(
                l10n.undo,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: scheme.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
    // Where more chips lie beyond an end, the row fades out there instead
    // of cutting a chip at a line.
    final row = ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          _moreLeft ? clear : shown,
          shown,
          shown,
          _moreRight ? clear : shown,
        ],
        stops: [
          0,
          math.min(0.5, space.md / bounds.width),
          math.max(0.5, 1 - space.md / bounds.width),
          1,
        ],
      ).createShader(bounds),
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        child: Row(
          children: [
            undoSlot,
            for (var i = 0; i < notes.length; i++) ...[
              if (i > 0) SizedBox(width: space.xs),
              ConstrainedBox(
                key: i == widget.selected ? _selectedKey : null,
                constraints: const BoxConstraints(maxWidth: 240),
                child: ChoiceChip(
                  selected: i == widget.selected,
                  onSelected: (_) => widget.onSelected(i),
                  label: Text(
                    notes[i].text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: tasbihTextDirection(notes[i].text),
                    style: tasbihDhikrLabelStyle(
                      context,
                      notes[i].text,
                    ).copyWith(color: scheme.onSurface),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _onMetrics(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _onMetrics(n.metrics),
        child: row,
      ),
    );
  }
}

/// The Undo chip arriving and leaving: it opens to its width and fades in,
/// and folds away the same way. Instant under reduce motion.
class _UndoChipIn extends StatefulWidget {
  const _UndoChipIn({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  State<_UndoChipIn> createState() => _UndoChipInState();
}

class _UndoChipInState extends State<_UndoChipIn>
    with SingleTickerProviderStateMixin {
  late final _open = AnimationController(
    vsync: this,
    value: widget.visible ? 1 : 0,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = context.tokens.motion;
    _open.duration = motion.of(context, motion.medium);
  }

  @override
  void didUpdateWidget(_UndoChipIn old) {
    super.didUpdateWidget(old);
    if (widget.visible == old.visible) return;
    if (_open.duration == Duration.zero) {
      _open.value = widget.visible ? 1 : 0;
    } else if (widget.visible) {
      _open.forward();
    } else {
      _open.reverse();
    }
  }

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = CurvedAnimation(
      parent: _open,
      curve: context.tokens.motion.standard,
    );
    return AnimatedBuilder(
      animation: _open,
      builder: (context, child) => _open.isDismissed
          ? const SizedBox.shrink()
          : SizeTransition(
              axis: Axis.horizontal,
              sizeFactor: t,
              alignment: AlignmentDirectional.centerStart,
              child: FadeTransition(opacity: t, child: child),
            ),
      child: widget.child,
    );
  }
}
