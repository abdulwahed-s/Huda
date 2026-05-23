import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_notes_wheel.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';

class TasbihCard extends StatelessWidget {
  final List<TasbihNote> notes;
  final int selectedNoteIndex;
  final int currentCount;
  final void Function(int) onNoteSelected;

  const TasbihCard({
    super.key,
    required this.notes,
    required this.selectedNoteIndex,
    required this.currentCount,
    required this.onNoteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final primary = context.primaryColor;
    final primaryDark = context.primaryDarkColor;
    final accent = context.accentColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
          colors: [
            primaryDark,
            primary,
            accent.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          children: [
            _CardDecorativeCircle(top: -50.h, right: -50.w, size: 180.w, opacity: 0.06),
            _CardDecorativeCircle(bottom: -30.h, left: -30.w, size: 140.w, opacity: 0.05),
            _CardDecorativeCircle(top: 20.h, left: 20.w, size: 60.w, opacity: 0.04),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 72.h,
                child: WaveWidget(
                  config: CustomConfig(
                    colors: [
                      Colors.white.withValues(alpha: 0.07),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                    durations: const [22000, 14000],
                    heightPercentages: const [0.3, 0.55],
                  ),
                  backgroundColor: Colors.transparent,
                  size: Size(double.infinity, 72.h),
                  waveAmplitude: 6,
                ),
              ),
            ),
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TasbihNotesWheel(
                      notes: notes,
                      selectedIndex: selectedNoteIndex,
                      onSelected: onNoteSelected,
                    ),
                  ),
                  const _CardVerticalDivider(),
                  SizedBox(
                    width: 88.w,
                    child: Center(
                      child: Text(
                        currentCount.toString(),
                        style: TextStyle(
                          fontSize: 64.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardDecorativeCircle extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final double opacity;

  const _CardDecorativeCircle({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _CardVerticalDivider extends StatelessWidget {
  const _CardVerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: EdgeInsets.symmetric(vertical: 20.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0x59FFFFFF), Colors.transparent],
        ),
      ),
    );
  }
}
