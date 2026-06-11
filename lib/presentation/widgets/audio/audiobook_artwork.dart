import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';





class AudiobookArtwork extends StatefulWidget {
  final AudioPlayer player;
  final String? artUrl;
  final bool isOffline;

  const AudiobookArtwork({
    super.key,
    required this.player,
    required this.artUrl,
    required this.isOffline,
  });

  @override
  State<AudiobookArtwork> createState() => _AudiobookArtworkState();
}

class _AudiobookArtworkState extends State<AudiobookArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final Animation<double> _breathScale;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _breathScale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  void _manageBreathAnimation(bool playing) {
    if (!mounted) return;
    if (playing && !_breathCtrl.isAnimating) {
      _breathCtrl.repeat(reverse: true);
    } else if (!playing && _breathCtrl.isAnimating) {
      _breathCtrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasArt = widget.artUrl != null && widget.artUrl!.isNotEmpty;
    final primaryColor = context.primaryColor;

    return StreamBuilder<PlayerState>(
      stream: widget.player.playerStateStream,
      builder: (context, snap) {
        _manageBreathAnimation(snap.data?.playing ?? false);

        return Center(
          child: AnimatedBuilder(
            animation: _breathScale,
            builder: (_, child) => Transform.scale(
              scale: _breathScale.value,
              child: child,
            ),
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 16.h),
              width: 240.w,
              height: 240.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _breathScale,
                    builder: (_, child) {
                      final t = (_breathScale.value - 1.0) / 0.03; 
                      return Container(
                        width: 240.w,
                        height: 240.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28.r),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.6),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(
                                  alpha: 0.25 + 0.2 * t),
                              blurRadius: 30 + 20 * t,
                              offset: const Offset(0, 12),
                              spreadRadius: t * 2,
                            ),
                          ],
                          image: hasArt
                              ? DecorationImage(
                                  image: NetworkImage(widget.artUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: child,
                      );
                    },
                    child: !hasArt
                        ? Icon(Icons.graphic_eq_rounded,
                            size: 96.sp, color: Colors.white)
                        : null,
                  ),
                  if (widget.isOffline)
                    Positioned(
                      bottom: 10.h,
                      right: 10.w,
                      child: const _OfflineBadge(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_done_rounded, size: 12.sp, color: Colors.white),
          SizedBox(width: 4.w),
          Text(
            AppLocalizations.of(context)!.audiobookDownloaded,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
