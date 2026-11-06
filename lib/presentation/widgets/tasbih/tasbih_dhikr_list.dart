import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_dhikr_row.dart';

/// A dhikr just removed, and how to put it back. The screen owns one, so
/// Undo outlives the list that showed it: the pane emptying, or the phone
/// sheet closing (the chip row then offers Undo, or the empty state when no
/// dhikr is left).
class TasbihUndo extends ChangeNotifier {
  static const undoFor = Duration(seconds: 6);

  TasbihNote? _note;
  int _index = 0;
  bool _wasSelected = false;
  bool _expiring = false;
  Timer? _timer;

  bool get pending => _note != null && !_expiring;
  bool get expiring => _expiring;
  int? get index => _note == null ? null : _index;

  /// The removed dhikr itself: a new removal is a new Undo row.
  TasbihNote? get note => _note;

  void remove(TasbihCubit cubit, TasbihLoaded state, int index) {
    _timer?.cancel();
    _note = state.notes[index];
    _index = index;
    _wasSelected = index == state.selectedNoteIndex;
    _expiring = false;
    cubit.removeNote(index);
    // Then the Undo row folds away (`medium`) and is gone.
    _timer = Timer(undoFor, () {
      _expiring = true;
      notifyListeners();
      _timer = Timer(const Duration(milliseconds: 300), clear);
    });
    notifyListeners();
  }

  /// Where the last Undo put a dhikr back: that row takes the Undo row's
  /// place, so it fades in at its height instead of opening.
  int? restoredAt;

  void undo(TasbihCubit cubit) {
    final note = _note;
    if (note == null) return;
    restoredAt = _index;
    cubit.restoreNote(_index, note, select: _wasSelected);
    clear();
  }

