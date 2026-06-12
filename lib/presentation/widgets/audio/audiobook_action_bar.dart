import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_cubit.dart';
import 'package:huda/presentation/widgets/audio/audio_format.dart';
import 'package:huda/presentation/widgets/audio/audiobook_sleep_timer_sheet.dart';
import 'package:huda/l10n/app_localizations.dart';

class AudiobookActionBar extends StatelessWidget {
  final AudioPlayer player;
  final AudiobookPlayerCubit cubit;

  const AudiobookActionBar({
    super.key,
    required this.player,
    required this.cubit,
  });

  static const List<double> _speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSpeedChip(context),
        _buildSleepTimer(context),
      ],
    );
  }

  Widget _buildSpeedChip(BuildContext context) {
    return StreamBuilder<double>(
      stream: player.speedStream,
      builder: (context, snap) {
        final speed = snap.data ?? 1.0;
        return _pill(
          context,
          icon: Icons.speed_rounded,
          label: '${speed}x',
          onTap: () => _showSpeedSheet(context, speed),
        );
      },
    );
  }

  Widget _buildSleepTimer(BuildContext context) {
    return ValueListenableBuilder<Duration?>(
      valueListenable: cubit.sleepRemaining,
      builder: (context, remaining, _) {
        String label = AppLocalizations.of(context)!.sleepTimer;
        bool active = false;
        if (remaining != null) {
          active = true;
          label = remaining.isNegative
              ? AppLocalizations.of(context)!.endOfChapter
              : formatAudioDuration(remaining);
        }
        return _pill(
          context,
          icon: active ? Icons.timer_rounded : Icons.timer_outlined,
          label: label,
          highlighted: active,
          showPulse: active,
          onTap: () => _showSleepSheet(context),
        );
      },
    );
  }

  void _showSpeedSheet(BuildContext context, double current) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primaryColor;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? context.darkCardBackground : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              AppLocalizations.of(context)!.playbackSpeed,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? context.darkText : context.lightText,
              ),
            ),
            SizedBox(height: 16.h),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10.h,
              crossAxisSpacing: 10.w,
              childAspectRatio: 1.8,
              children: _speeds.map((s) {
                final selected = s == current;
                return GestureDetector(
                  onTap: () {
                    cubit.setSpeed(s);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: selected
                          ? primaryColor.withValues(alpha: 0.15)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: selected ? primaryColor : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${s}x',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.w500,
                            color: selected
                                ? primaryColor
                                : (isDark
                                    ? context.darkText
                                    : context.lightText),
                          ),
                        ),
                        if (selected)
                          Positioned(
                            top: 6.h,
                            right: 6.w,
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 12.sp,
                              color: primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSleepSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: AudiobookSleepTimerSheet(cubit: cubit),
      ),
    );
  }

  Widget _pill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlighted = false,
    bool showPulse = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = highlighted
        ? context.primaryColor
        : (isDark ? context.darkText : context.lightText);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: highlighted
                ? context.primaryColor.withValues(alpha: 0.12)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(20.r),
            border: highlighted
                ? Border.all(
                    color: context.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showPulse) ...[
                _PulsingDot(color: context.primaryColor),
                SizedBox(width: 6.w),
              ],
              Icon(icon, size: 18.sp, color: color),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _size;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _size = Tween<double>(begin: 5.0, end: 8.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _size,
      builder: (_, __) => Container(
        width: _size.value,
        height: _size.value,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
        ),
      ),
    );
  }
}
