import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:huda/data/models/radio_station_model.dart';

class RadioStationCard extends StatefulWidget {
  final RadioStation station;
  final bool isActive;
  final bool isPlaying;
  final bool isBuffering;
  final AnimationController pulseController;
  final VoidCallback onTap;
  final int index;

  const RadioStationCard({
    super.key,
    required this.station,
    required this.isActive,
    required this.isPlaying,
    required this.isBuffering,
    required this.pulseController,
    required this.onTap,
    required this.index,
  });

  @override
  State<RadioStationCard> createState() => _RadioStationCardState();
}

class _RadioStationCardState extends State<RadioStationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim =
        CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceController, curve: Curves.easeOutCubic));

    final delay = (widget.index * 30).clamp(0, 120);
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(18.r),
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                constraints: BoxConstraints(minHeight: 76.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.r),
                  color: widget.isActive
                      ? theme.colorScheme.primary
                          .withValues(alpha: isDark ? 0.18 : 0.07)
                      : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                  border: Border.all(
                    color: widget.isActive
                        ? theme.colorScheme.primary.withValues(alpha: 0.5)
                        : theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.35),
                    width: widget.isActive ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isActive
                          ? theme.colorScheme.primary.withValues(alpha: 0.13)
                          : Colors.black
                              .withValues(alpha: isDark ? 0.12 : 0.04),
                      blurRadius: widget.isActive ? 18 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18.r),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          width: 4.w,
                          decoration: BoxDecoration(
                            gradient: widget.isActive
                                ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                  )
                                : null,
                            color: widget.isActive ? null : Colors.transparent,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          width: 46.r,
                          height: 46.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: widget.isActive
                                ? LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                  )
                                : null,
                            color: widget.isActive
                                ? null
                                : theme.colorScheme.secondaryContainer,
                          ),
                          child: Icon(
                            Icons.radio_rounded,
                            color: widget.isActive
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSecondaryContainer,
                            size: 22.sp,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Text(
                                widget.station.name.toString(),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: widget.isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: widget.isActive
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.isActive && widget.isPlaying)
                                Padding(
                                  padding: EdgeInsets.only(top: 3.h),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6.r,
                                        height: 6.r,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      SizedBox(width: 5.w),
                                      Text(
                                        'Live',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Padding(
                          padding: EdgeInsets.only(right: 16.w, left: 16.w),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(scale: anim, child: child),
                            child: widget.isActive && widget.isBuffering
                                ? SizedBox(
                                    key: const ValueKey('buf'),
                                    width: 22.sp,
                                    height: 22.sp,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : (widget.isActive && widget.isPlaying)
                                    ? AnimatedBuilder(
                                        key: const ValueKey('eq'),
                                        animation: widget.pulseController,
                                        builder: (_, __) => Icon(
                                          Icons.graphic_eq_rounded,
                                          color: theme.colorScheme.primary,
                                          size: 28.sp,
                                        ),
                                      )
                                    : Icon(
                                        Icons.play_circle_filled_rounded,
                                        key:
                                            ValueKey('play_${widget.isActive}'),
                                        color: widget.isActive
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.secondary
                                                .withValues(alpha: 0.45),
                                        size: 32.sp,
                                      ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
