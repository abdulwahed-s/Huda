import 'package:huda/core/routes/app_route.dart';

/// Retains the latest widget destination until an app navigator can accept it.
class WidgetLinkQueue {
  String? _pendingRoute;

  bool get hasPending => _pendingRoute != null;

  void accept(Uri? uri) {
    if (uri == null || uri.scheme.toLowerCase() != 'huda') return;
    final target = (uri.host.isNotEmpty ? uri.host : uri.path)
        .replaceAll('/', '')
        .toLowerCase();
    final route = switch (target) {
      'quran' || 'homequran' => AppRoute.homeQuran,
      'prayer_times' || 'prayertimes' => AppRoute.prayerTimes,
      _ => null,
    };
    if (route != null) _pendingRoute = route;
  }

  bool drain(bool Function(String route) navigate) {
    final route = _pendingRoute;
    if (route == null) return true;
    if (!navigate(route)) return false;
    _pendingRoute = null;
    return true;
  }

  void clear() => _pendingRoute = null;
}
