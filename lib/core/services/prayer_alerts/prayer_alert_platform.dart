import 'package:flutter/foundation.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_settings.dart';

/// One platform's prayer alert settings, behind the shared sheet. [T] is the
/// platform's own model, which stays the source of truth; this only reads it
/// for the sheet, applies edits to it and saves it the way it always was.
abstract class PrayerAlertPlatform<T> {
  /// The settings the platform has acknowledged.
  ValueListenable<T?> get applied;

  /// Reads the latest acknowledged settings.
  Future<void> refresh();

  PrayerAlertCapabilities capabilities(T settings);
  PrayerAlertSettings view(T settings);
  T change(T settings, PrayerAlertChange change);

  /// Saves [next] and returns what the platform acknowledged. Throws
  /// [PrayerAlertApplyException].
  Future<T> apply(T previous, T next);

  /// An l10n key when the acknowledged settings differ from what was asked
  /// (for example, macOS didn't allow starting at login).
  String? warning(T requested, T acknowledged) => null;

  /// How long edits wait to be saved together.
  Duration get debounce => const Duration(milliseconds: 300);

  /// Sends a real alert for [prayer] about 10 seconds from now, with the
  /// saved settings, so the user can leave Huda and still get it. [title]
  /// and [body] are the prayer's usual text where the platform needs them.
  Future<PrayerTestOutcome> sendTest(
    String prayer,
    T settings, {
    required String title,
    required String body,
  });

  /// Stops a test that is playing or still waiting.
  Future<void> stopTest();
}
