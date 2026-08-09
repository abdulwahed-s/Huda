import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/core/utils/distribution_channel.dart';

enum AppStoreTarget {
  play,
  fdroid,
  appGallery,
  appStore,
  macAppStore,
  microsoftStore,
  snap,
  unknown,
}

class AppStoreInfo {
  final AppStoreTarget target;

  final String? lookupId;

  final String? storeUrl;

  final String? reviewUrl;

  final bool canPrompt;

  const AppStoreInfo({
    required this.target,
    required this.canPrompt,
    this.lookupId,
    this.storeUrl,
    this.reviewUrl,
  });

  static const _androidPackage = 'com.aw.huda';
  static const _appleBundleId = 'com.aw.huda';
  static const _appleAppStoreId = '6757343816';
  static const _microsoftProductId = '9p68h8m1g92b';
  static const _appGalleryContentId = 'C115050257';
  static const _snapName = 'huda';

  static AppStoreInfo resolve(String? installerStore) {
    if (PlatformUtils.isAndroid) {
      if (DistributionChannel.isFoss) {
        return const AppStoreInfo(
          target: AppStoreTarget.fdroid,
          canPrompt: true,
          lookupId: _androidPackage,
          storeUrl: 'https://f-droid.org/packages/$_androidPackage/',
        );
      }

      if (DistributionChannel.isAppGallery) {
        return const AppStoreInfo(
          target: AppStoreTarget.appGallery,
          canPrompt: true,
          lookupId: _appGalleryContentId,
          storeUrl: 'appmarket://details?id=$_androidPackage',
        );
      }

      const play = AppStoreInfo(
        target: AppStoreTarget.play,
        canPrompt: true,
        lookupId: _androidPackage,
        storeUrl:
            'https://play.google.com/store/apps/details?id=$_androidPackage',
        reviewUrl: 'market://details?id=$_androidPackage',
      );
      switch (installerStore) {
        case 'com.huawei.appmarket':
          return const AppStoreInfo(
            target: AppStoreTarget.appGallery,
            canPrompt: true,
            lookupId: _appGalleryContentId,
            storeUrl: 'appmarket://details?id=$_androidPackage',
          );
        case 'com.android.vending':
        default:
          return play;
      }
    }

    if (PlatformUtils.isIOS) {
      return const AppStoreInfo(
        target: AppStoreTarget.appStore,
        canPrompt: true,
        lookupId: _appleBundleId,
        storeUrl: 'https://apps.apple.com/app/id$_appleAppStoreId',
        reviewUrl:
            'https://apps.apple.com/app/id$_appleAppStoreId?action=write-review',
      );
    }

    if (PlatformUtils.isMacOS) {
      return const AppStoreInfo(
        target: AppStoreTarget.macAppStore,
        canPrompt: true,
        lookupId: _appleBundleId,
        storeUrl: 'macappstore://apps.apple.com/app/id$_appleAppStoreId',
        reviewUrl:
            'macappstore://apps.apple.com/app/id$_appleAppStoreId?action=write-review',
      );
    }

    if (PlatformUtils.isWindow) {
      return const AppStoreInfo(
        target: AppStoreTarget.microsoftStore,
        canPrompt: true,
        lookupId: _microsoftProductId,
        storeUrl: 'ms-windows-store://pdp/?ProductId=$_microsoftProductId',
        reviewUrl: 'ms-windows-store://review/?ProductId=$_microsoftProductId',
      );
    }

    if (PlatformUtils.isLinux) {
      return const AppStoreInfo(
        target: AppStoreTarget.snap,
        canPrompt: true,
        lookupId: _snapName,
        // snap:// opens the Snap Store GUI; the edge function also returns the
        // snapcraft.io URL as a fallback.
        storeUrl: 'snap://$_snapName',
      );
    }

    return const AppStoreInfo(target: AppStoreTarget.unknown, canPrompt: false);
  }
}
