import 'package:flutter/material.dart';
import 'package:huda/core/services/widget_service.dart';
import 'package:huda/core/services/widget_background_service.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/widget_management/custom_verses_section.dart';
import 'package:huda/presentation/widgets/widget_management/force_update_section.dart';
import 'package:huda/presentation/widgets/widget_management/header_section.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WidgetManagementScreen extends StatefulWidget {
  const WidgetManagementScreen({super.key});

  @override
  State<WidgetManagementScreen> createState() => _WidgetManagementScreenState();
}

class _WidgetManagementScreenState extends State<WidgetManagementScreen> {
  bool _isUpdating = false;
  String? _lastUpdateMessage;
  List<String> _customVerses = [];
  bool _isLoadingVerses = false;

  @override
  void initState() {
    super.initState();
    _loadCustomVerses();
    _initializeBackgroundUpdates();
  }

  Future<void> _loadCustomVerses() async {
    setState(() {
      _isLoadingVerses = true;
    });

    try {
      final verses = await WidgetService.getCustomVerses();
      setState(() {
        _customVerses = verses;
      });
    } catch (e) {
      debugPrint('Error loading custom verses: $e');
    } finally {
      setState(() {
        _isLoadingVerses = false;
      });
    }
  }

  Future<void> _initializeBackgroundUpdates() async {
    try {
      await WidgetBackgroundService.initialize();
      await _scheduleAggressiveWidgetUpdates();
    } catch (e) {
      debugPrint('Error initializing background updates: $e');
    }
  }

  Future<void> _scheduleAggressiveWidgetUpdates() async {
    try {
      await Workmanager().cancelAll();

      await Workmanager().registerPeriodicTask(
        "frequentWidgetUpdate",
        "updateHomeWidget",
        frequency: const Duration(minutes: 30),
        initialDelay: const Duration(minutes: 5),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      await Workmanager().registerPeriodicTask(
        "backupWidgetUpdate",
        "updateHomeWidget",
        frequency: const Duration(hours: 1),
        initialDelay: const Duration(minutes: 35),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      await Workmanager().registerOneOffTask(
        "immediateWidgetUpdate",
        "updateHomeWidget",
        initialDelay: const Duration(minutes: 1),
      );

      debugPrint('✅ All background widget update tasks scheduled');
    } catch (e) {
      debugPrint('❌ Error scheduling background updates: $e');
    }
  }

  Future<void> _forceUpdateWidget() async {
    setState(() {
      _isUpdating = true;
      _lastUpdateMessage = null;
    });

    try {
      await WidgetService.forceUpdateWidget();
      await WidgetBackgroundService.forceUpdateNow();
      await _scheduleAggressiveWidgetUpdates();

      setState(() {
        _lastUpdateMessage =
            AppLocalizations.of(context)!.homeScreenWidgetUpdatedSuccessfully;
      });
    } catch (e) {
      setState(() {
        _lastUpdateMessage =
            AppLocalizations.of(context)!.errorUpdatingWidget(e.toString());
      });
    } finally {
      setState(() {
        _isUpdating = false;
      });

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _lastUpdateMessage = null;
          });
        }
      });
    }
  }

  Future<void> _removeCustomVerse(String verse, int index) async {
    try {
      final success = await WidgetService.removeCustomVerse(verse);
      if (success) {
        setState(() {
          _customVerses.removeAt(index);
        });

        await WidgetService.forceUpdateWidget();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.verseRemovedFromWidget,
                style: const TextStyle(fontFamily: 'Amiri'),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${AppLocalizations.of(context)!.errorRemovingVerse}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _clearAllCustomVerses() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.clearAllCustomVerses),
        content: Text(
            AppLocalizations.of(context)!.clearAllCustomVersesConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.clearAll),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await WidgetService.clearCustomVerses();
        setState(() {
          _customVerses.clear();
        });

        await WidgetService.forceUpdateWidget();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.allCustomVersesCleared),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${AppLocalizations.of(context)!.errorClearingVerses}: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.homeScreenWidgetManagement,
          style:
              const TextStyle(fontWeight: FontWeight.w600, fontFamily: "Amiri"),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeaderSection(isDark: isDark),
            SizedBox(height: 20.h),
            ForceUpdateSection(
              isUpdating: _isUpdating,
              lastUpdateMessage: _lastUpdateMessage,
              onForceUpdate: _forceUpdateWidget,
              isDark: isDark,
            ),
            SizedBox(height: 20.h),
            CustomVersesSection(
              customVerses: _customVerses,
              isLoadingVerses: _isLoadingVerses,
              onRefresh: _loadCustomVerses,
              onRemoveVerse: _removeCustomVerse,
              onClearAll: _clearAllCustomVerses,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}