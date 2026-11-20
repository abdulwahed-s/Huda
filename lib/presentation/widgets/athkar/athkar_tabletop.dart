import 'package:flutter/material.dart';
import 'package:huda/core/layout/tabletop_split.dart';

class AthkarTabletop extends TabletopSplit {
  const AthkarTabletop({super.key, required super.top, required super.bottom});

  static bool applies(BuildContext context) => TabletopSplit.applies(context);
}
