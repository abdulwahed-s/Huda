import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';

enum FoldPosture {
  /// No fold or hinge in this window.
  none,

  /// A fold that is fully open (or a flat hinge between two screens).
  flat,

  /// Half open: book (vertical fold) or tabletop (horizontal fold).
  halfOpened,
}

/// Where the window's fold or hinge is, read from
/// `MediaQuery.displayFeaturesOf`. Android reports it natively; on iOS the
/// fold bridge (`IOSFoldDisplayFeatures`) adds it. Cutouts are ignored.
///
/// [bounds] are window coordinates in logical pixels. A [separatorAxis] of
/// [Axis.vertical] is a vertical line that splits the window into a left
/// and a right half (a book); [Axis.horizontal] splits it into top and
/// bottom (tabletop).
@immutable
class FoldInfo {
  const FoldInfo._(this.posture, this.bounds, this.separatorAxis);

  static const none = FoldInfo._(FoldPosture.none, Rect.zero, null);

  factory FoldInfo.of(BuildContext context) => FoldInfo.fromFeatures(
    MediaQuery.displayFeaturesOf(context),
    MediaQuery.sizeOf(context),
  );

  factory FoldInfo.fromFeatures(List<DisplayFeature> features, Size window) {
    final windowRect = Offset.zero & window;
    for (final feature in features) {
      if (feature.type != DisplayFeatureType.fold &&
          feature.type != DisplayFeatureType.hinge) {
        continue;
      }
      final bounds = feature.bounds;
      // A fold that doesn't cross this window (split screen) doesn't count.
      if (!bounds.overlaps(windowRect)) continue;
      final Axis axis;
      if (bounds.height >= window.height - 1 && bounds.width < window.width) {
        axis = Axis.vertical;
      } else if (bounds.width >= window.width - 1) {
        axis = Axis.horizontal;
      } else {
        continue;
      }
      return FoldInfo._(
        feature.state == DisplayFeatureState.postureHalfOpened
            ? FoldPosture.halfOpened
            : FoldPosture.flat,
        bounds,
        axis,
      );
    }
    return none;
  }

  final FoldPosture posture;
  final Rect bounds;
  final Axis? separatorAxis;

  bool get hasFold => posture != FoldPosture.none;
  bool get isHalfOpened => posture == FoldPosture.halfOpened;

  /// Half open with a vertical fold, held like a book.
  bool get isBook => isHalfOpened && separatorAxis == Axis.vertical;

  /// Half open with a horizontal fold, standing on a table.
  bool get isTabletop => isHalfOpened && separatorAxis == Axis.horizontal;

  /// Whether a two-pane layout should split at the fold (left and right).
  bool get splitsHorizontally => separatorAxis == Axis.vertical;

  /// Whether the fold splits the screen in two: it's half open, or it has a
  /// width (a hinge between two screens). Flutter's dialog and sheet routes
  /// avoid the same folds. A flat fold is a zero-width line and one screen:
  /// overlays center across it (`design/RESPONSIVE.md`).
  bool get avoided => isHalfOpened || bounds.shortestSide > 0;

  /// The fold's start and end along the split axis, in window coordinates.
  double get start => separatorAxis == Axis.vertical ? bounds.left : bounds.top;
  double get end =>
      separatorAxis == Axis.vertical ? bounds.right : bounds.bottom;

  @override
  bool operator ==(Object other) =>
      other is FoldInfo &&
      other.posture == posture &&
      other.bounds == bounds &&
      other.separatorAxis == separatorAxis;

  @override
  int get hashCode => Object.hash(posture, bounds, separatorAxis);

  @override
  String toString() => hasFold
      ? 'FoldInfo(${posture.name}, ${separatorAxis!.name}, $bounds)'
      : 'FoldInfo.none';
}

extension FoldContext on BuildContext {
  FoldInfo get fold => FoldInfo.of(this);
}
