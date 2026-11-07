import 'dart:io';

import 'package:flutter/foundation.dart';

/// Which lock Miqaat Lock drives: Android's accessibility service and
/// overlay, iOS's Screen Time, or none (desktop, where the feature isn't
/// offered). A capability, not a layout choice.
enum MiqaatLockPlatform {
  android,
  ios,
  other;

  /// Lets tests render the Android and iOS screens on any host.
  @visibleForTesting
  static MiqaatLockPlatform? debugOverride;

  static MiqaatLockPlatform get current =>
      debugOverride ??
      (Platform.isAndroid
          ? android
          : Platform.isIOS
          ? ios
          : other);
}
