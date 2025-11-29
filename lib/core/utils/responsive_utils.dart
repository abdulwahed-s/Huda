import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

class ResponsiveUtils {
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 950;

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > tabletMaxWidth) {
      return DeviceType.desktop;
    } else if (width > mobileMaxWidth) {
      return DeviceType.tablet;
    } else {
      return DeviceType.mobile;
    }
  }

  static bool getIfDeviceWidthMoreThenMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > mobileMaxWidth) {
      return true;
    } else {
      return false;
    }
  }

  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  static Size getResponsiveDesignSize(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.desktop:
        return const Size(1440, 900); // Common desktop resolution
      case DeviceType.tablet:
        return const Size(834, 1194); // iPad Pro 11-inch
      case DeviceType.mobile:
        return const Size(360, 690); // Standard mobile reference
    }
  }

  // Helper to get responsive value based on device type
  static T getValue<T>(BuildContext context,
      {required T mobile, T? tablet, T? desktop}) {
    final deviceType = getDeviceType(context);
    if (deviceType == DeviceType.desktop && desktop != null) return desktop;
    if (deviceType == DeviceType.tablet && tablet != null) return tablet;
    return mobile;
  }
}

extension ResponsiveContext on BuildContext {
  DeviceType get deviceType => ResponsiveUtils.getDeviceType(this);
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  T responsive<T>({required T mobile, T? tablet, T? desktop}) =>
      ResponsiveUtils.getValue(this,
          mobile: mobile, tablet: tablet, desktop: desktop);
}