  void clear() {
    _timer?.cancel();
    if (_note == null) return;
    _note = null;
    _expiring = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// The dhikr with their counts: tap a row to count it, the trash icon to
/// remove it. A removed dhikr leaves an "Undo" row in its place for a few
/// seconds, so removing needs no confirmation. Added and restored rows
/// open to their height. Used inline by the list pane and inside the phone
/// sheet, so both work the same way.
class TasbihDhikrList extends StatefulWidget {
  const TasbihDhikrList({
    super.key,
    required this.state,
    required this.cubit,
    required this.undo,
    this.revealFrom,
  });

  final TasbihLoaded state;
  final TasbihCubit cubit;
  final TasbihUndo undo;

  /// The first [HudaReveal] index for the rows when the list arrives with
  /// the screen; null when it opens in a sheet.
  final int? revealFrom;

  @override
  State<TasbihDhikrList> createState() => _TasbihDhikrListState();
}

class _TasbihDhikrListState extends State<TasbihDhikrList> {
  final _lastKey = GlobalKey();

  /// The row that just arrived (added or restored), and a token that
  /// makes it open again for the next arrival.
  int? _entering;
  int _enterToken = 0;
  bool _entersInPlace = false;

  @override
  void initState() {
    super.initState();
    widget.undo.addListener(_changed);
  }

  @override
  void didUpdateWidget(TasbihDhikrList old) {
    super.didUpdateWidget(old);
    if (old.undo != widget.undo) {
      old.undo.removeListener(_changed);
      widget.undo.addListener(_changed);
    }
    final before = old.state.notes;
    final after = widget.state.notes;
    if (after.length != before.length + 1) return;
    // The first place the lists differ is the row that arrived.
    var at = 0;
    while (at < before.length && identical(before[at], after[at])) {
      at++;
    }
    _entering = at;
    _enterToken++;
    _entersInPlace = at == widget.undo.restoredAt;
    widget.undo.restoredAt = null;
    // A new dhikr at the end comes into view.
    if (at == after.length - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final last = _lastKey.currentContext;
        if (last == null || !last.mounted) return;
        final motion = last.tokens.motion;
        Scrollable.ensureVisible(
          last,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          duration: motion.of(last, motion.long),
          curve: motion.standard,
        );
      });
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.undo.removeListener(_changed);
    super.dispose();
  }

  void _remove(int index) {
    _entering = null;
    widget.undo.remove(widget.cubit, widget.state, index);
    HudaHaptics.light(context, enabled: widget.state.mode);
  }

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final notes = widget.state.notes;
    final undo = widget.undo;
    final undoAt = undo.index?.clamp(0, notes.length);
    final revealFrom = widget.revealFrom;

    Widget reveal(int i, Widget child) => revealFrom == null
        ? child
        : HudaReveal(index: revealFrom + i, child: child);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i <= notes.length; i++) ...[
          if (i == undoAt)
            Padding(
              padding: EdgeInsets.only(bottom: space.xs),
              child: _UndoRow(
                key: ObjectKey(undo.note),
                onUndo: () => undo.undo(widget.cubit),
                expiring: undo.expiring,
                onGone: undo.clear,
              ),
            ),
          if (i < notes.length)
            reveal(
              i,
              _Enter(
                key: i == _entering ? ValueKey(_enterToken) : null,
                animate: i == _entering,
                grow: !_entersInPlace,
                child: Padding(
                  key: i == notes.length - 1 ? _lastKey : null,
                  padding: EdgeInsets.only(bottom: space.xs),
                  child: TasbihDhikrRow(
                    note: notes[i],
                    selected: i == widget.state.selectedNoteIndex,
                    onTap: () => widget.cubit.selectNote(i),
                    onDelete: () => _remove(i),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// A row that just arrived opens to its height and fades in, so the rows
/// below move instead of jumping.
class _Enter extends StatefulWidget {
  const _Enter({
    super.key,
    required this.animate,
    required this.child,
    this.grow = true,
  });

  final bool animate;

  /// False for a row restored where its Undo row was: it only fades in.
  final bool grow;
  final Widget child;

  @override
  State<_Enter> createState() => _EnterState();
}

class _EnterState extends State<_Enter> with SingleTickerProviderStateMixin {
  late final _open = AnimationController(
    vsync: this,
    value: widget.animate ? 0 : 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = context.tokens.motion;
    _open.duration = motion.of(context, motion.medium);
    if (_open.isDismissed) _open.forward();
  }

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = context.tokens.motion.standard;
    final t = CurvedAnimation(parent: _open, curve: curve);
    final faded = FadeTransition(opacity: t, child: widget.child);
    if (!widget.grow) return faded;
    return SizeTransition(
      sizeFactor: t,
      alignment: AlignmentDirectional.topStart,
      child: faded,
    );
  }
}

/// Where a removed dhikr was: "Dhikr removed · Undo". It fades in where
/// the row was, and folds away (its height animating) when Undo expires.
class _UndoRow extends StatefulWidget {
  const _UndoRow({
    super.key,
    required this.onUndo,
    required this.expiring,
    required this.onGone,
  });

  final VoidCallback onUndo;
  final bool expiring;
  final VoidCallback onGone;

  @override
  State<_UndoRow> createState() => _UndoRowState();
}

class _UndoRowState extends State<_UndoRow> with TickerProviderStateMixin {
  late final _fade = AnimationController(vsync: this);
  late final _fold = AnimationController(vsync: this, value: 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = context.tokens.motion;
    _fade.duration = motion.of(context, motion.medium);
    _fold.duration = motion.of(context, motion.medium);
    if (_fade.isDismissed) _fade.forward();
  }

  @override
  void didUpdateWidget(_UndoRow old) {
    super.didUpdateWidget(old);
    if (widget.expiring && !old.expiring) {
      _fold.reverse().whenComplete(() {
        if (mounted) widget.onGone();
      });
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    _fold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final scheme = Theme.of(context).colorScheme;
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: _fold, curve: tokens.motion.standard),
      alignment: AlignmentDirectional.topStart,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _fade, curve: tokens.motion.standard),
        child: Semantics(
          liveRegion: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: EdgeInsetsDirectional.only(
              start: space.md,
              end: space.xxs,
            ),
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: tokens.radius.card,
                side: BorderSide(color: scheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.tasbihDhikrRemoved,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton(onPressed: widget.onUndo, child: Text(l10n.undo)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Adds a dhikr: a text field and a lit "+" (Enter also adds). Stays
/// focused after adding, so several can be added in a row.
class TasbihDhikrComposer extends StatefulWidget {
  const TasbihDhikrComposer({super.key, required this.cubit});

  final TasbihCubit cubit;

  @override
  State<TasbihDhikrComposer> createState() => _TasbihDhikrComposerState();
}

class _TasbihDhikrComposerState extends State<TasbihDhikrComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.cubit.addNote(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(hintText: l10n.enterDhikrHint),
            minLines: 1,
            maxLines: 3,
            // Wraps long dhikr, and Enter adds instead of a new line.
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ),
        SizedBox(width: space.xs),
        // Adding is the primary action here: lit.
        Tooltip(
          message: l10n.addDhikr,
          child: Semantics(
            label: l10n.addDhikr,
            button: true,
            excludeSemantics: true,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(56, 56),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ),
      ],
    );
  }
}
