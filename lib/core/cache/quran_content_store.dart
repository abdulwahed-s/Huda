import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:synchronized/synchronized.dart';

enum QuranContentKind { audio, tafsir, translation }

class StoredQuranContent {
  const StoredQuranContent(this.response, this.savedAt);

  final Map<String, dynamic> response;
  final int? savedAt;

  bool get isExpired =>
      savedAt == null ||
      DateTime.now().difference(
            DateTime.fromMillisecondsSinceEpoch(savedAt!),
          ) >=
          const Duration(hours: 24);
}

class QuranContentStore {
  QuranContentStore({
    required CacheHelper cache,
    String? storagePath,
    Future<LazyBox<String>> Function()? openBox,
  }) : _cache = cache,
       _storagePath = storagePath,
       _openBox = openBox;

  final CacheHelper _cache;
  final String? _storagePath;
  final Future<LazyBox<String>> Function()? _openBox;
  final Lock _lock = Lock();
  LazyBox<String>? _box;

  Future<LazyBox<String>> _open() async {
    if (_box?.isOpen == true) return _box!;
    if (_openBox != null) return _box = await _openBox();
    if (_storagePath == null) {
      await Hive.initFlutter();
    } else {
      Hive.init(_storagePath);
    }
    return _box = await Hive.openLazyBox<String>('quran_content_v1');
  }

  String _prefix(QuranContentKind kind, String identifier, bool full) =>
      '${full ? 'full' : 'surah'}:${kind.name}:$identifier:';

  Future<String?> readReciterCatalog(String language) =>
      _lock.synchronized(() => _readReciterCatalog('huda_reciters_$language'));

  Future<void> saveReciterCatalog(String language, String json) =>
      _lock.synchronized(() async {
        if (jsonDecode(json) is! List) {
          throw const FormatException('Invalid reciter catalog');
        }
        final key = 'huda_reciters_$language';
        await _writeStringVerified('catalog:$key', json);
        await _removeLegacy(key);
      });

  Future<String?> _readReciterCatalog(String key) async {
    final legacy = _cache.getDataString(key: key);
    try {
      final box = await _open();
      final saved = await box.get('catalog:$key');
      if (saved != null && jsonDecode(saved) is List) {
        if (legacy != null) await _removeLegacy(key);
        return saved;
      }
      if (legacy != null) {
        if (jsonDecode(legacy) is! List) {
          throw const FormatException('Invalid legacy reciter catalog');
        }
        await _writeStringVerified('catalog:$key', legacy);
        await _removeLegacy(key);
      }
      return legacy;
    } catch (_) {
      if (legacy != null) return legacy;
      rethrow;
    }
  }

  Future<StoredQuranContent?> readSurah(
    QuranContentKind kind,
    String identifier,
    int number,
  ) => _lock.synchronized(() async {
    await _migrateEdition(kind, identifier, number);
    try {
      final box = await _open();
      final raw =
          await box.get('${_prefix(kind, identifier, false)}$number') ??
          await box.get('${_prefix(kind, identifier, true)}$number');
      if (raw != null) {
        final record = jsonDecode(raw) as Map<String, dynamic>;
        return StoredQuranContent(
          record['response'] as Map<String, dynamic>,
          record['savedAt'] as int?,
        );
      }
      return _readLegacy(kind, identifier, number);
    } catch (_) {
      final legacy = _readLegacy(kind, identifier, number);
      if (legacy != null) return legacy;
      rethrow;
    }
  });

  Future<bool> hasSurah(QuranContentKind kind, String identifier, int number) =>
      _lock.synchronized(() async {
        await _migrateEdition(kind, identifier, number);
        if (_cache.getDataString(
              key: 'surah_${kind.name}_${identifier}_$number',
            ) !=
            null) {
          return true;
        }
        return (await _open()).containsKey(
          '${_prefix(kind, identifier, false)}$number',
        );
      });

