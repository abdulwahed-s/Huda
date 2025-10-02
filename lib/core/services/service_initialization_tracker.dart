import 'package:flutter/foundation.dart';

class ServiceInitializationTracker extends ChangeNotifier {
  static final ServiceInitializationTracker _instance =
      ServiceInitializationTracker._internal();

  factory ServiceInitializationTracker() {
    return _instance;
  }

  ServiceInitializationTracker._internal();

  final Map<String, bool> _serviceStatus = {
    'cache': false,
    'notifications': false,
    'widgets': false,
    'prayer': false,
    'background': false,
  };

  bool get allCriticalServicesReady =>
      _serviceStatus['cache']! && _serviceStatus['notifications']!;

  bool get allServicesReady => _serviceStatus.values.every((status) => status);

  double get progress {
    final completedServices =
        _serviceStatus.values.where((status) => status).length;
    return completedServices / _serviceStatus.length;
  }

  void markServiceReady(String serviceName) {
    if (_serviceStatus.containsKey(serviceName)) {
      _serviceStatus[serviceName] = true;
      notifyListeners();
    }
  }

  void reset() {
    _serviceStatus.updateAll((key, value) => false);
    notifyListeners();
  }

  List<String> get readyServices => _serviceStatus.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();

  List<String> get pendingServices => _serviceStatus.entries
      .where((entry) => !entry.value)
      .map((entry) => entry.key)
      .toList();
}
