import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

typedef ReorderLayoutItemBuilder<T extends Object> =
    Widget Function(BuildContext context, T item, bool lifted);

class AnimatedReorderLayout<T extends Object> extends StatefulWidget {
  const AnimatedReorderLayout({
    super.key,
    required this.items,
    required this.columns,
    required this.itemExtent,
    required this.itemBuilder,
    required this.onReorder,
    required this.moveUpLabel,
    required this.moveDownLabel,
    this.spacing = 12,
    this.onDragUpdate,
    this.semanticLabelBuilder,
  });

  final List<T> items;
  final int columns;
  final double itemExtent;
  final double spacing;
  final ReorderLayoutItemBuilder<T> itemBuilder;
  final void Function(T dragged, T target) onReorder;
  final ValueChanged<DragUpdateDetails>? onDragUpdate;
  final String Function(T item)? semanticLabelBuilder;
  final String moveUpLabel;
  final String moveDownLabel;

  @override
  State<AnimatedReorderLayout<T>> createState() =>
      _AnimatedReorderLayoutState<T>();
}

class _AnimatedReorderLayoutState<T extends Object>
    extends State<AnimatedReorderLayout<T>> {
  T? _dragging;
  T? _lastTarget;
  Offset? _lastDragOffset;
  Offset? _lastReorderDirection;

  bool get _usesImmediateDrag {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => true,
      _ => false,
    };
  }

  @override
  void didUpdateWidget(covariant AnimatedReorderLayout<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragging != null && !widget.items.contains(_dragging)) {
      _finishDrag();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final columns = widget.columns.clamp(1, widget.items.length);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemWidth = (width - widget.spacing * (columns - 1)) / columns;
        final rows = (widget.items.length / columns).ceil();
        final height =
            rows * widget.itemExtent +
            (rows > 1 ? (rows - 1) * widget.spacing : 0);

        return AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < widget.items.length; index++)
                _positionedItem(
                  context,
                  item: widget.items[index],
                  index: index,
                  columns: columns,
                  width: itemWidth,
                  reduceMotion: reduceMotion,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _positionedItem(
    BuildContext context, {
    required T item,
    required int index,
    required int columns,
    required double width,
    required bool reduceMotion,
  }) {
    final row = index ~/ columns;
    final column = index % columns;
    return AnimatedPositionedDirectional(
      key: ValueKey<T>(item),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      start: column * (width + widget.spacing),
      top: row * (widget.itemExtent + widget.spacing),
      width: width,
      height: widget.itemExtent,
      child: _AppearTransition(
        reduceMotion: reduceMotion,
        child: DragTarget<T>(
          onWillAcceptWithDetails: (details) {
            if (details.data == item) {
              _lastDragOffset = details.offset;
              return false;
            }
            _reorderFromDrag(details, item);
            return true;
          },
          onMove: (details) {
            if (details.data == item) {
              _lastDragOffset = details.offset;
              return;
            }
            _reorderFromDrag(details, item);
          },
          onLeave: (_) {
            if (_lastTarget == item) _lastTarget = null;
          },
          onAcceptWithDetails: (_) {},
          builder: (context, candidates, rejected) {
            final targeted = candidates.any((candidate) => candidate != item);
            return AnimatedScale(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 150),
              curve: Curves.easeOutBack,
              scale: targeted ? 1.035 : 1,
              child: _buildDraggable(context, item, width, index),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDraggable(
    BuildContext context,
    T item,
    double width,
    int index,
  ) {
    final semanticActions = <CustomSemanticsAction, VoidCallback>{
      if (index > 0)
        CustomSemanticsAction(label: widget.moveUpLabel): () =>
            widget.onReorder(item, widget.items[index - 1]),
      if (index < widget.items.length - 1)
        CustomSemanticsAction(label: widget.moveDownLabel): () =>
            widget.onReorder(item, widget.items[index + 1]),
    };
    final child = MouseRegion(
      cursor: _dragging == item
          ? SystemMouseCursors.grabbing
          : SystemMouseCursors.grab,
      child: Semantics(
        container: true,
        label: widget.semanticLabelBuilder?.call(item),
        customSemanticsActions: semanticActions,
        child: widget.itemBuilder(context, item, _dragging == item),
      ),
    );
    final feedback = Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: width,
        height: widget.itemExtent,
        child: Transform.rotate(
          angle: -0.012,
          child: Transform.scale(
            scale: 1.035,
            child: widget.itemBuilder(context, item, true),
          ),
        ),
      ),
    );
    final childWhenDragging = IgnorePointer(
      child: Opacity(
        opacity: 0.24,
        child: widget.itemBuilder(context, item, true),
      ),
    );

    if (_usesImmediateDrag) {
      return Draggable<T>(
        data: item,
        maxSimultaneousDrags: _dragging == null || _dragging == item ? 1 : 0,
        feedback: feedback,
        childWhenDragging: childWhenDragging,
        onDragStarted: () => _startDrag(item),
        onDragUpdate: widget.onDragUpdate,
        onDragEnd: (_) => _finishDrag(),
        rootOverlay: true,
        child: child,
      );
    }

    return LongPressDraggable<T>(
      data: item,
      delay: const Duration(milliseconds: 260),
      maxSimultaneousDrags: _dragging == null || _dragging == item ? 1 : 0,
      feedback: feedback,
      childWhenDragging: childWhenDragging,
      onDragStarted: () => _startDrag(item),
      onDragUpdate: widget.onDragUpdate,
      onDragEnd: (_) => _finishDrag(),
      rootOverlay: true,
      hapticFeedbackOnStart: false,
      child: child,
    );
  }

  void _startDrag(T item) {
    HapticFeedback.mediumImpact();
    setState(() {
      _dragging = item;
      _lastTarget = null;
      _lastDragOffset = null;
      _lastReorderDirection = null;
    });
  }

  void _reorderFromDrag(DragTargetDetails<T> details, T target) {
    final previousOffset = _lastDragOffset;
    final movement = previousOffset == null
        ? null
        : details.offset - previousOffset;
    final lastDirection = _lastReorderDirection;
    final reversed =
        _lastTarget == target &&
        movement != null &&
        movement.distanceSquared > 0.25 &&
        lastDirection != null &&
        movement.dx * lastDirection.dx + movement.dy * lastDirection.dy < 0;

    if (_lastTarget != target || reversed) {
      widget.onReorder(details.data, target);
      _lastTarget = target;
      if (movement != null && movement.distanceSquared > 0.25) {
        _lastReorderDirection = movement;
      }
    }
    _lastDragOffset = details.offset;
  }

  void _finishDrag() {
    if (!mounted) return;
    setState(() {
      _dragging = null;
      _lastTarget = null;
      _lastDragOffset = null;
      _lastReorderDirection = null;
    });
  }
}

class _AppearTransition extends StatelessWidget {
  const _AppearTransition({required this.reduceMotion, required this.child});

  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(scale: 0.94 + value * 0.06, child: child),
      ),
    );
  }
}
