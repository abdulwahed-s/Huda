import 'package:flutter/services.dart';

/// Saves a share image to the device's photos (the "Save image" action of
/// the share sheets).
///
/// One native handler per platform on the `com.aw.huda/gallery` channel:
/// method `saveImage`, arguments `{'bytes': Uint8List (PNG), 'name': String
/// (file name without extension)}`, returns `true` once saved.
///
/// * Android: `MediaStore.Images` under `Pictures/Huda` (no permission from
///   Android 10; WRITE_EXTERNAL_STORAGE asked for on 7-9),
///   `GalleryImageSaver.kt`.
/// * iOS: Photos, add-only (`NSPhotoLibraryAddUsageDescription`),
///   `GalleryImageChannel` in `AppDelegate.swift`.
/// * macOS: Downloads (sandbox `files.downloads.read-write`),
///   `GalleryImageChannel` in `MainFlutterWindow.swift`.
/// * Windows, Linux: Downloads, `gallery_image_saver.cpp` / `.cc`.
///
/// Desktops never replace a file: a taken name gets a number. A platform
/// without a handler (web) returns [ShareImageSaveResult.unavailable] and the
/// sheet says saving isn't available yet.
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
