import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class TasbihNotesWheel extends StatefulWidget {
  final List<TasbihNote> notes;
  final int selectedIndex;
  final void Function(int) onSelected;

  const TasbihNotesWheel({
    super.key,
    required this.notes,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<TasbihNotesWheel> createState() => _TasbihNotesWheelState();
}

class _TasbihNotesWheelState extends State<TasbihNotesWheel> {
  late FixedExtentScrollController _controller;
  static const double _itemExtent = 80.0;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: widget.notes.isEmpty
          ? 0
          : widget.selectedIndex.clamp(0, widget.notes.length - 1),
    );
  }

  @override
  void didUpdateWidget(TasbihNotesWheel old) {
    super.didUpdateWidget(old);
    if (widget.notes.isEmpty) return;
    final target = widget.selectedIndex.clamp(0, widget.notes.length - 1);
    if (old.selectedIndex != widget.selectedIndex &&
        _controller.hasClients &&
        _controller.selectedItem != target) {
      _controller.animateToItem(
        target,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notes.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 28.sp,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              SizedBox(height: 8.h),
              Text(
                AppLocalizations.of(context)!.noDhikrYet,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13.sp,
                  fontFamily: 'Amiri',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white,
          Colors.white,
          Colors.transparent,
        ],
        stops: [0.0, 0.18, 0.82, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: ListWheelScrollView.useDelegate(
        controller: _controller,
        physics: const FixedExtentScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemExtent: _itemExtent,
        diameterRatio: 6.0,
        squeeze: 0.88,
        onSelectedItemChanged: widget.onSelected,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: widget.notes.length,
          builder: (context, index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final double fractional =
                    (_controller.hasClients &&
                            _controller.position.hasContentDimensions)
                        ? _controller.offset / _itemExtent
                        : widget.selectedIndex.toDouble();

                final double dist =
                    (index.toDouble() - fractional).clamp(-3.0, 3.0);
                final double distAbs = dist.abs();

                final double textAlpha =
                    (1.0 - distAbs * 0.40).clamp(0.08, 1.0);
                final double pillAlpha =
                    (1.0 - distAbs * 2.8).clamp(0.0, 1.0);
                final double scale =
                    (1.0 - distAbs * 0.055).clamp(0.80, 1.0);

                final bool isSelected = index == widget.selectedIndex;

                return Center(
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 10.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: isSelected ? 7.h : 4.h,
                      ),
                      decoration: pillAlpha > 0.02
                          ? BoxDecoration(
                              color: Colors.white
                                  .withValues(alpha: 0.19 * pillAlpha),
                              borderRadius: BorderRadius.circular(50.r),
                              border: Border.all(
                                color: Colors.white
                                    .withValues(alpha: 0.46 * pillAlpha),
                                width: 1.5,
                              ),
                              boxShadow: pillAlpha > 0.6
                                  ? [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.12 * pillAlpha),
                                        blurRadius: 12,
                                        spreadRadius: -2,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            )
                          : null,
                      child: Text(
                        widget.notes[index].text,
                        textAlign: TextAlign.center,
                        maxLines: isSelected ? 4 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isSelected ? 14.sp : 11.5.sp,
                          color: Colors.white.withValues(alpha: textAlpha),
                          fontFamily: 'Amiri',
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w400,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
