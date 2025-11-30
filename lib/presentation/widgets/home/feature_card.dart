import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/core/utils/responsive_utils.dart';

class FeatureCard extends StatelessWidget {
  final String title;
  final String? svgAsset;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isDarkMode;
  final int index;

  const FeatureCard({
    super.key,
    required this.title,
    this.svgAsset,
    this.icon,
    required this.onTap,
    required this.isDarkMode,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize =
        context.responsive(mobile: 32.sp, tablet: 50.sp, desktop: 64.sp);
    final paddingSize =
        context.responsive(mobile: 12.w, tablet: 20.w, desktop: 24.w);
    final fontSize =
        context.responsive(mobile: 12.sp, tablet: 16.sp, desktop: 20.sp);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        const Color(0xFF2B2F3A),
                        const Color(0xFF1E2230),
                      ]
                    : [
                        const Color(0xFFFFFFFF),
                        const Color(0xFFF8FAFF),
                      ],
              ),
              border: Border.all(
                color: (isDarkMode ? Colors.white : Colors.black)
                    .withValues(alpha: 0.06),
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16.r),
                onTap: () {
                  onTap();
                },
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (svgAsset != null)
                        Flexible(
                          flex: 0,
                          child: Container(
                            padding: EdgeInsets.all(paddingSize),
                            decoration: BoxDecoration(
                              color:
                                  context.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: context.primaryColor
                                    .withValues(alpha: 0.12),
                              ),
                            ),
                            child: SvgPicture.asset(
                              svgAsset!,
                              width: iconSize,
                              height: iconSize,
                              colorFilter: ColorFilter.mode(
                                isDarkMode
                                    ? context.primaryLightColor
                                    : context.primaryColor,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        )
                      else
                        Flexible(
                          flex: 0,
                          child: Container(
                            padding: EdgeInsets.all(paddingSize),
                            decoration: BoxDecoration(
                              color:
                                  context.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: context.primaryColor
                                    .withValues(alpha: 0.12),
                              ),
                            ),
                            child: Icon(
                              icon,
                              size: iconSize,
                              color: isDarkMode
                                  ? context.primaryLightColor
                                  : context.primaryColor,
                            ),
                          ),
                        ),
                      SizedBox(height: 12.h),
                      Flexible(
                        child: AutoSizeText(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          minFontSize: 8,
                          maxFontSize: 24,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.white
                                : Colors.black.withValues(alpha: 0.85),
                            fontFamily: "Amiri",
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