  Future<void> saveSurah(
    QuranContentKind kind,
    String identifier,
    int number,
    Map<String, dynamic> response,
  ) => _lock.synchronized(() async {
    await _migrateEdition(kind, identifier, number);
    final parts = _split(response);
    if (parts.length != 1 || !parts.containsKey(number)) {
      throw const FormatException('Unexpected surah in Quran response');
    }
    await _writeVerified(
      '${_prefix(kind, identifier, false)}$number',
      parts[number]!,
      DateTime.now().millisecondsSinceEpoch,
    );
  });

  Future<void> saveFullEdition(
    QuranContentKind kind,
    String identifier,
    Map<String, dynamic> response,
  ) => _lock.synchronized(() async {
    await _migrateEdition(kind, identifier, null);
    await _saveFull(
      kind,
      identifier,
      response,
      DateTime.now().millisecondsSinceEpoch,
    );
  });

  Future<bool> hasFullEdition(QuranContentKind kind, String identifier) =>
      _lock.synchronized(() async {
        await _migrateEdition(kind, identifier, null);
        if (_cache.getDataString(key: 'full_quran_${kind.name}_$identifier') !=
            null) {
          return true;
        }
        final box = await _open();
        final prefix = _prefix(kind, identifier, true);
        if (box.containsKey('${prefix}complete') &&
            List.generate(
              114,
              (i) => i + 1,
            ).every((number) => box.containsKey('$prefix$number'))) {
          return true;
        }
        return false;
      });

  Future<void> deleteSurah(
    QuranContentKind kind,
    String identifier,
    int number,
  ) => _lock.synchronized(() async {
    await _removeLegacy('surah_${kind.name}_${identifier}_$number');
    await (await _open()).delete('${_prefix(kind, identifier, false)}$number');
  });

  Future<void> deleteFullEdition(QuranContentKind kind, String identifier) =>
      _lock.synchronized(() async {
        await _removeLegacy('full_quran_${kind.name}_$identifier');
        final box = await _open();
        final prefix = _prefix(kind, identifier, true);
        await box.deleteAll(
          box.keys.where((key) => key.toString().startsWith(prefix)).toList(),
        );
      });

  Future<void> clearAudio([String? identifier]) => _lock.synchronized(() async {
    final box = await _open();
    final prefix = identifier == null
        ? 'surah:audio:'
        : _prefix(QuranContentKind.audio, identifier, false);
    await box.deleteAll(
      box.keys.where((key) => key.toString().startsWith(prefix)).toList(),
    );
    for (final key in CacheHelper.sharedPreferences.getKeys()) {
      if (identifier == null
          ? key.startsWith('surah_audio_')
          : key == 'surah_audio_$identifier') {
        await _removeLegacy(key);
      }
    }
  });

  Future<void> migrateLegacyContent() => _lock.synchronized(() async {
    for (final key in CacheHelper.sharedPreferences.getKeys()) {
      if (key.startsWith('huda_reciters_')) {
        await _readReciterCatalog(key);
        continue;
      }
      if (RegExp(
        r'^(surah_(audio|tafsir|translation)_|full_quran_(tafsir|translation)_)',
      ).hasMatch(key)) {
        await _tryMigrate(key);
      }
    }
  });

  Future<void> _migrateEdition(
    QuranContentKind kind,
    String identifier,
    int? number,
  ) async {
    if (kind == QuranContentKind.audio) {
      await _tryMigrate('surah_audio_$identifier');
    } else {
      if (number != null) {
        await _tryMigrate('surah_${kind.name}_${identifier}_$number');
      }
      await _tryMigrate('full_quran_${kind.name}_$identifier');
    }
  }

