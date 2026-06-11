import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class AudiosAppBar extends StatelessWidget {
  final bool isDark;

  const AudiosAppBar({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = context.primaryColor;
    final bgColor = isDark ? Colors.grey[900]! : Colors.grey[50]!;

    return SliverAppBar(
      elevation: 0,
      backgroundColor: bgColor,
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : Colors.black,
      ),
      surfaceTintColor: Colors.transparent,
      pinned: true,
      floating: false,
      expandedHeight: 140.h,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsetsDirectional.only(
          start: 50.w,
          bottom: 5.h,
        ),
        title: Text(
          AppLocalizations.of(context)!.audios,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Amiri',
            color: isDark ? context.darkText : context.lightText,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark ? context.darkCardBackground : Colors.white,
                    bgColor,
                  ],
                ),
              ),
            ),
            
            Positioned.directional(
              textDirection: Directionality.of(context),
              end: -20.w,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.album_rounded,
                  size: 130.sp,
                  color: primary.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned.directional(
              textDirection: Directionality.of(context),
              end: 60.w,
              top: 10.h,
              child: Icon(
                Icons.headphones_rounded,
                size: 48.sp,
                color: primary.withValues(alpha: 0.06),
              ),
            ),
            
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary.withValues(alpha: 0.0),
                      primary.withValues(alpha: 0.35),
                      primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
