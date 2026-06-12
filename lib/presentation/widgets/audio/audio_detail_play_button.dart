import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';

class AudioDetailPlayButton extends StatefulWidget {
  final bool hasProgress;
  final int trackIndex;
  final bool enabled;
  final bool isThisAudioActive;
  final bool isCurrentlyPlaying;
  final String label;
  final VoidCallback? onPressed;

  const AudioDetailPlayButton({
    super.key,
    required this.hasProgress,
    required this.trackIndex,
    required this.enabled,
    required this.isThisAudioActive,
    required this.isCurrentlyPlaying,
    required this.label,
    required this.onPressed,
  });

  @override
  State<AudioDetailPlayButton> createState() => _AudioDetailPlayButtonState();
}

class _AudioDetailPlayButtonState extends State<AudioDetailPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.reverse();
  void _onTapUp(TapUpDetails _) {
    _ctrl.forward();
    widget.onPressed?.call();
  }

  void _onTapCancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: widget.enabled ? _onTapDown : null,
        onTapUp: widget.enabled ? _onTapUp : null,
        onTapCancel: widget.enabled ? _onTapCancel : null,
        child: AnimatedOpacity(
          opacity: widget.enabled ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: 52.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primaryColor,
                  context.accentColor,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: widget.enabled
                  ? [
                      BoxShadow(
                        color: context.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.isThisAudioActive && widget.isCurrentlyPlaying
                        ? Icons.pause_rounded
                        : widget.hasProgress
                            ? Icons.play_circle_fill_rounded
                            : Icons.play_arrow_rounded,
                    key: ValueKey(widget.isCurrentlyPlaying),
                    color: Colors.white,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
