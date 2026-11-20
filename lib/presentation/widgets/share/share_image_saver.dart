import 'package:flutter/services.dart';

abstract final class ShareImageSaver {
  static const MethodChannel channel = MethodChannel('com.aw.huda/gallery');

  static Future<ShareImageSaveResult> save(
    Uint8List png, {
    required String name,
  }) async {
    try {
      final saved = await channel.invokeMethod<bool>('saveImage', {
        'bytes': png,
        'name': name,
      });
      return saved == true
          ? ShareImageSaveResult.saved
          : ShareImageSaveResult.failed;
    } on MissingPluginException {
      return ShareImageSaveResult.unavailable;
    } on PlatformException {
      return ShareImageSaveResult.failed;
    }
  }
}

enum ShareImageSaveResult {
  saved,

  unavailable,

  failed,
}