  Future<void> _tryMigrate(String key) async {
    final raw = _cache.getDataString(key: key);
    if (raw == null) return;
    try {
      final response = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = _cache.getData(key: 'cache_timestamp_$key') as int?;
      final full = key.startsWith('full_quran_');
      final match = RegExp(
        r'^(?:full_quran|surah)_(audio|tafsir|translation)_(.+)$',
      ).firstMatch(key)!;
      final kind = QuranContentKind.values.byName(match[1]!);
      var identifier = match[2]!;
      final parts = _split(response);
      if (!full && kind != QuranContentKind.audio) {
        final separator = identifier.lastIndexOf('_');
        final number = int.parse(identifier.substring(separator + 1));
        identifier = identifier.substring(0, separator);
        if (parts.length != 1 || !parts.containsKey(number)) {
          throw const FormatException('Legacy surah does not match its key');
        }
      }
      if (full) {
        await _saveFull(kind, identifier, response, savedAt);
      } else {
        for (final part in parts.entries) {
          await _writeVerified(
            '${_prefix(kind, identifier, false)}${part.key}',
            part.value,
            savedAt,
          );
        }
      }
      await _removeLegacy(key);
    } catch (error) {
      debugPrint(
        'Retaining legacy Quran content after migration failure: $key ($error)',
      );
    }
  }

  Future<void> _saveFull(
    QuranContentKind kind,
    String identifier,
    Map<String, dynamic> response,
    int? savedAt,
  ) async {
    final parts = _split(response);
    if (parts.length != 114 ||
        !List.generate(114, (i) => i + 1).every(parts.containsKey)) {
      throw const FormatException('Incomplete Quran edition');
    }
    final box = await _open();
    final prefix = _prefix(kind, identifier, true);
    await box.delete('${prefix}complete');
    for (final part in parts.entries) {
      await _writeVerified('$prefix${part.key}', part.value, savedAt);
    }
    await box.put('${prefix}complete', 'true');
    await box.flush();
    if (await box.get('${prefix}complete') != 'true') {
      throw StateError('Could not verify Quran edition index');
    }
  }

  Future<void> _writeVerified(
    String key,
    Map<String, dynamic> response,
    int? savedAt,
  ) async {
    final encoded = jsonEncode({'response': response, 'savedAt': savedAt});
    await _writeStringVerified(key, encoded);
  }

  Future<void> _writeStringVerified(String key, String encoded) async {
    final box = await _open();
    await box.put(key, encoded);
    await box.flush();
    if (await box.get(key) != encoded) {
      throw StateError('Could not verify saved Quran content');
    }
  }

  Map<int, Map<String, dynamic>> _split(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>;
    final surahs = data['surahs'] as List? ?? [data];
    if (surahs.isEmpty) throw const FormatException('Empty Quran content');
    final parts = <int, Map<String, dynamic>>{};
    for (final value in surahs) {
      final surah = Map<String, dynamic>.from(value as Map);
      final number = surah['number'] as int;
      if (number < 1 ||
          number > 114 ||
          parts.containsKey(number) ||
          surah['ayahs'] is! List ||
          (surah['ayahs'] as List).isEmpty) {
        throw const FormatException('Invalid Quran content');
      }
      parts[number] = {
        ...response,
        'data': {
          ...data,
          'surahs': [surah],
        }..remove('ayahs'),
      };
    }
    return parts;
  }

  StoredQuranContent? _readLegacy(
    QuranContentKind kind,
    String identifier,
    int number,
  ) {
    final keys = kind == QuranContentKind.audio
        ? ['surah_audio_$identifier']
        : [
            'surah_${kind.name}_${identifier}_$number',
            'full_quran_${kind.name}_$identifier',
          ];
    for (final key in keys) {
      final raw = _cache.getDataString(key: key);
      if (raw == null) continue;
      try {
        final part = _split(jsonDecode(raw) as Map<String, dynamic>)[number];
        if (part != null) {
          return StoredQuranContent(
            part,
            _cache.getData(key: 'cache_timestamp_$key') as int?,
          );
        }
      } catch (_) {
      }
    }
    return null;
  }

  Future<void> _removeLegacy(String key) async {
    await _cache.removeData(key: key);
    await _cache.removeData(key: 'cache_timestamp_$key');
  }
}
