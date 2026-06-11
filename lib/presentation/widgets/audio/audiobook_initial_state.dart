import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';



class AudiobookInitialState extends StatefulWidget {
  final bool isDark;

  const AudiobookInitialState({super.key, required this.isDark});

  @override
  State<AudiobookInitialState> createState() => _AudiobookInitialStateState();
}

class _AudiobookInitialStateState extends State<AudiobookInitialState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.75).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? context.darkText : context.lightText;
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _opacity,
              builder: (_, __) => Opacity(
                opacity: _opacity.value,
                child: Container(
                  width: 200.w,
                  height: 200.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28.r),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.primaryColor.withValues(alpha: 0.35),
                        context.primaryColor.withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.headphones_rounded,
                    size: 80.sp,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            SizedBox(height: 28.h),
            Text(
              AppLocalizations.of(context)!.loading,
              style: TextStyle(
                fontSize: 14.sp,
                color: textColor.withValues(alpha: 0.6),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
