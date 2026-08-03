import 'package:flutter/material.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/utils/version_utils.dart';
import 'package:huda/data/models/whats_new_content.dart';
import 'package:huda/presentation/widgets/home/whats_new_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';

class WhatsNewService {
  static const String _lastSeenVersionKey = 'whats_new_last_seen_version';
  static const String _onboardingKey = 'onboarding_completed';
  static Future<void>? _activeCheckAndShow;

  static Future<void> checkAndShow(BuildContext context) {
    final activeCheckAndShow = _activeCheckAndShow;
    if (activeCheckAndShow != null) return activeCheckAndShow;

    final request = _checkAndShow(context);
    _activeCheckAndShow = request;
    return request.whenComplete(() {
      if (identical(_activeCheckAndShow, request)) {
        _activeCheckAndShow = null;
      }
    });
  }

  static Future<void> _checkAndShow(BuildContext context) async {
    if (!context.mounted) return;

    final cacheHelper = getIt<CacheHelper>();
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final storedVersion = cacheHelper.getDataString(key: _lastSeenVersionKey);
    final onboardingCompleted =
        cacheHelper.getData(key: _onboardingKey) as bool?;

    if (onboardingCompleted != true) return;

    final content = WhatsNewContent.getLatestForVersion(currentVersion);
    if (content == null) return;

    if (storedVersion != null &&
        !VersionUtils.isNewer(content.version, storedVersion)) {
      return;
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => WhatsNewDialog(content: content),
    );

    await cacheHelper.saveData(
        key: _lastSeenVersionKey, value: content.version);
  }
}
