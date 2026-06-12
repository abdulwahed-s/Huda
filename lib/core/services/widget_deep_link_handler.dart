import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/presentation/screens/app.dart';

class WidgetDeepLinkHandler {
  WidgetDeepLinkHandler._();

  static StreamSubscription<Uri?>? _subscription;
  static bool _coldStartHandled = false;

  static Future<void> start() async {
    if (!PlatformUtils.isMobile) return;
    if (_subscription != null) return;

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
  }

  static void _handleUri(Uri? uri) {
    if (uri == null) return;
    debugPrint('🔗 Widget deep link: $uri');

    final navigator = App.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('⚠️ Navigator not ready yet — dropping deep link $uri');
      return;
    }

    final route = _routeForUri(uri);
    if (route == null) return;

    navigator.pushNamedAndRemoveUntil(
      route,
      (r) => r.isFirst,
    );
  }

  static String? _routeForUri(Uri uri) {
    final target = (uri.host.isNotEmpty ? uri.host : uri.path)
        .replaceAll('/', '')
        .toLowerCase();

    switch (target) {
      case 'prayer_times':
      case 'prayertimes':
        return AppRoute.prayerTimes;
      default:
        return null;
    }
  }
}
