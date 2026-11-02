import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/theme/huda_system_ui.dart';
import 'package:huda/core/theme/huda_tokens.dart';

/// The page above a pinned audio bar: [child] fills the room the [bar]
/// leaves, and while the bar shows it owns the bottom edge (its surface
/// runs to the screen edge and lifts its content by the inset), so the
/// page's scroll views stop adding the inset themselves. The bar rises in
/// and out with the shared motion. Shared by the Quran player, the radio and the
/// audiobooks player (moved from `quran_player/` in `audiobooks`).
class HudaAudioDock extends StatelessWidget {
  const HudaAudioDock({
    super.key,
    required this.child,
    required this.bar,
    required this.visible,
  });

  final Widget child;
  final Widget bar;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final motion = context.tokens.motion;
    final duration = motion.of(context, motion.medium);
    final shown = visible
        ? AnnotatedRegion<SystemUiOverlayStyle>(
            // The bar is night chrome: light navigation icons over it.
            value: HudaSystemUi.over(
              top: Theme.of(context).brightness,
              bottom: Brightness.dark,
            ),
            child: bar,
          )
        : const SizedBox(width: double.infinity);
    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: visible,
            child: child,
          ),
        ),
        // A zero-length AnimatedSize throws when its child changes size
        // (found by `tasbih`): swap instantly under reduce motion.
        if (duration == Duration.zero)
          shown
        else
          ClipRect(
            child: AnimatedSize(
              duration: duration,
              curve: motion.standard,
              alignment: Alignment.topCenter,
              child: shown,
            ),
          ),
      ],
    );
  }
}
