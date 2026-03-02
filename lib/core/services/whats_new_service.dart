import 'package:flutter/material.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/data/models/whats_new_content.dart';
import 'package:huda/presentation/widgets/home/whats_new_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';

class WhatsNewService {
  static const String _lastSeenVersionKey = 'whats_new_last_seen_version';
  static const String _onboardingKey = 'onboarding_completed';

  static Future<void> checkAndShow(BuildContext context) async {
    if (!context.mounted) return;

    final cacheHelper = getIt<CacheHelper>();
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final storedVersion = cacheHelper.getDataString(key: _lastSeenVersionKey);
    final onboardingCompleted =
        cacheHelper.getData(key: _onboardingKey) as bool?;

    if (onboardingCompleted != true) return;

    if (storedVersion != null && !_isNewer(currentVersion, storedVersion)) {
      return;
    }

    final content = WhatsNewContent.getForVersion(currentVersion);
    if (content == null) return;

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => WhatsNewDialog(content: content),
    );

    await cacheHelper.saveData(key: _lastSeenVersionKey, value: currentVersion);
  }

  static bool _isNewer(String current, String stored) {
    final currentParts = current.split('.').map(int.tryParse).toList();
    final storedParts = stored.split('.').map(int.tryParse).toList();

    for (int i = 0; i < currentParts.length; i++) {
      final c = currentParts[i] ?? 0;
      final s = (i < storedParts.length) ? (storedParts[i] ?? 0) : 0;
      if (c > s) return true;
      if (c < s) return false;
    }
    return false;
  }
}
