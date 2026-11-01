import 'package:flutter/widgets.dart';

/// Material 3 window width classes. See `design/RESPONSIVE.md`.
enum WindowWidthClass {
  compact,
  medium,
  expanded,
  large,
  extraLarge;

  static WindowWidthClass fromWidth(double width) {
    if (width < 600) return compact;
    if (width < 840) return medium;
    if (width < 1200) return expanded;
    if (width < 1600) return large;
    return extraLarge;
  }

  bool operator >=(WindowWidthClass other) => index >= other.index;
  bool operator <(WindowWidthClass other) => index < other.index;
}

/// Window height classes. Compact height is phone landscape and the
/// iPhone Duo closed in landscape.
enum WindowHeightClass {
  compact,
  medium,
  expanded;

  static WindowHeightClass fromHeight(double height) {
    if (height < 480) return compact;
    if (height < 900) return medium;
    return expanded;
  }

  bool operator >=(WindowHeightClass other) => index >= other.index;
  bool operator <(WindowHeightClass other) => index < other.index;
}

/// The size class of a window or of a component's constraints.
///
/// Page-level code reads `context.windowClass` (the window); components use
/// [WindowClass.fromSize] with their `LayoutBuilder` constraints.
@immutable
class WindowClass {
  const WindowClass(this.width, this.height);

  factory WindowClass.fromSize(Size size) => WindowClass(
    WindowWidthClass.fromWidth(size.width),
    WindowHeightClass.fromHeight(size.height),
  );

  factory WindowClass.of(BuildContext context) =>
      WindowClass.fromSize(MediaQuery.sizeOf(context));

  final WindowWidthClass width;
  final WindowHeightClass height;

  bool get isCompact => width == WindowWidthClass.compact;
  bool get isCompactHeight => height == WindowHeightClass.compact;

  @override
  bool operator ==(Object other) =>
      other is WindowClass && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'WindowClass(${width.name} × ${height.name})';
}

extension WindowClassContext on BuildContext {
  WindowClass get windowClass => WindowClass.of(this);
}
