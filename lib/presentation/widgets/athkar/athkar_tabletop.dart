import 'package:flutter/material.dart';
import 'package:huda/core/layout/tabletop_split.dart';

/// Athkar's tabletop halves: the shared [TabletopSplit] (moved there in
/// `hadith`, so both features split the same way).
class AthkarTabletop extends TabletopSplit {
  const AthkarTabletop({super.key, required super.top, required super.bottom});

  /// Whether the window is in tabletop posture.
  static bool applies(BuildContext context) => TabletopSplit.applies(context);
}
