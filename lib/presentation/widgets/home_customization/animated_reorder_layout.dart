import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef ReorderLayoutItemBuilder<T extends Object> = Widget Function(
  BuildContext context,
  T item,
  bool lifted,
);

class AnimatedReorderLayout<T extends Object> extends StatefulWidget {
  const AnimatedReorderLayout({
    super.key,
    required this.items,
    required this.columns,
    required this.itemExtent,
    required this.itemBuilder,
    required this.onReorder,
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

  @override
  State<AnimatedReorderLayout<T>> createState() =>
      _AnimatedReorderLayoutState<T>();
}

class _AnimatedReorderLayoutState<T extends Object>
    extends State<AnimatedReorderLayout<T>> {
  T? _dragging;
  T? _lastTarget;

  bool get _usesImmediateDrag {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux =>
        true,
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
        final height = rows * widget.itemExtent +
            (rows - 1).clamp(0, rows) * widget.spacing;

        return AnimatedContainer(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 240),
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
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 230),
      curve: Curves.easeOutCubic,
      start: column * (width + widget.spacing),
      top: row * (widget.itemExtent + widget.spacing),
      width: width,
      height: widget.itemExtent,
      child: DragTarget<T>(
        onWillAcceptWithDetails: (details) {
          if (details.data == item || _lastTarget == item) return false;
          _lastTarget = item;
          widget.onReorder(details.data, item);
          return true;
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
            child: _buildDraggable(context, item, width),
          );
        },
      ),
    );
  }

  Widget _buildDraggable(BuildContext context, T item, double width) {
    final child = MouseRegion(
      cursor: _dragging == item
          ? SystemMouseCursors.grabbing
          : SystemMouseCursors.grab,
      child: Semantics(
        label: widget.semanticLabelBuilder?.call(item),
        child: widget.itemBuilder(context, item, _dragging == item),
      ),
    );
    final feedback = Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: width,
        height: widget.itemExtent,
        child: Transform.rotate(
          angle: -0.018,
          child: Transform.scale(
            scale: 1.045,
            child: widget.itemBuilder(context, item, true),
          ),
        ),
      ),
    );
    final childWhenDragging = IgnorePointer(
      child: Opacity(
        opacity: 0.22,
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
    });
  }

  void _finishDrag() {
    if (!mounted) return;
    setState(() {
      _dragging = null;
      _lastTarget = null;
    });
  }
}
