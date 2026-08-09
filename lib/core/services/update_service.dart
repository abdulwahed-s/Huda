import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/keys/hadith_key.dart';
import 'package:huda/core/services/app_store_target.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/utils/version_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/update_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const _cacheKey = 'update_check_cache';
  static const _cacheTimestampKey = 'update_check_cache_ts';
  static const _lastShownTsKey = 'update_prompt_last_shown_ts';
  static const _lastShownVersionKey = 'update_prompt_last_version';

  static const _cacheTtl = Duration(hours: 6);
  static const _remindInterval = Duration(hours: 12);

  static final Dio _dio = Dio();
  static Future<bool>? _activeCheckAndShow;

  static Future<bool> checkAndShow(BuildContext context) {
    final activeCheckAndShow = _activeCheckAndShow;
    if (activeCheckAndShow != null) return activeCheckAndShow;

    final request = _checkAndShow(context);
    _activeCheckAndShow = request;
    return request.whenComplete(() {
      if (identical(_activeCheckAndShow, request)) {
        _activeCheckAndShow = null;
      }
    });
  }

  static Future<bool> _checkAndShow(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final info = AppStoreInfo.resolve(packageInfo.installerStore);
      if (!info.canPrompt || info.lookupId == null) {
        return false;
      }

      final locale = context.mounted
          ? Localizations.localeOf(context)
          : const Locale('en');

      final latest = await _resolveLatest(info, locale);
      if (latest?.version == null) {
        return false;
      }

      final hasUpdate =
          VersionUtils.isNewer(latest!.version!, packageInfo.version);
      if (!hasUpdate) return false;

      if (_recentlyShown(latest.version!)) {
        return false;
      }

      if (!context.mounted) return false;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (_) => UpdateDialog(
          version: latest.version!,
          releaseNotes: latest.releaseNotes,
          onUpdate: () {
            final url = latest.url ?? info.storeUrl;
            if (info.target == AppStoreTarget.fdroid) {
              unawaited(_showUpdateSources(context, url));
            } else {
              unawaited(_launchStore(url));
            }
          },
        ),
      );

      await _markShown(latest.version!);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('UpdateService error: $e');
      return false;
    }
  }

  static Future<_UpdateInfo?> _resolveLatest(
      AppStoreInfo info, Locale locale) async {
    final cached = _getCached();
    if (cached != null && cached.store == info.target.name && _isCacheFresh()) {
      return cached;
    }

    try {
      final fetched = await _fetchFromEdge(info, locale);
      await _cache(fetched);
      return fetched;
    } catch (_) {
      if (cached != null && cached.store == info.target.name) return cached;
      return null;
    }
  }

  static Future<_UpdateInfo> _fetchFromEdge(
      AppStoreInfo info, Locale locale) async {
    if (info.target == AppStoreTarget.fdroid) {
      return _fetchFromFdroid(info);
    }

    final country = (locale.countryCode ??
            PlatformDispatcher.instance.locale.countryCode ??
            'us')
        .toLowerCase();

    final response = await _dio.post(
      '$supabaseUrl/functions/v1/version-check',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseAnonKey',
          'apikey': supabaseAnonKey,
        },
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
      data: {
        'store': info.target.name,
        'id': info.lookupId,
        'country': country,
        'lang': locale.languageCode,
        'locale': locale.toLanguageTag(),
      },
    );

    final data = response.data is String
        ? jsonDecode(response.data as String) as Map<String, dynamic>
        : (response.data as Map).cast<String, dynamic>();

    return _UpdateInfo(
      version: data['version'] as String?,
      url: data['url'] as String?,
      releaseNotes: data['releaseNotes'] as String?,
      store: info.target.name,
    );
  }

  static Future<_UpdateInfo> _fetchFromFdroid(AppStoreInfo info) async {
    final response = await _dio.get(
      'https://f-droid.org/api/v1/packages/${info.lookupId}',
      options: Options(
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );

    final data = response.data is String
        ? jsonDecode(response.data as String) as Map<String, dynamic>
        : (response.data as Map).cast<String, dynamic>();
    final suggestedCode = (data['suggestedVersionCode'] as num?)?.toInt();
    final packages = (data['packages'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((entry) => entry.cast<String, dynamic>())
        .toList();

    Map<String, dynamic>? selected;
    if (suggestedCode != null) {
      for (final package in packages) {
        if ((package['versionCode'] as num?)?.toInt() == suggestedCode) {
          selected = package;
          break;
        }
      }
    }
    if (selected == null && packages.isNotEmpty) {
      packages.sort((a, b) {
        final aCode = (a['versionCode'] as num?)?.toInt() ?? -1;
        final bCode = (b['versionCode'] as num?)?.toInt() ?? -1;
        return bCode.compareTo(aCode);
      });
      selected = packages.first;
    }

    return _UpdateInfo(
      version: selected?['versionName'] as String?,
      url: info.storeUrl,
      store: info.target.name,
    );
  }

  static _UpdateInfo? _getCached() {
    final raw = getIt<CacheHelper>().getDataString(key: _cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return _UpdateInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static bool _isCacheFresh() {
    final tsString =
        getIt<CacheHelper>().getDataString(key: _cacheTimestampKey);
    final ts = int.tryParse(tsString ?? '');
    if (ts == null) return false;
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now().difference(cachedAt) < _cacheTtl;
  }

  static Future<void> _cache(_UpdateInfo info) async {
    final cache = getIt<CacheHelper>();
    await cache.saveData(key: _cacheKey, value: jsonEncode(info.toJson()));
    await cache.saveData(
      key: _cacheTimestampKey,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  static bool _recentlyShown(String version) {
    final cache = getIt<CacheHelper>();
    if (cache.getDataString(key: _lastShownVersionKey) != version) return false;
    final ts = int.tryParse(cache.getDataString(key: _lastShownTsKey) ?? '');
    if (ts == null) return false;
    final shownAt = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now().difference(shownAt) < _remindInterval;
  }

  static Future<void> _markShown(String version) async {
    final cache = getIt<CacheHelper>();
    await cache.saveData(key: _lastShownVersionKey, value: version);
    await cache.saveData(
      key: _lastShownTsKey,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  static Future<void> _showUpdateSources(
    BuildContext context,
    String? fdroidUrl,
  ) async {
    if (!context.mounted || fdroidUrl == null) return;
    final l10n = AppLocalizations.of(context)!;
    final selectedUrl = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  l10n.chooseUpdateSource,
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.store_rounded),
                title: Text(l10n.fdroidStore),
                subtitle: Text(l10n.fdroidUpdateSourceDescription),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => Navigator.of(sheetContext).pop(fdroidUrl),
              ),
            ],
          ),
        ),
      ),
    );
    if (selectedUrl != null) {
      await _launchStore(selectedUrl);
    }
  }

  static Future<void> _launchStore(String? url) async {
    if (url == null) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}

class _UpdateInfo {
  final String? version;
  final String? url;
  final String? releaseNotes;
  final String? store;

  const _UpdateInfo({this.version, this.url, this.releaseNotes, this.store});

  factory _UpdateInfo.fromJson(Map<String, dynamic> json) => _UpdateInfo(
        version: json['version'] as String?,
        url: json['url'] as String?,
        releaseNotes: json['releaseNotes'] as String?,
        store: json['store'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'url': url,
        'releaseNotes': releaseNotes,
        'store': store,
      };
}
