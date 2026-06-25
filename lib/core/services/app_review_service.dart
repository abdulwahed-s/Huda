import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/services/app_store_target.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppReviewService {
  static const int _minDays = 3;
  static const int _minLaunches = 7;
  static const int _remindDays = 5;
  static const int _remindLaunches = 10;

  static const String _minDateKey = 'app_review_min_date';
  static const String _launchesKey = 'app_review_launches';
  static const String _dontAskKey = 'app_review_dont_ask';

  static Future<bool> recordLaunchAndEvaluate() async {
    final cache = getIt<CacheHelper>();

    int? minDateMs = cache.getData(key: _minDateKey) as int?;
    if (minDateMs == null) {
      minDateMs = DateTime.now()
          .add(const Duration(days: _minDays))
          .millisecondsSinceEpoch;
      await cache.saveData(key: _minDateKey, value: minDateMs);
    }

    final launches = (cache.getData(key: _launchesKey) as int? ?? 0) + 1;
    await cache.saveData(key: _launchesKey, value: launches);

    final dontAsk = cache.getData(key: _dontAskKey) as bool? ?? false;

    final minDate = DateTime.fromMillisecondsSinceEpoch(minDateMs);
    final daysPassed = DateTime.now().isAfter(minDate);
    final enoughLaunches = launches >= _minLaunches;
    final shouldShow = daysPassed && enoughLaunches && !dontAsk;

    return shouldShow;
  }

  static Future<void> recordRemindLater() async {
    final cache = getIt<CacheHelper>();
    final newMinDate = DateTime.now().add(const Duration(days: _remindDays));
    await cache.saveData(
      key: _minDateKey,
      value: newMinDate.millisecondsSinceEpoch,
    );
    final launches = cache.getData(key: _launchesKey) as int? ?? 0;
    final newLaunches = launches - _remindLaunches;
    await cache.saveData(key: _launchesKey, value: newLaunches);
  }

  static Future<void> recordDoNotAskAgain() async {
    await getIt<CacheHelper>().saveData(key: _dontAskKey, value: true);
  }

  static Future<void> reset() async {
    final cache = getIt<CacheHelper>();
    await cache.removeData(key: _minDateKey);
    await cache.removeData(key: _launchesKey);
    await cache.removeData(key: _dontAskKey);
  }

  static Future<void> launchReviewPage() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final info = AppStoreInfo.resolve(packageInfo.installerStore);

    for (final url in [info.reviewUrl, info.storeUrl]) {
      if (url == null) continue;
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        //
      }
    }
  }
}
