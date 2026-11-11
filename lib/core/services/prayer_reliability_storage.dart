import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:huda/core/services/prayer_reconciliation_state.dart';
import 'package:huda/core/services/linux_prayer_storage_lock.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

enum PrayerStorageReadStatus { absent, valid, recoveredBackup, corrupt }

class PrayerStorageRead {
  const PrayerStorageRead(this.status, this.state);

  final PrayerStorageReadStatus status;
  final PrayerReliabilityState? state;
}

abstract interface class PrayerReliabilityStorage {
  Future<T> runExclusive<T>(Future<T> Function() action);

  Future<PrayerStorageRead> read();

  Future<void> write(PrayerReliabilityState state);
}

class AtomicPrayerReliabilityStorage implements PrayerReliabilityStorage {
  AtomicPrayerReliabilityStorage._(
    this.directory, {
    required Duration lockTimeout,
    required Duration staleLockAge,
  }) : _lockTimeout = lockTimeout,
       _staleLockAge = staleLockAge;

  static const String fileName = 'prayer_reliability_state_v1.json';
  static const int storageSchemaVersion = 1;
  static const Duration defaultLockTimeout = Duration(seconds: 20);
  static const Duration defaultStaleLockAge = Duration(minutes: 10);
  static final Map<String, Lock> _processLocks = <String, Lock>{};
  static final Random _secureRandom = Random.secure();
  // Windows enforces byte-range locks on reads through other handles too.
  // Keep the ownership byte beyond the JSON metadata so a second handle can
  // still verify that the path refers to this owner's record.
  static final int _ownershipLockStart = Platform.isWindows ? 1 << 32 : 0;
  static final int _ownershipLockEnd = Platform.isWindows
      ? _ownershipLockStart + 1
      : -1;

  final Directory directory;
  final Duration _lockTimeout;
  final Duration _staleLockAge;

  // The Android foreground scheduler also runs on Flutter's UI isolate.
  // Keep typed validation and time-zone parsing with serialization in the
  // worker; moving only JSON encoding leaves large state walks on the UI.
  static bool get _useValidationWorker =>
      (Platform.isWindows || Platform.isAndroid) &&
      RootIsolateToken.instance != null;

  String get _primaryPath => p.join(directory.path, fileName);
  String get _backupPath => '$_primaryPath.backup';
  String get _lockPath => '$_primaryPath.lock';

  static Future<AtomicPrayerReliabilityStorage> create({
    Directory? directory,
    Duration lockTimeout = defaultLockTimeout,
    Duration staleLockAge = defaultStaleLockAge,
  }) async {
    Directory resolved;
    if (directory != null) {
      resolved = directory;
    } else {
      try {
        resolved = await getApplicationSupportDirectory();
      } on MissingPluginException {
        resolved = await Directory.systemTemp.createTemp(
          'huda-prayer-reliability-',
        );
      } on StateError catch (error) {
        if (!error.toString().contains(
          'Binding has not yet been initialized',
        )) {
          rethrow;
        }
        resolved = await Directory.systemTemp.createTemp(
          'huda-prayer-reliability-',
        );
      }
    }
    await resolved.create(recursive: true);
    return AtomicPrayerReliabilityStorage._(
      resolved,
      lockTimeout: lockTimeout,
      staleLockAge: staleLockAge,
    );
  }

