import 'dart:async';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:huda/core/utils/platform_utils.dart';

/// Adds the iPhone Duo's fold and inner camera to
/// [MediaQueryData.displayFeatures], so layout code reads folds the same way
/// on iOS as on Android.
///
/// Flutter fills `displayFeatures` on Android but not on iOS yet
/// (flutter/flutter#192515). `ios/Runner/IOSFoldBridge.swift` reads the iOS
/// 27.1 reserved regions and the hinge and sends them here. Place this below
/// every `MediaQuery` the app root adds, so it extends the final data.
class IOSFoldDisplayFeatures extends StatefulWidget {
  const IOSFoldDisplayFeatures({super.key, required this.child, this.enabled});

  final Widget child;

  /// Whether to listen to the native bridge. Null means "on iOS".
  final bool? enabled;

  /// The bridge's channel; `getState` returns the raw payload.
  static const channel = MethodChannel('com.aw.huda/fold');

  /// The display features in a native payload: `division` regions become
  /// folds, with a posture from the hinge, and active `occlusion` regions
  /// become cutouts. Bounds include the region's margins, which iOS reserves
  /// around the fold and camera for interactive content.
  ///
  /// iOS marks the division inactive while the device is flat (measured on
  /// the iPhone Duo simulator) and active once it bends. Android reports a
  /// flat fold as `postureFlat`, and the layout rules rely on that (even
  /// grid columns, panes split at the fold), so an inactive division counts
  /// as a flat fold when the hinge reports fully open.
  ///
  /// A flat fold is one continuous screen, so like Android it is a zero-width
  /// line at the crease. Flutter's dialog and sheet routes then center on
  /// the whole window, as on a tablet, and avoid the fold only while it is
  /// half open (`design/RESPONSIVE.md`, owner's rule of 2026-10-30).
  static List<DisplayFeature> parse(Object? payload) {
    if (payload is! Map) return const [];
    final hinge = payload['hinge'];
    final posture = switch (hinge is Map ? hinge['status'] : null) {
      'partiallyOpen' => DisplayFeatureState.postureHalfOpened,
      'fullyOpen' => DisplayFeatureState.postureFlat,
      _ => DisplayFeatureState.unknown,
    };
    final regions = payload['regions'];
    if (regions is! List) return const [];
    final features = <DisplayFeature>[];
    for (final region in regions) {
      if (region is! Map) continue;
      final active = region['active'] == true;
      final flatFold =
          !active &&
          region['kind'] == 'division' &&
          posture == DisplayFeatureState.postureFlat;
      if (!active && !flatFold) continue;
      final type = switch (region['kind']) {
        'division' => DisplayFeatureType.fold,
        'occlusion' => DisplayFeatureType.cutout,
        _ => null,
      };
      final bounds = _bounds(region);
      if (type == null || bounds == null) continue;
      final flat =
          type == DisplayFeatureType.fold &&
          posture == DisplayFeatureState.postureFlat;
      features.add(
        DisplayFeature(
          bounds: flat ? _crease(bounds) : bounds,
          type: type,
          state: type == DisplayFeatureType.fold
              ? posture
              : DisplayFeatureState.unknown,
        ),
      );
    }
    return features;
  }

  /// The center line of a fold band, along its long side.
  static Rect _crease(Rect band) => band.height >= band.width
      ? Rect.fromLTWH(band.center.dx, band.top, 0, band.height)
      : Rect.fromLTWH(band.left, band.center.dy, band.width, 0);

  static Rect? _bounds(Map region) {
    final [left, top, width, height] = [
      for (final key in const ['left', 'top', 'width', 'height'])
        switch (region[key]) {
          final num value when value.isFinite => value.toDouble(),
          _ => double.nan,
        },
    ];
    if ([left, top, width, height].any((value) => value.isNaN)) return null;
    if (width < 0 || height < 0) return null;
    return Rect.fromLTWH(left, top, width, height);
  }

  @override
  State<IOSFoldDisplayFeatures> createState() => _IOSFoldDisplayFeaturesState();
}

class _IOSFoldDisplayFeaturesState extends State<IOSFoldDisplayFeatures> {
  List<DisplayFeature> _features = const [];
  late final bool _enabled = widget.enabled ?? PlatformUtils.isIOS;

  @override
  void initState() {
    super.initState();
    if (_enabled) _listen();
  }

  void _listen() {
    IOSFoldDisplayFeatures.channel.setMethodCallHandler((call) async {
      if (call.method == 'stateChanged') _apply(call.arguments);
    });
    unawaited(
      IOSFoldDisplayFeatures.channel
          .invokeMethod<Object?>('getState')
          .then(_apply)
          .catchError((Object error) {
            // Older Runner builds or a missing plugin: no fold to report.
            debugPrint('iOS fold bridge unavailable: $error');
          }),
    );
  }

  void _apply(Object? payload) {
    final features = IOSFoldDisplayFeatures.parse(payload);
    if (!mounted || listEquals(features, _features)) return;
    setState(() => _features = features);
  }

  @override
  void dispose() {
    if (_enabled) {
      IOSFoldDisplayFeatures.channel.setMethodCallHandler(null);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always wrap while enabled: inserting the MediaQuery only once a fold
    // appears would rebuild the subtree and lose its state.
    if (!_enabled) return widget.child;
    final data = MediaQuery.of(context);
    return MediaQuery(
      data: data.copyWith(
        displayFeatures: [...data.displayFeatures, ..._features],
      ),
      child: widget.child,
    );
  }
}
