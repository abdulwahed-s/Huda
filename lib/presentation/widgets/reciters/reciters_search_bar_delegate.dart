import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:huda/l10n/app_localizations.dart';

class RecitersSearchBarDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String query;
  final bool isDark;
  final ThemeData theme;
  final AppLocalizations l10n;
  final bool isOffline;

  RecitersSearchBarDelegate({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.query,
    required this.isDark,
    required this.theme,
    required this.l10n,
    required this.isOffline,
  });

  double get _offlineBannerHeight => isOffline ? 34.h : 0;

  @override
  double get maxExtent => 64.h + _offlineBannerHeight;

  @override
  double get minExtent => 64.h + _offlineBannerHeight;

  @override
  bool shouldRebuild(covariant RecitersSearchBarDelegate old) =>
      old.query != query || old.isDark != isDark || old.isOffline != isOffline;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: Material(
        color: theme.scaffoldBackgroundColor,
        elevation: overlapsContent ? 2 : 0,
        shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOffline)
              Container(
                width: double.infinity,
                height: _offlineBannerHeight,
                color: Colors.orange.shade700,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        size: 14.sp, color: Colors.white),
                    SizedBox(width: 6.w),
                    Text(
                      l10n.offlineMode,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 64.h,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: l10n.searchReciters,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                    prefixIcon: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Icon(Icons.search_rounded,
                          color: theme.colorScheme.primary),
                    ),
                    prefixIconConstraints:
                        BoxConstraints(minWidth: 40.w, minHeight: 40.w),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: onClear,
                          )
                        : null,
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
