import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class AudioDetailHeroHeader extends StatelessWidget {
  final String? artUrl;
  final String title;
  final String author;
  final int chapterCount;
  final bool isDark;

  const AudioDetailHeroHeader({
    super.key,
    required this.artUrl,
    required this.title,
    required this.author,
    required this.chapterCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasArt = artUrl != null && artUrl!.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasArt)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Image.network(
              artUrl!,
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.35),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (_, __, ___) => _solidBg(context),
            ),
          )
        else
          _solidBg(context),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.4, 1.0],
                colors: [
                  Colors.transparent,
                  isDark ? context.darkGradientStart : Colors.grey.shade50,
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 130.w,
                  height: 130.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                    gradient: !hasArt
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              context.primaryColor,
                              context.primaryColor.withValues(alpha: 0.6),
                            ],
                          )
                        : null,
                    image: hasArt
                        ? DecorationImage(
                            image: NetworkImage(artUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !hasArt
                      ? Icon(Icons.graphic_eq_rounded,
                          color: Colors.white, size: 52.sp)
                      : null,
                ),
                SizedBox(height: 16.h),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                if (author.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white.withValues(alpha: 0.75),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
                SizedBox(height: 10.h),
                _ChapterCountPill(count: chapterCount),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _solidBg(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.darkGradientStart,
            context.darkGradientMid,
            context.darkGradientEnd,
          ],
        ),
      ),
    );
  }
}

class _ChapterCountPill extends StatelessWidget {
  final int count;
  const _ChapterCountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.headphones_rounded,
              size: 13.sp, color: Colors.white.withValues(alpha: 0.9)),
          SizedBox(width: 5.w),
          Text(
            '$count ${AppLocalizations.of(context)!.chapters}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
