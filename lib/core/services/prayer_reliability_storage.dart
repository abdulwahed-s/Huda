import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:huda/core/services/prayer_reconciliation_state.dart';
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

  final Directory directory;
  final Duration _lockTimeout;
  final Duration _staleLockAge;

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
        await ownershipHandle.lock(FileLock.exclusive);
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
            await ownershipHandle.unlock();
          } on FileSystemException {}
        }
        await pathVerificationHandle?.close();
        await ownershipHandle?.close();
        if (ownsPath) {
          try {
            await lockFile.delete();
          } on FileSystemException {}
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
      if (ownerPid == pid) return false;

      verificationHandle = await lockFile.open(mode: FileMode.append);
      await verificationHandle.lock(FileLock.exclusive);
      await verificationHandle.setPosition(0);
      final lockedRecord = utf8.decode(
        await verificationHandle.read(await verificationHandle.length()),
      );
      if (lockedRecord != observedRecord) return false;
      await lockFile.delete();
      return true;
    } catch (_) {
      return false;
    } finally {
      if (verificationHandle != null) {
        try {
          await verificationHandle.unlock();
        } on FileSystemException {}
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
      final decoded = jsonDecode(await file.readAsString());
      Object? stateValue = decoded;
      if (decoded is Map && decoded.containsKey('storageSchemaVersion')) {
        if (decoded['storageSchemaVersion'] != storageSchemaVersion ||
            decoded['state'] is! Map ||
            decoded['sha256'] is! String) {
          return null;
        }
        final stateJson = decoded['state'];
        final expected = sha256
            .convert(utf8.encode(jsonEncode(stateJson)))
            .toString();
        if (decoded['sha256'] != expected) return null;
        stateValue = stateJson;
      }
      return PrayerReliabilityState.tryParse(stateValue);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(PrayerReliabilityState state) async {
    final validated = PrayerReliabilityState.tryParse(state.toJson());
    if (validated == null) {
      throw StateError('Refusing to persist invalid prayer reliability state');
    }
    await directory.create(recursive: true);
    final primary = File(_primaryPath);
    final backup = File(_backupPath);
    final temporary = File(
      '$_primaryPath.tmp.$pid.${DateTime.now().microsecondsSinceEpoch}',
    );
    final stateJson = state.toJson();
    final checksum = sha256
        .convert(utf8.encode(jsonEncode(stateJson)))
        .toString();
    final envelope = <String, Object?>{
      'storageSchemaVersion': storageSchemaVersion,
      'state': stateJson,
      'sha256': checksum,
    };
    await temporary.writeAsString(jsonEncode(envelope), flush: true);
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
        } on FileSystemException {}
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
