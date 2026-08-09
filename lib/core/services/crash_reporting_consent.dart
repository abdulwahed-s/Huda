import 'package:huda/core/utils/distribution_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class CrashReportingConsent {
  static const _preferenceKey = 'foss_crash_reporting_enabled';

  static bool get requiresExplicitConsent => DistributionChannel.isFoss;

  static Future<bool?> getDecision() async {
    if (!requiresExplicitConsent) return true;
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_preferenceKey);
  }

  static Future<bool> canReport() async {
    if (!requiresExplicitConsent) return true;
    return await getDecision() == true;
  }

  static Future<void> setEnabled(bool enabled) async {
    if (!requiresExplicitConsent) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_preferenceKey, enabled);
  }
}