  @override
  Future<T> runExclusive<T>(Future<T> Function() action) {
    final processLock = _processLocks.putIfAbsent(_primaryPath, Lock.new);
    return processLock.synchronized(() async {
      if (Platform.isLinux) {
        final ownership = LinuxPrayerStorageLock.open(_lockPath);
        final elapsed = Stopwatch()..start();
        try {
          while (!ownership.tryClaim()) {
            if (elapsed.elapsed >= _lockTimeout) {
              throw TimeoutException(
                'Timed out waiting for prayer scheduling ownership',
                _lockTimeout,
              );
            }
            await Future<void>.delayed(const Duration(milliseconds: 40));
          }
          return await action();
        } finally {
          ownership.close();
        }
      }
      final lockFile = File(_lockPath);
      final deadline = DateTime.now().add(_lockTimeout);
      while (true) {
        try {
          await lockFile.create(exclusive: true);
          break;
        } on FileSystemException {
          if (await _recoverStaleLock(lockFile)) {
            continue;
          }
          if (!DateTime.now().isBefore(deadline)) {
            throw TimeoutException(
              'Timed out waiting for prayer scheduling ownership',
              _lockTimeout,
            );
          }
          await Future<void>.delayed(const Duration(milliseconds: 40));
        }
      }

      RandomAccessFile? ownershipHandle;
      RandomAccessFile? pathVerificationHandle;
      var ownsPath = false;
      try {
        final ownerToken =
            '$pid-${DateTime.now().microsecondsSinceEpoch}-'
            '${_secureRandom.nextInt(1 << 32)}';
        final ownerRecord = jsonEncode(<String, Object?>{
          'pid': pid,
          'ownerToken': ownerToken,
          'createdAtUtc': DateTime.now().toUtc().toIso8601String(),
        });
        ownershipHandle = await lockFile.open(mode: FileMode.append);
        await ownershipHandle.lock(
          FileLock.exclusive,
          _ownershipLockStart,
          _ownershipLockEnd,
        );
        await ownershipHandle.truncate(0);
        await ownershipHandle.setPosition(0);
        await ownershipHandle.writeString(ownerRecord);
        await ownershipHandle.flush();

        pathVerificationHandle = await lockFile.open(mode: FileMode.read);
        final pathRecord = utf8.decode(
          await pathVerificationHandle.read(
            await pathVerificationHandle.length(),
          ),
        );
        if (pathRecord != ownerRecord) {
          throw StateError('Prayer scheduling ownership was superseded');
        }
        ownsPath = true;
        return await action();
      } finally {
        if (ownershipHandle != null) {
          try {
            await ownershipHandle.unlock(
              _ownershipLockStart,
              _ownershipLockEnd,
            );
          } on FileSystemException {
            // Closing the handle below still releases the ownership lock.
          }
        }
        await pathVerificationHandle?.close();
        await ownershipHandle?.close();
        if (ownsPath) {
          try {
            await lockFile.delete();
          } on FileSystemException {
            // A competing handle may retain the file; stale recovery retries.
          }
        }
      }
    });
  }

  Future<bool> _recoverStaleLock(File lockFile) async {
    RandomAccessFile? verificationHandle;
    try {
      final stat = await lockFile.stat();
      final now = DateTime.now();
      final age = now.difference(stat.modified);
      final futureDated = stat.modified.isAfter(now);
      if (!await lockFile.exists()) return true;
      final observedRecord = await lockFile.readAsString();
      Object? ownerPid;
      Object? ownerToken;
      try {
        final decoded = jsonDecode(observedRecord);
        if (decoded is Map) {
          ownerPid = decoded['pid'];
          ownerToken = decoded['ownerToken'];
        }
      } catch (_) {}
      final hasCompleteOwnerRecord =
          ownerPid is int && ownerToken is String && ownerToken.isNotEmpty;
      if (!hasCompleteOwnerRecord && !futureDated && age < _staleLockAge) {
        return false;
      }
      if (futureDated && !hasCompleteOwnerRecord) return false;
      // Windows locks belong to the file handle, including handles opened by
      // different isolates in this process. An exited isolate can leave its
      // record behind, so verify physical ownership before reclaiming it.
      // Other platforms may use process-scoped locks; retain their PID guard.
      if (ownerPid == pid && !Platform.isWindows) return false;

      verificationHandle = await lockFile.open(mode: FileMode.append);
      await verificationHandle.lock(
        FileLock.exclusive,
        _ownershipLockStart,
        _ownershipLockEnd,
      );
      await verificationHandle.setPosition(0);
      final lockedRecord = utf8.decode(
        await verificationHandle.read(await verificationHandle.length()),
      );
      if (lockedRecord != observedRecord) return false;
      if (Platform.isWindows) {
        // Dart's Windows handles deny deletion while open. A competing owner
        // that opens the path before this delete also prevents its removal.
        await verificationHandle.unlock(_ownershipLockStart, _ownershipLockEnd);
        await verificationHandle.close();
        verificationHandle = null;
      }
      await lockFile.delete();
      return true;
    } catch (_) {
      return false;
    } finally {
      if (verificationHandle != null) {
        try {
          await verificationHandle.unlock(
            _ownershipLockStart,
            _ownershipLockEnd,
          );
        } on FileSystemException {
          // Closing the verification handle below also releases its lock.
        }
        await verificationHandle.close();
      }
    }
  }

  @override
  Future<PrayerStorageRead> read() async {
    final primary = File(_primaryPath);
    final backup = File(_backupPath);
    final primaryExists = await primary.exists();
    final backupExists = await backup.exists();

    final primaryState = primaryExists ? await _decode(primary) : null;
    if (primaryState != null) {
      return PrayerStorageRead(PrayerStorageReadStatus.valid, primaryState);
    }
    final backupState = backupExists ? await _decode(backup) : null;
    if (backupState != null) {
      return PrayerStorageRead(
        PrayerStorageReadStatus.recoveredBackup,
        backupState,
      );
    }
    return PrayerStorageRead(
      primaryExists || backupExists
          ? PrayerStorageReadStatus.corrupt
          : PrayerStorageReadStatus.absent,
      null,
    );
  }

