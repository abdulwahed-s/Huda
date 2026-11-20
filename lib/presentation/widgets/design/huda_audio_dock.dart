import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/theme/huda_system_ui.dart';
import 'package:huda/core/theme/huda_tokens.dart';

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
