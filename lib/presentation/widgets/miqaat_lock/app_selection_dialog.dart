import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/miqaat_lock/miqaat_lock_cubit.dart';
import 'package:huda/cubit/miqaat_lock/miqaat_lock_state.dart';
import 'package:huda/data/models/miqaat_lock/locked_app.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class AppSelectionDialog extends StatefulWidget {
  final List<String> selectedApps;

  const AppSelectionDialog({
    super.key,
    required this.selectedApps,
  });

  @override
  State<AppSelectionDialog> createState() => _AppSelectionDialogState();
}

class _AppSelectionDialogState extends State<AppSelectionDialog> {
  String _searchQuery = '';
  Set<String> _selectedPackages = {};

  @override
  void initState() {
    super.initState();
    _selectedPackages = Set.from(widget.selectedApps);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 5.h,
            margin: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: theme.hintColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.5.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                Text(
                  l10n.selectApps,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
                TextButton(
                  onPressed: _saveSelection,
                  child: Text(l10n.done),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: l10n.searchApps,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<MiqaatLockCubit, MiqaatLockState>(
              builder: (context, state) {
                if (state is! MiqaatLockLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.isLoadingApps) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        SizedBox(height: 16.h),
                        Text(l10n.loadingApps),
                      ],
                    ),
                  );
                }

                if (state.installedApps.isEmpty) {
                  if (Platform.isIOS) {
                    return _buildIOSMessage(theme, l10n);
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.apps,
                          size: 64.sp,
                          color: theme.hintColor,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          l10n.noAppsFound,
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextButton(
                          onPressed: () => context
                              .read<MiqaatLockCubit>()
                              .loadInstalledApps(),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  );
                }

                final filteredApps = state.installedApps
                    .where((app) =>
                        app.appName
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        app.packageId
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                    .toList();

                return ListView.builder(
                  itemCount: filteredApps.length,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemBuilder: (context, index) {
                    final app = filteredApps[index];
                    final isSelected =
                        _selectedPackages.contains(app.packageId);

                    return _buildAppTile(app, isSelected, theme);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSMessage(ThemeData theme, AppLocalizations l10n) {
    const platform = MethodChannel('com.aw.huda/miqaat_lock');

    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apps_rounded,
            size: 64.sp,
            color: theme.primaryColor,
          ),
          SizedBox(height: 24.h),
          Text(
            l10n.iosAppSelectionTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            l10n.iosTapToSelectApps,
            style: TextStyle(
              color: theme.hintColor,
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final hasApps =
                    await platform.invokeMethod('showFamilyActivityPicker');
                if (hasApps == true && mounted) {
                  HudaSnackBar.success(
                    context,
                    message: l10n.iosAppsSelectedSuccessfully,
                  );
                  Navigator.pop(context);
                }
              } on PlatformException catch (e) {
                if (mounted) {
                  HudaSnackBar.error(
                    context,
                    message: l10n.iosAppSelectionError(e.message ?? ''),
                  );
                }
              }
            },
            icon: const Icon(Icons.add_circle_outline),
            label: Text(l10n.selectApps),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          TextButton(
            onPressed: () async {
              const url = 'app-settings:';
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
  }

  Widget _buildAppTile(LockedApp app, bool isSelected, ThemeData theme) {
    Widget iconWidget;
    if (app.iconBase64 != null && app.iconBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(app.iconBase64!);
        iconWidget = ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: Image.memory(
            bytes,
            width: 48.w,
            height: 48.h,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _defaultIcon(theme),
          ),
        );
      } catch (e) {
        iconWidget = _defaultIcon(theme);
      }
    } else {
      iconWidget = _defaultIcon(theme);
    }

    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 4.h),
      leading: iconWidget,
      title: Text(
        app.appName,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14.sp,
        ),
      ),
      subtitle: Text(
        app.packageId,
        style: TextStyle(
          fontSize: 11.sp,
          color: theme.hintColor,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedPackages.add(app.packageId);
            } else {
              _selectedPackages.remove(app.packageId);
            }
          });
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.r),
        ),
      ),
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedPackages.remove(app.packageId);
          } else {
            _selectedPackages.add(app.packageId);
          }
        });
      },
    );
  }

  Widget _defaultIcon(ThemeData theme) {
    return Container(
      width: 48.w,
      height: 48.h,
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(
        Icons.android,
        color: theme.primaryColor,
        size: 28.sp,
      ),
    );
  }

  void _saveSelection() {
    final cubit = context.read<MiqaatLockCubit>();
    final state = cubit.state;

    if (state is MiqaatLockLoaded) {
      final newLockedApps = <LockedApp>[];

      for (final app in state.settings.lockedApps) {
        if (_selectedPackages.contains(app.packageId)) {
          newLockedApps.add(app);
        }
      }

      final existingPackages = newLockedApps.map((a) => a.packageId).toSet();
      for (final packageId in _selectedPackages) {
        if (!existingPackages.contains(packageId)) {
          final app = state.installedApps.firstWhere(
            (a) => a.packageId == packageId,
            orElse: () => LockedApp(packageId: packageId, appName: packageId),
          );
          newLockedApps.add(app);
        }
      }

      cubit.setLockedApps(newLockedApps);
    }

    Navigator.pop(context);
  }
}