  Future<PrayerReliabilityState?> _decode(File file) async {
    try {
      final contents = await file.readAsString();
      if (_useValidationWorker) {
        return await Isolate.run(() {
          PrayerTimeZoneService.initializeDatabase();
          return PrayerReliabilityState.tryParse(_verifiedStateJson(contents));
        });
      }
      // JSON parsing and checksum verification run off the UI isolate. The
      // typed parse stays here: its time zone validation needs this
      // isolate's time zone database.
      final stateValue = await Isolate.run(() => _verifiedStateJson(contents));
      return PrayerReliabilityState.tryParse(stateValue);
    } catch (_) {
      return null;
    }
  }

  /// Returns the raw state JSON when [contents] is a legacy unwrapped state
  /// or an envelope whose checksum matches; null otherwise.
  static Object? _verifiedStateJson(String contents) {
    try {
      final decoded = jsonDecode(contents);
      if (decoded is! Map || !decoded.containsKey('storageSchemaVersion')) {
        return decoded;
      }
      if (decoded['storageSchemaVersion'] != storageSchemaVersion ||
          decoded['state'] is! Map ||
          decoded['sha256'] is! String) {
        return null;
      }
      final stateJson = decoded['state'];
      final expected = sha256
          .convert(utf8.encode(jsonEncode(stateJson)))
          .toString();
      return decoded['sha256'] == expected ? stateJson : null;
    } catch (_) {
      return null;
    }
  }

  /// Encodes and checksums [stateJson] in a single encode pass. The output is
  /// byte-identical to `jsonEncode` of the envelope map, which
  /// [_verifiedStateJson] relies on.
  static String _encodeEnvelope(Map<String, Object?> stateJson) {
    final encodedState = jsonEncode(stateJson);
    final checksum = sha256.convert(utf8.encode(encodedState)).toString();
    return '{"storageSchemaVersion":$storageSchemaVersion,'
        '"state":$encodedState,"sha256":"$checksum"}';
  }

  @override
  Future<void> write(PrayerReliabilityState state) async {
    final envelope = _useValidationWorker
        ? await Isolate.run(() {
            PrayerTimeZoneService.initializeDatabase();
            return _validateAndEncode(state);
          })
        : await _encodeFromCaller(state);
    await _writeEnvelope(envelope);
  }

  static String _validateAndEncode(PrayerReliabilityState state) {
    final stateJson = state.toJson();
    if (PrayerReliabilityState.tryParse(stateJson) == null) {
      throw StateError('Refusing to persist invalid prayer reliability state');
    }
    return _encodeEnvelope(stateJson);
  }

  static Future<String> _encodeFromCaller(PrayerReliabilityState state) async {
    final stateJson = state.toJson();
    if (PrayerReliabilityState.tryParse(stateJson) == null) {
      throw StateError('Refusing to persist invalid prayer reliability state');
    }
    return Isolate.run(() => _encodeEnvelope(stateJson));
  }

  Future<void> _writeEnvelope(String envelope) async {
    await directory.create(recursive: true);
    final primary = File(_primaryPath);
    final backup = File(_backupPath);
    final temporary = File(
      '$_primaryPath.tmp.$pid.${DateTime.now().microsecondsSinceEpoch}',
    );
    await temporary.writeAsString(envelope, flush: true);
    try {
      if (await primary.exists()) {
        if (await backup.exists()) await backup.delete();
        await primary.rename(_backupPath);
      }
      await temporary.rename(_primaryPath);
    } catch (_) {
      if (!await primary.exists() && await backup.exists()) {
        try {
          await backup.rename(_primaryPath);
        } catch (_) {}
      }
      rethrow;
    } finally {
      if (await temporary.exists()) {
        try {
          await temporary.delete();
        } on FileSystemException {
          // A later write or stale-file cleanup can remove this temporary file.
        }
      }
    }
  }
}

class InMemoryPrayerReliabilityStorage implements PrayerReliabilityStorage {
  InMemoryPrayerReliabilityStorage({PrayerReliabilityState? initialState})
    : _state = initialState;

  final Lock _lock = Lock();
  PrayerReliabilityState? _state;
  bool hasRecord = false;
  bool corrupt = false;

  PrayerReliabilityState? get state => _state;

  @override
  Future<T> runExclusive<T>(Future<T> Function() action) =>
      _lock.synchronized(action);

  @override
  Future<PrayerStorageRead> read() async {
    if (corrupt) {
      return const PrayerStorageRead(PrayerStorageReadStatus.corrupt, null);
    }
    if (_state == null && !hasRecord) {
      return const PrayerStorageRead(PrayerStorageReadStatus.absent, null);
    }
    return PrayerStorageRead(PrayerStorageReadStatus.valid, _state);
  }

  @override
  Future<void> write(PrayerReliabilityState state) async {
    _state = state;
    hasRecord = true;
  }
}
