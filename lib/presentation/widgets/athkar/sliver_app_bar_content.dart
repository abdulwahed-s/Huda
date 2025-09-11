import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class SliverAppBarContent extends StatelessWidget {
  final bool isDark;
  final bool showSearch;
  final AnimationController searchAnimationController;
  final TextEditingController searchController;
  final String searchQuery;
  final VoidCallback toggleSearch;
  final ValueChanged<String> onSearchChanged;

  const SliverAppBarContent({
    super.key,
    required this.isDark,
    required this.showSearch,
    required this.searchAnimationController,
    required this.searchController,
    required this.searchQuery,
    required this.toggleSearch,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120.h,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor:
          isDark ? context.darkGradientStart : context.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: showSearch
            ? null
            : Text(
                AppLocalizations.of(context)!.athkar,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
              ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      context.darkGradientStart,
                      context.darkGradientMid,
                      context.darkGradientEnd,
                    ]
                  : [
                      context.primaryColor,
                      context.primaryVariantColor,
                      context.primaryLightColor,
                    ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative pattern
              Positioned(
                top: 20.h,
                right: -20.w,
                child: Container(
                  width: 100.w,
                  height: 100.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                top: 60.h,
                left: -30.w,
                child: Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (!showSearch)
          IconButton(
            key: const ValueKey('search'),
            icon: Icon(
              Icons.search,
              color: Colors.white,
              size: 24.sp,
            ),
            onPressed: toggleSearch,
          ),
        if (showSearch)
          IconButton(
            key: const ValueKey('close'),
            icon: Icon(
              Icons.close,
              color: Colors.white,
              size: 24.sp,
            ),
            onPressed: toggleSearch,
          ),
      ],
      bottom: showSearch
          ? PreferredSize(
              preferredSize: Size.fromHeight(60.h),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: searchAnimationController,
                  curve: Curves.easeInOut,
                )),
                child: Container(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: Container(
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(22.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontFamily: 'Tajawal',
                      ),
                      decoration: InputDecoration(
                        hintText:
                            AppLocalizations.of(context)!.searchAthkarHint,
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14.sp,
                          fontFamily: 'Tajawal',
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 12.h,
                        ),
                        prefixIcon: Container(
                          padding: EdgeInsets.all(12.w),
                          child: Icon(
                            Icons.search,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 20.sp,
                          ),
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  searchController.clear();
                                  onSearchChanged('');
                                },
                                child: Container(
                                  padding: EdgeInsets.all(12.w),
                                  child: Icon(
                                    Icons.clear,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 18.sp,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      onChanged: onSearchChanged,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
