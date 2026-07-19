import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/data/models/offline_audiobook_model.dart';
import 'package:path_provider/path_provider.dart';

class OfflineAudiobooksService {
  static const String _audiobooksKey = 'offline_audiobooks';
  static const String _downloadProgressKey = 'audiobook_download_progress';

  static bool get isSupported => !kIsWeb;

  Future<Directory> _getAudiobooksDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Offline audiobooks not supported on web');
    }
    final appDocDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDocDir.path}/huda_audiobooks');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _getAudiobookDirectory(int id) async {
    final root = await _getAudiobooksDirectory();
    final dir = Directory('${root.path}/$id');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> getTrackPath(int id, int order) async {
    final dir = await _getAudiobookDirectory(id);
    final tracksDir = Directory('${dir.path}/tracks');
    if (!await tracksDir.exists()) {
      await tracksDir.create(recursive: true);
    }
    return '${tracksDir.path}/track_$order.mp3';
  }

  Future<String> getImagePath(int id, String fileName) async {
    final dir = await _getAudiobookDirectory(id);
    final imagesDir = Directory('${dir.path}/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return '${imagesDir.path}/$fileName';
  }

  Future<void> saveAudiobook(OfflineAudiobookModel audiobook) async {
    try {
      final dir = await _getAudiobookDirectory(audiobook.id);
      final infoFile = File('${dir.path}/audiobook_info.json');
      await infoFile.writeAsString(jsonEncode(audiobook.toJson()));

      final list = await getAllAudiobooks();
      final existingIndex = list.indexWhere((a) => a.id == audiobook.id);
      if (existingIndex != -1) {
        list[existingIndex] = audiobook;
      } else {
        list.add(audiobook);
      }
      await _saveToPrefs(list);
    } catch (e) {
      throw Exception('Failed to save audiobook: $e');
    }
  }

  Future<List<OfflineAudiobookModel>> getAllAudiobooks() async {
    try {
      final data = CacheHelper.sharedPreferences.getString(_audiobooksKey);
      if (data == null) return [];
      final List<dynamic> list = jsonDecode(data);
      return list.map((json) => OfflineAudiobookModel.fromJson(json)).toList();
    } catch (e) {
      return await _getAudiobooksFromDirectory();
    }
  }

  Future<List<OfflineAudiobookModel>> _getAudiobooksFromDirectory() async {
    try {
      final root = await _getAudiobooksDirectory();
      final List<OfflineAudiobookModel> list = [];
      await for (final entity in root.list()) {
        if (entity is Directory) {
          try {
            final infoFile = File('${entity.path}/audiobook_info.json');
            if (await infoFile.exists()) {
              final data = await infoFile.readAsString();
              list.add(OfflineAudiobookModel.fromJson(jsonDecode(data)));
            }
          } catch (e) {
            continue;
          }
        }
      }
      await _saveToPrefs(list);
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveToPrefs(List<OfflineAudiobookModel> list) async {
    final json = list.map((a) => a.toJson()).toList();
    await CacheHelper.sharedPreferences
        .setString(_audiobooksKey, jsonEncode(json));
  }

  Future<OfflineAudiobookModel?> getAudiobook(int id) async {
    try {
      final list = await getAllAudiobooks();
      return list.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteAudiobook(int id) async {
    try {
      final dir = await _getAudiobookDirectory(id);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      final list = await getAllAudiobooks();
      list.removeWhere((a) => a.id == id);
      await _saveToPrefs(list);
      await removeDownloadProgress(id);
    } catch (e) {
      throw Exception('Failed to delete audiobook: $e');
    }
  }

  Future<bool> isAudiobookDownloaded(int id) async {
    final audiobook = await getAudiobook(id);
    if (audiobook == null) return false;
    if (audiobook.tracks.isEmpty) return false;
    for (final track in audiobook.tracks) {
      if (!track.isDownloaded || !await File(track.localPath).exists()) {
        return false;
      }
    }
    return true;
  }

  Future<List<OfflineAudiobookModel>> getAudiobooksByLanguage(
      String language) async {
    final list = await getAllAudiobooks();
    return list.where((a) => a.language == language).toList();
  }

  Future<List<OfflineAudiobookModel>> searchAudiobooks(String query) async {
    final list = await getAllAudiobooks();
    final q = query.toLowerCase();
    return list.where((a) {
      return a.title.toLowerCase().contains(q) ||
          a.description.toLowerCase().contains(q) ||
          a.preparedBy.any(
              (author) => author.title?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> saveDownloadProgress(DownloadProgress progress) async {
    try {
      final map = await _getAllDownloadProgress();
      map[progress.bookId.toString()] = _progressToJson(progress);
      await CacheHelper.sharedPreferences
          .setString(_downloadProgressKey, jsonEncode(map));
    } catch (e) {
      throw Exception('Failed to save download progress: $e');
    }
  }

  Future<DownloadProgress?> getDownloadProgress(int id) async {
    try {
      final map = await _getAllDownloadProgress();
      final data = map[id.toString()];
      if (data != null) {
        return DownloadProgress(
          bookId: data['bookId'],
          fileName: data['fileName'],
          progress: data['progress'],
          downloadedBytes: data['downloadedBytes'],
          totalBytes: data['totalBytes'],
          status: DownloadStatus.values
              .firstWhere((status) => status.name == data['status']),
          error: data['error'],
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _getAllDownloadProgress() async {
    try {
      final data =
          CacheHelper.sharedPreferences.getString(_downloadProgressKey);
      if (data == null) return {};
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (e) {
      return {};
    }
  }

  Future<void> removeDownloadProgress(int id) async {
    try {
      final map = await _getAllDownloadProgress();
      map.remove(id.toString());
      await CacheHelper.sharedPreferences
          .setString(_downloadProgressKey, jsonEncode(map));
    } catch (e) {}
  }

  Future<void> cleanupOrphanedFiles() async {
    try {
      final root = await _getAudiobooksDirectory();
      final list = await getAllAudiobooks();
      final validIds = list.map((a) => a.id.toString()).toSet();
      await for (final entity in root.list()) {
        if (entity is Directory) {
          final dirName = entity.path.split('/').last;
          if (!validIds.contains(dirName)) {
            await entity.delete(recursive: true);
          }
        }
      }
    } catch (e) {}
  }

  Map<String, dynamic> _progressToJson(DownloadProgress p) {
    return {
      'bookId': p.bookId,
      'fileName': p.fileName,
      'progress': p.progress,
      'downloadedBytes': p.downloadedBytes,
      'totalBytes': p.totalBytes,
      'status': p.status.name,
      'error': p.error,
    };
  }
}
