import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_platform.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alert_settings.dart';
import 'package:synchronized/synchronized.dart';

enum PrayerAlertSaveState {
  idle,

  /// Saving changes made in the sheet.
  updating,
  saved,

  /// The last save didn't work; the sheet still shows the edits.
  failed,

  /// Saving again because the user tapped Retry.
  retrying,
}

/// Saves the sheet's edits as they are made. Edits made close together are
/// saved together, one save at a time, the latest edit winning. A failed
/// save is never retried by itself: the user can retry or undo.
class PrayerAlertController<T> extends ChangeNotifier {
  PrayerAlertController(this.platform, {this.onApplied}) {
    platform.applied.addListener(_onApplied);
  }

  final PrayerAlertPlatform<T> platform;

  /// Runs after each successful save (Prayer Times refreshes its schedule).
  Future<void> Function()? onApplied;

  final _lock = Lock();
  T? _draft;
  int _revision = 0;
  int _savedRevision = 0;
  Timer? _debounce;
  bool _disposed = false;

  PrayerAlertSaveState saveState = PrayerAlertSaveState.idle;
  PrayerAlertSaveFailure? failure;

  /// An l10n key: saved, but not exactly as asked.
  String? warning;

  T? get current => _draft ?? platform.applied.value;
  bool get hasUnsavedEdits => _draft != null;

  PrayerAlertSettings? get settings {
    final value = current;
    return value == null ? null : platform.view(value);
  }

  PrayerAlertCapabilities? get capabilities {
    final value = current;
    return value == null ? null : platform.capabilities(value);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _onApplied() {
    if (_draft == null) _notify();
  }

  Future<void> refresh() async {
    try {
      await platform.refresh();
    } catch (error) {
      debugPrint('Prayer alert settings unavailable: $error');
    }
    _notify();
  }

  /// Shows [change] at once and saves it shortly after.
  void edit(PrayerAlertChange change) {
    final base = current;
    if (base == null) return;
    final T next;
    try {
      next = platform.change(base, change);
    } catch (error) {
      debugPrint('Prayer alert edit rejected: $error');
      return;
    }
    _draft = next;
    _revision++;
    if (saveState != PrayerAlertSaveState.failed) {
      saveState = PrayerAlertSaveState.updating;
    }
    _notify();
    _debounce?.cancel();
    _debounce = Timer(platform.debounce, () => unawaited(_save()));
  }

  /// Saves pending edits now (when the sheet closes).
  Future<void> flush() async {
    if (_draft == null) return;
    _debounce?.cancel();
    await _save();
  }

  Future<void> retry() async {
    if (_draft == null) return;
    _debounce?.cancel();
    await _save(retrying: true);
  }

  /// Drops edits that couldn't be saved.
  void undo() {
    _debounce?.cancel();
    _draft = null;
    _savedRevision = _revision;
    saveState = PrayerAlertSaveState.idle;
    failure = null;
    _notify();
  }

  Future<void> _save({bool retrying = false}) => _lock.synchronized(() async {
    while (_draft != null && _savedRevision != _revision) {
      final requested = _draft as T;
      final revision = _revision;
      final previous = platform.applied.value ?? requested;
      saveState = retrying
          ? PrayerAlertSaveState.retrying
          : PrayerAlertSaveState.updating;
      failure = null;
      _notify();
      try {
        final acknowledged = await platform.apply(previous, requested);
        _savedRevision = revision;
        warning = platform.warning(requested, acknowledged);
        if (_revision == revision) {
          _draft = null;
          saveState = PrayerAlertSaveState.saved;
        }
        await onApplied?.call();
      } catch (error) {
        debugPrint('Prayer alert settings not saved: $error');
        failure = error is PrayerAlertApplyException
            ? error.failure
            : PrayerAlertSaveFailure.unknown;
        saveState = PrayerAlertSaveState.failed;
        _notify();
        return;
      }
      _notify();
    }
  });

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    platform.applied.removeListener(_onApplied);
    super.dispose();
  }
}
