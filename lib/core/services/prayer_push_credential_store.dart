import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huda/core/cache/cache_helper.dart';

class PrayerPushInstallationIdentity {
  const PrayerPushInstallationIdentity(this.id, this.secret);

  final String id;
  final String secret;
}

abstract interface class PrayerPushSecureStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class KeychainPrayerPushSecureStore implements PrayerPushSecureStore {
  const KeychainPrayerPushSecureStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(migrateWithBackup: true),
          );

  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
  );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) =>
      _storage.read(key: key, iOptions: _iosOptions);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value, iOptions: _iosOptions);
}

class PrayerPushCredentialStore {
  PrayerPushCredentialStore({
    required this.cacheHelper,
    PrayerPushSecureStore? secureStore,
  }) : secureStore = secureStore ?? const KeychainPrayerPushSecureStore();

  static const secureIdentityKey = 'prayer_push_installation_identity_v1';
  static const legacyIdKey = 'prayer_push_installation_id';
  static const legacySecretKey = 'prayer_push_installation_secret';

  final CacheHelper cacheHelper;
  final PrayerPushSecureStore secureStore;

  Future<PrayerPushInstallationIdentity?> read() async {
    try {
      final secured = _decode(await secureStore.read(secureIdentityKey));
      if (secured != null) return secured;
    } catch (_) {}

    final legacy = _legacyIdentity();
    if (legacy == null) return null;
    await _writeSecurelyOrRetainLegacy(legacy);
    return legacy;
  }

  Future<void> write(PrayerPushInstallationIdentity identity) async {
    await _writeSecurelyOrRetainLegacy(identity);
  }

  PrayerPushInstallationIdentity? _legacyIdentity() {
    final id = cacheHelper.getDataString(key: legacyIdKey);
    final secret = cacheHelper.getDataString(key: legacySecretKey);
    if (id == null || id.isEmpty || secret == null || secret.isEmpty) {
      return null;
    }
    return PrayerPushInstallationIdentity(id, secret);
  }

  Future<void> _writeSecurelyOrRetainLegacy(
    PrayerPushInstallationIdentity identity,
  ) async {
    final encoded = jsonEncode({'id': identity.id, 'secret': identity.secret});
    try {
      await secureStore.write(secureIdentityKey, encoded);
      final verified = _decode(await secureStore.read(secureIdentityKey));
      if (verified?.id == identity.id && verified?.secret == identity.secret) {
        await cacheHelper.removeData(key: legacyIdKey);
        await cacheHelper.removeData(key: legacySecretKey);
        return;
      }
    } catch (_) {}

    await cacheHelper.saveData(key: legacyIdKey, value: identity.id);
    await cacheHelper.saveData(key: legacySecretKey, value: identity.secret);
  }

  PrayerPushInstallationIdentity? _decode(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;
      final id = decoded['id']?.toString();
      final secret = decoded['secret']?.toString();
      if (id == null || id.isEmpty || secret == null || secret.isEmpty) {
        return null;
      }
      return PrayerPushInstallationIdentity(id, secret);
    } catch (_) {
      return null;
    }
  }
}
