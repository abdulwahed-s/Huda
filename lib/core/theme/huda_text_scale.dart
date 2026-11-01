import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The app's text scale: the device's text size × the in-app adjustment.
/// See `design/RESPONSIVE.md`, "Text scale".
///
/// The in-app factor applies to the font size first, then the device's
/// own scaler, so Android 14's non-linear curve is kept. UI text stops at
/// [maxScale] (2×); reading content that scrolls may opt out with
/// [uncapped].
@immutable
class CombinedTextScaler extends TextScaler {
  const CombinedTextScaler({
    required this.device,
    required this.factor,
    this.maxScale = interfaceMaxScale,
  });

  /// UI text never scales past this.
  static const double interfaceMaxScale = 2.0;

  /// The OS scaler (`MediaQuery.textScalerOf` above the app's override).
  final TextScaler device;

  /// The in-app "smaller / larger than my device" setting, 1.0 by default.
  final double factor;

  /// Null for no cap.
  final double? maxScale;

  /// The same scale without the 2× cap, for scrolling reading content
  /// (ayat, hadith, dhikr). `MediaQuery(textScaler: ...uncapped)`.
  CombinedTextScaler get uncapped =>
      CombinedTextScaler(device: device, factor: factor, maxScale: null);

  @override
  double scale(double fontSize) {
    final scaled = device.scale(fontSize * factor);
    final cap = maxScale;
    return cap == null ? scaled : math.min(scaled, fontSize * cap);
  }

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is CombinedTextScaler &&
      other.device == device &&
      other.factor == factor &&
      other.maxScale == maxScale;

  @override
  int get hashCode => Object.hash(device, factor, maxScale);

  @override
  String toString() =>
      'CombinedTextScaler($device × $factor${maxScale == null ? '' : ', ≤ $maxScale×'})';
}

/// The one-time migration of the saved in-app text size: before, the app
/// *replaced* the device's text size with it; now it multiplies. Dividing
/// by the device's current scale keeps everyone's text the size they
/// chose. Clamped to the slider's range.
double migrateTextScaleToRelative(
  double saved, {
  required double deviceScale,
  double min = 0.5,
  double max = 2.0,
}) {
  if (!saved.isFinite || !deviceScale.isFinite || deviceScale <= 0) {
    return 1.0;
  }
  return (saved / deviceScale).clamp(min, max);
}
