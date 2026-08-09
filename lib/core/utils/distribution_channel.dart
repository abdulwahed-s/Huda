import 'package:flutter/services.dart' show appFlavor;

abstract final class DistributionChannel {
  static bool get isFoss => appFlavor == 'foss';

  static bool get isAppGallery => appFlavor == 'appgallery';
}
