import 'package:flutter/services.dart';

/// macOS counterpart to home_widget's App Group writer (the plugin has no macOS target).
class MacWidgetBridge {
  MacWidgetBridge._();

  static const _channel = MethodChannel('com.aw.huda/mac_widgets');

  static Future<void> publish(
    Map<String, Object?> values, {
    required List<String> kinds,
  }) async {
    await _channel.invokeMethod<void>('publish', {
      'values': values,
      'kinds': kinds,
    });
  }

  static Future<String?> initialLink() =>
      _channel.invokeMethod<String>('initialLink');

  static void onLink(void Function(String) callback) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'widgetClicked' && call.arguments is String) {
        callback(call.arguments as String);
      }
    });
  }
}
