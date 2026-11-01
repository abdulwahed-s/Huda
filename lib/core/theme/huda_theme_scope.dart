import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';

/// Lantern's night for immersive focus screens (counters, Qiblah,
/// players): the dark theme on the deep chrome, in light mode too.
/// Readers (Quran, hadith, books) don't use it; they follow the theme.
///
/// It reads the root theme (`HudaTheme`, set in `app.dart`) and paints the
/// chrome gradient behind [child], so a `Scaffold` inside should keep its
/// default background.
class HudaNight extends StatelessWidget {
  const HudaNight({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final night = context.tokens.night();
    final tokens = night.extension<HudaTokens>()!;
    return Theme(
      data: night,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: tokens.bandGradient),
        child: Theme(
          // The gradient shows through the scaffold.
          data: night.copyWith(scaffoldBackgroundColor: Colors.transparent),
          child: child,
        ),
      ),
    );
  }
}
