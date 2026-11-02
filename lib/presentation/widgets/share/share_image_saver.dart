import 'package:flutter/services.dart';

/// Saves a share image to the device's photos (the "Save image" action of
/// the share sheets).
///
/// **Placeholder** (owner, 2026-10-31): the native side comes later, one
/// handler per platform on the `com.aw.huda/gallery` channel:
///
/// * method `saveImage`, arguments `{'bytes': Uint8List (PNG), 'name':
///   String (file name without extension)}`, returns `true` once saved.
/// * Android: insert into `MediaStore.Images` under `Pictures/Huda` (no
///   permission from Android 10).
/// * iOS: `PHPhotoLibrary` add-only, with `NSPhotoLibraryAddUsageDescription`
///   in `Info.plist`.
/// * macOS, Windows, Linux: write to the Downloads folder.
///
/// Until a platform has its handler, [save] returns
/// [ShareImageSaveResult.unavailable] and the sheet says saving isn't
/// available yet.
abstract final class ShareImageSaver {
  static const MethodChannel channel = MethodChannel('com.aw.huda/gallery');

  /// Whether [png] was saved, and if not, whether it could have been.
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

/// How a save went: the sheet words each one (owner round 4).
enum ShareImageSaveResult {
  saved,

  /// No handler on this platform yet: trying again won't help.
  unavailable,

  /// The platform tried and failed (no space, permission denied).
  failed,
}
