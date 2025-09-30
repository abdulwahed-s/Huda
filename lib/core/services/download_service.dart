import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:huda/core/services/service_locator.dart';

class DownloadService {
  final Dio _dio = getIt<Dio>();

  Future<String?> downloadAudioFile({
    required String url,
    required String fileName,
    required String surahNumber,
    required String ayahNumber,
    Function(double)? onProgress,
  }) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final audioDir =
          Directory('${appDocDir.path}/quran_audio/surah_$surahNumber');

      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final filePath = '${audioDir.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        return filePath;
      }

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      return filePath;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isFileDownloaded({
    required String surahNumber,
    required String ayahNumber,
    required String fileName,
  }) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final filePath =
          '${appDocDir.path}/quran_audio/surah_$surahNumber/$fileName';
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  Future<String?> getLocalFilePath({
    required String surahNumber,
    required String ayahNumber,
    required String fileName,
  }) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final filePath =
          '${appDocDir.path}/quran_audio/surah_$surahNumber/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteDownloadedFile({
    required String surahNumber,
    required String ayahNumber,
    required String fileName,
  }) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final filePath =
          '${appDocDir.path}/quran_audio/surah_$surahNumber/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<int> getSurahDownloadSize(String surahNumber) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final audioDir =
          Directory('${appDocDir.path}/quran_audio/surah_$surahNumber');

      if (!await audioDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (FileSystemEntity entity in audioDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
