import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The system bars for redesigned screens: transparent status and
/// navigation bars with no divider or contrast scrim, drawn edge to edge,
/// with icon brightness following the surface under each bar. See
/// `design/RESPONSIVE.md`, "The bottom edge and system bars".
///
/// Foundation's chrome applies it (`AnnotatedRegion`, app bar themes);
/// features don't call `SystemChrome` themselves.
abstract final class HudaSystemUi {
  /// Transparent bars, no scrim. Never `SystemUiOverlayStyle.light` or
  /// `.dark` as they are: both carry a black navigation bar.
  static const base = SystemUiOverlayStyle(
    statusBarColor: Color(0x00000000),
    systemNavigationBarColor: Color(0x00000000),
    systemNavigationBarDividerColor: Color(0x00000000),
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
  );

  /// Icons that read on a [top] surface (status bar) and a [bottom] surface
  /// (navigation bar): dark icons on light surfaces, light on dark.
  static SystemUiOverlayStyle over({
    required Brightness top,
    required Brightness bottom,
  }) => base.copyWith(
    statusBarIconBrightness: _icons(top),
    // iOS: the brightness of what's behind the status bar.
    statusBarBrightness: top,
    systemNavigationBarIconBrightness: _icons(bottom),
  );

  /// Over surfaces of these colors.
  static SystemUiOverlayStyle overColors({
    required Color top,
    required Color bottom,
  }) => over(
    top: ThemeData.estimateBrightnessForColor(top),
    bottom: ThemeData.estimateBrightnessForColor(bottom),
  );

  static Brightness _icons(Brightness surface) =>
      surface == Brightness.light ? Brightness.dark : Brightness.light;

  /// At startup: draw behind the system bars. Android 15+ (target SDK 36)
  /// already does; this makes Android 14 and older and the restore after
  /// immersive readers match.
  static Future<void> enableEdgeToEdge() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}
