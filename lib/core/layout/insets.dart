import 'package:flutter/widgets.dart';

/// End padding for scroll views on edge-to-edge screens: the content
/// scrolls under the transparent system bars and comes to rest fully above
/// them. Never put the inset outside the scroll view (it clips at a hard
/// line) or a `SafeArea` around the page (it leaves a band). See
/// `design/RESPONSIVE.md`, "The bottom edge and system bars".
extension HudaInsetsContext on BuildContext {
  /// [base] plus the bottom and side insets (the navigation bar, the home
  /// indicator, a landscape 3-button bar or the Duo's side column). Uses
  /// `paddingOf`, which drops to zero while the keyboard covers the bar.
  EdgeInsets scrollPadding(EdgeInsets base, {bool includeTop = false}) {
    final insets = MediaQuery.paddingOf(this);
    return base +
        EdgeInsets.only(
          left: insets.left,
          right: insets.right,
          bottom: insets.bottom,
          top: includeTop ? insets.top : 0,
        );
  }

  /// The bottom inset alone, for a pinned bar's content (its background
  /// still reaches the screen edge).
  double get bottomInset => MediaQuery.paddingOf(this).bottom;
}
