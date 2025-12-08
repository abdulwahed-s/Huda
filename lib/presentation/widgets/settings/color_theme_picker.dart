import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/core/utils/responsive_utils.dart';
import 'package:huda/l10n/app_localizations.dart';

class ColorThemePicker extends StatefulWidget {
  final AppColorTheme selectedTheme;
  final Function(AppColorTheme) onThemeSelected;

  const ColorThemePicker({
    super.key,
    required this.selectedTheme,
    required this.onThemeSelected,
  });

  @override
  State<ColorThemePicker> createState() => _ColorThemePickerState();
}

class _ColorThemePickerState extends State<ColorThemePicker>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  AppColorTheme? _hoveredTheme;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = ResponsiveUtils.isTablet(context) ||
            kIsWeb ||
            PlatformUtils.isDesktop;

        final crossAxisCount = isTablet ? 6 : 4;
        final gridSpacing = isTablet ? 16.0 : 12.w;
        final maxWidth = isTablet ? 800.0 : double.infinity;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isTablet ? 14 : 12.w),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(isTablet ? 14 : 12.r),
                      ),
                      child: Icon(
                        Icons.palette_outlined,
                        size: isTablet ? 28 : 24.sp,
                        color: context.primaryColor,
                      ),
                    ),
                    SizedBox(width: isTablet ? 20 : 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.chooseThemeColor,
                            style: TextStyle(
                              fontSize: isTablet ? 22 : 18.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: "Amiri",
                              color:
                                  isDark ? context.darkText : context.lightText,
                            ),
                          ),
                          SizedBox(height: isTablet ? 6 : 4.h),
                          Text(
                            AppLocalizations.of(context)!.themeDescription,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14.sp,
                              fontFamily: "Amiri",
                              color: isDark
                                  ? context.darkText.withValues(alpha: 0.7)
                                  : context.lightText.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 32 : 24.h),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: gridSpacing,
                    mainAxisSpacing: gridSpacing,
                    childAspectRatio: 1,
                  ),
                  itemCount: AppColors.availableThemes.length,
                  itemBuilder: (context, index) {
                    final theme = AppColors.availableThemes[index];
                    return _buildThemeOption(theme, isDark, isTablet);
                  },
                ),
                SizedBox(height: isTablet ? 24 : 16.h),
                Container(
                  padding: EdgeInsets.all(isTablet ? 20 : 16.w),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(isTablet ? 14 : 12.r),
                    border: Border.all(
                      color: context.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: isTablet ? 22 : 18.sp,
                        color: context.primaryColor.withValues(alpha: 0.8),
                      ),
                      SizedBox(width: isTablet ? 16 : 12.w),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.themeInfo,
                          style: TextStyle(
                            fontSize: isTablet ? 15 : 12.sp,
                            fontFamily: "Amiri",
                            color: isDark
                                ? context.darkText.withValues(alpha: 0.7)
                                : context.lightText.withValues(alpha: 0.7),
                            height: 1.4,
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
      },
    );
  }

  Widget _buildThemeOption(AppColorTheme theme, bool isDark, bool isTablet) {
    final colorScheme = AppColors.getColorScheme(theme);
    final isSelected = theme == widget.selectedTheme;
    final isHovered = theme == _hoveredTheme;

    final borderRadius = isTablet ? 18.0 : 16.r;
    final innerBorderRadius = isTablet ? 16.0 : 14.r;
    final borderWidth =
        isSelected ? (isTablet ? 3.5 : 3.0) : (isTablet ? 2.5 : 2.0);
    final checkSize = isTablet ? 32.0 : 24.w;
    final checkIconSize = isTablet ? 20.0 : 16.sp;
    final badgeFontSize = isTablet ? 10.0 : 8.sp;
    final badgePadding = isTablet ? 6.0 : 4.w;
    final badgeVerticalPadding = isTablet ? 3.0 : 2.h;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hoveredTheme = theme);
        if (!isSelected) _animationController.forward();
      },
      onExit: (_) {
        setState(() => _hoveredTheme = null);
        if (!isSelected) _animationController.reverse();
      },
      child: GestureDetector(
        onTap: () {
          widget.onThemeSelected(theme);
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: (isHovered && !isSelected) ? _scaleAnimation.value : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : isHovered
                            ? colorScheme.primary.withValues(alpha: 0.4)
                            : colorScheme.primary.withValues(alpha: 0.1),
                    width: borderWidth,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: isTablet ? 12 : 8.r,
                        offset: Offset(0, isTablet ? 3 : 2.h),
                      ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(innerBorderRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        colorScheme.primaryVariant,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (isSelected)
                        Center(
                          child: Container(
                            width: checkSize,
                            height: checkSize,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(checkSize / 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: isTablet ? 6 : 4.r,
                                  offset: Offset(0, isTablet ? 3 : 2.h),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: colorScheme.primary,
                              size: checkIconSize,
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: isTablet ? 6 : 4.h,
                        left: isTablet ? 6 : 4.w,
                        right: isTablet ? 6 : 4.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: badgePadding,
                            vertical: badgeVerticalPadding,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius:
                                BorderRadius.circular(isTablet ? 8 : 6.r),
                          ),
                          child: Text(
                            AppColors.getThemeName(theme, context),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: badgeFontSize,
                              fontWeight: FontWeight.w600,
                              fontFamily: "Amiri",
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (isHovered && !isSelected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(innerBorderRadius),
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
