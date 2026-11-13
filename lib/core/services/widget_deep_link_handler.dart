import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:huda/core/services/mac_widget_bridge.dart';
import 'package:huda/core/services/widget_link_queue.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/presentation/screens/app.dart';

class WidgetDeepLinkHandler {
  WidgetDeepLinkHandler._();

  static StreamSubscription<Uri?>? _subscription;
  static bool _coldStartHandled = false;
  static final _pendingLinks = WidgetLinkQueue();
  static Timer? _retry;
  static bool _deliveryScheduled = false;
  static bool _started = false;

  static Future<void> start() async {
    if (!PlatformUtils.isMobile && !PlatformUtils.isMacOS) return;
    if (_started) return;
    _started = true;

    if (PlatformUtils.isMacOS) {
      MacWidgetBridge.onLink((raw) => _handleUri(Uri.tryParse(raw)));
      if (!_coldStartHandled) {
        _coldStartHandled = true;
        final raw = await MacWidgetBridge.initialLink();
        if (raw != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _handleUri(Uri.tryParse(raw)),
          );
        }
      }
      return;
    }

    _subscription = HomeWidget.widgetClicked.listen(_handleUri);

    if (!_coldStartHandled) {
      _coldStartHandled = true;
      try {
        final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
        if (uri != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _handleUri(uri));
        }
      } catch (e) {
        debugPrint('⚠️ initiallyLaunchedFromHomeWidget failed: $e');
      }
    }
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
    _retry?.cancel();
    _retry = null;
    _pendingLinks.clear();
  }

  static void _handleUri(Uri? uri) {
    if (uri == null || !_started) return;
    debugPrint('🔗 Widget deep link: $uri');

    _pendingLinks.accept(uri);
    _scheduleDelivery();
  }

  static void _scheduleDelivery() {
    if (!_started || !_pendingLinks.hasPending || _deliveryScheduled) return;
    _retry?.cancel();
    _deliveryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deliveryScheduled = false;
      if (!_started) return;
      final delivered = _pendingLinks.drain((route) {
        final navigator = App.navigatorKey.currentState;
        if (navigator == null) return false;
        navigator.pushNamedAndRemoveUntil(route, (r) => r.isFirst);
        return true;
      });
      if (!delivered) {
        _retry = Timer(const Duration(milliseconds: 100), _scheduleDelivery);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }
}
