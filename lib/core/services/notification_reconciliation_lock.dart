import 'dart:async';

import 'package:synchronized/synchronized.dart';

class NotificationReconciliationLock {
  NotificationReconciliationLock._();

  static final Lock _isolateLock = Lock();
  static final Object _nestedOperationKey = Object();
  static Future<T> synchronized<T>(Future<T> Function() operation) {
    if (Zone.current[_nestedOperationKey] == true) return operation();
    return _isolateLock.synchronized(
      () => runZoned<Future<T>>(
        operation,
        zoneValues: {_nestedOperationKey: true},
      ),
    );
  }
}
