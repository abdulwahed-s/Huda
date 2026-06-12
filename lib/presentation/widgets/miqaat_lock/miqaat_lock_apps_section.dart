import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/miqaat_lock/miqaat_lock.dart';
import 'package:huda/l10n/app_localizations.dart';

import 'miqaat_lock_shared_components.dart';

class LockedAppsSection extends StatelessWidget {
  final List<LockedApp> lockedApps;
  final VoidCallback onAddAppsTap;
  final void Function(String packageId) onRemoveApp;
  final int iosAppsRefreshKey;

  const LockedAppsSection({
    super.key,
    required this.lockedApps,
    required this.onAddAppsTap,
    required this.onRemoveApp,
    required this.iosAppsRefreshKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = context.primaryColor;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: Icons.apps_rounded,
          title: l10n.lockedApps,
          theme: theme,
          primary: primary,
        ),
        SizedBox(height: 6.h),
        SharedCard(
          theme: theme,
          isDark: isDark,
          child: Column(
            children: [
              if (Platform.isIOS)
                _buildIOSLockedAppsInfo(context, theme, l10n)
              else if (lockedApps.isEmpty)
                EmptyStateWidget(
                  icon: Icons.apps_outlined,
                  message: l10n.noAppsSelected,
                  theme: theme,
                  isDark: isDark,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lockedApps.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1.h,
                    indent: 68.w,
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (context, index) {
                    final app = lockedApps[index];
                    return _buildAppTile(app, theme, context);
                  },
                ),
              AddButtonWidget(
                icon: Icons.add_rounded,
                label: l10n.addApps,
                primary: primary,
                onTap: onAddAppsTap,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIOSLockedAppsInfo(
      BuildContext context, ThemeData theme, AppLocalizations l10n) {
    const platform = MethodChannel('com.aw.huda/miqaat_lock');

    return FutureBuilder<dynamic>(
      key: ValueKey('ios_apps_$iosAppsRefreshKey'),
      future: platform.invokeMethod('getSelectedAppsCount'),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final int appCount = data is Map ? (data['appCount'] as int? ?? 0) : 0;
        final int categoryCount =
            data is Map ? (data['categoryCount'] as int? ?? 0) : 0;
        final int total = appCount + categoryCount;

        if (total == 0) {
          return EmptyStateWidget(
            icon: Icons.apps_outlined,
            message: l10n.noAppsSelected,
            theme: theme,
            isDark: theme.brightness == Brightness.dark,
          );
        }

        return Padding(
          padding: EdgeInsets.all(16.r),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.shield_rounded,
                  color: context.primaryColor,
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.iosScreenTimeProtection,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      categoryCount > 0
                          ? l10n.iosAppsAndCategoriesSelected(
                              appCount, categoryCount)
                          : (appCount == 1
                              ? l10n.iosAppSelected(1)
                              : l10n.iosAppsSelected(appCount)),
                      style: TextStyle(
                        color: theme.hintColor,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFF00C9A7),
                size: 24.sp,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppTile(LockedApp app, ThemeData theme, BuildContext context) {
    Widget iconWidget;
    if (app.iconBase64 != null && app.iconBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(app.iconBase64!);
        iconWidget = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Image.memory(
              bytes,
              width: 42.w,
              height: 42.h,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _defaultAppIcon(theme, context),
            ),
          ),
        );
      } catch (e) {
        iconWidget = _defaultAppIcon(theme, context);
      }
    } else {
      iconWidget = _defaultAppIcon(theme, context);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        children: [
          iconWidget,
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              app.appName,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              CupertinoIcons.minus_circle_fill,
              color: Colors.red.withValues(alpha: 0.6),
              size: 22.sp,
            ),
            onPressed: () => onRemoveApp(app.packageId),
          ),
        ],
      ),
    );
  }

  Widget _defaultAppIcon(ThemeData theme, BuildContext context) {
    return Container(
      width: 42.w,
      height: 42.h,
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(
        Icons.android,
        color: context.primaryColor,
        size: 22.sp,
      ),
    );
  }
}
