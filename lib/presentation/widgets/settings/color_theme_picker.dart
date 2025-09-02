import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/theme/theme_extension.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section with improved design
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.palette_outlined,
                size: 24.sp,
                color: context.primaryColor,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.chooseThemeColor,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: "Amiri",
                      color: isDark ? context.darkText : context.lightText,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    AppLocalizations.of(context)!.themeDescription,
                    style: TextStyle(
                      fontSize: 14.sp,
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
        SizedBox(height: 24.h),
        // Theme selection grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 1,
          ),
          itemCount: AppColors.availableThemes.length,
          itemBuilder: (context, index) {
            final theme = AppColors.availableThemes[index];
            return _buildThemeOption(theme, isDark);
          },
        ),
        SizedBox(height: 16.h),

        // Info section with better design
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: context.primaryColor.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18.sp,
                color: context.primaryColor.withValues(alpha: 0.8),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.themeInfo,
                  style: TextStyle(
                    fontSize: 12.sp,
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
    );
  }

  Widget _buildThemeOption(AppColorTheme theme, bool isDark) {
    final colorScheme = AppColors.getColorScheme(theme);
    final isSelected = theme == widget.selectedTheme;
    final isHovered = theme == _hoveredTheme;

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
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : isHovered
                            ? colorScheme.primary.withValues(alpha: 0.4)
                            : colorScheme.primary.withValues(alpha: 0.1),
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
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
                      // Selection indicator
                      if (isSelected)
                        Center(
                          child: Container(
                            width: 24.w,
                            height: 24.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: colorScheme.primary,
                              size: 16.sp,
                            ),
                          ),
                        ),

                      // Theme name badge
                      Positioned(
                        bottom: 4.h,
                        left: 4.w,
                        right: 4.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            AppColors.getThemeName(theme, context),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: "Amiri",
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // Hover overlay
                      if (isHovered && !isSelected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14.r),
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
