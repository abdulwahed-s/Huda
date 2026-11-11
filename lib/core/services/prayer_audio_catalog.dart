/// Shared manifest rules. Bundled descriptors remain platform-specific.
abstract final class PrayerAudioCatalogRules {
  static const bundledReciterId = 'huda-default';
  static final idPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
  static final versionPattern = RegExp(r'^v[1-9][0-9]*$');
  static final catalogUrl = Uri.parse(
    'https://aiheljvapaxaztcehufr.supabase.co/storage/v1/object/public/athan/catalog.json',
  );
}

class PrayerAudioVariant {
  PrayerAudioVariant(
    Map<String, dynamic> json,
    this.filename, {
    bool bundled = false,
  }) : url = json['url'] == null ? null : Uri.parse(json['url'] as String),
       bytes = json['bytes'] as int,
       sha256Hex = json['sha256'] as String,
       durationMs = json['duration_ms'] as int {
    if ((!bundled &&
            (url == null ||
                url!.scheme != 'https' ||
                url!.host != PrayerAudioCatalogRules.catalogUrl.host ||
                !url!.path.startsWith('/storage/v1/object/public/athan/'))) ||
        bytes < 1 ||
        bytes > 8388608 ||
        durationMs < 1 ||
        durationMs > 3600000 ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256Hex)) {
      throw const FormatException('Invalid prayer audio manifest.');
    }
  }
  final Uri? url;
  final int bytes, durationMs;
  final String sha256Hex, filename;
}

class PrayerAudioReciter {
  PrayerAudioReciter(Map<String, dynamic> json)
    : id = json['id'] as String,
      isBundled = json['source'] == 'bundled',
      nameEn = json['name_en'] as String,
      nameAr = json['name_ar'] as String,
      full = PrayerAudioVariant(
        json['full'] as Map<String, dynamic>,
        'full.mp3',
        bundled: json['source'] == 'bundled',
      ),
      short = PrayerAudioVariant(
        json['notification'] as Map<String, dynamic>,
        json['source'] == 'bundled'
            ? (json['notification'] as Map<String, dynamic>)['filename']
                      as String? ??
                  'full.mp3'
            : 'notification.wav',
        bundled: json['source'] == 'bundled',
      ) {
    if (!PrayerAudioCatalogRules.idPattern.hasMatch(id) ||
        nameEn.isEmpty ||
        nameAr.isEmpty ||
        (isBundled && id != PrayerAudioCatalogRules.bundledReciterId) ||
        !const {
          'full.mp3',
          'notification.wav',
          'notification.caf',
        }.contains(short.filename)) {
      throw const FormatException('Invalid prayer reciter.');
    }
  }
  final String id, nameEn, nameAr;
  final bool isBundled;
  final PrayerAudioVariant full, short;
  String name(String locale) => locale.startsWith('ar') ? nameAr : nameEn;
}

class PrayerAudioCatalog {
  PrayerAudioCatalog._(this.version, this.reciters);
  PrayerAudioCatalog(Map<String, dynamic> json)
    : version = json['audio_version'] as String,
      reciters = (json['reciters'] as List)
          .map((e) => PrayerAudioReciter(e as Map<String, dynamic>))
          .toList() {
    if (json['schema_version'] != 1 ||
        !PrayerAudioCatalogRules.versionPattern.hasMatch(version) ||
        reciters.isEmpty ||
        reciters.map((r) => r.id).toSet().length != reciters.length) {
      throw const FormatException('Unsupported prayer audio catalog.');
    }
  }
  final String version;
  final List<PrayerAudioReciter> reciters;
  PrayerAudioCatalog withBuiltIn(PrayerAudioReciter reciter) =>
      PrayerAudioCatalog._(version, [
        reciter,
        ...reciters.where((item) => item.id != reciter.id),
      ]);
}
