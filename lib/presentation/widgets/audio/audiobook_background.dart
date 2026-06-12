import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:huda/core/theme/theme_extension.dart';

class AudiobookBackground extends StatelessWidget {
  final String? artUrl;
  final bool isDark;

  const AudiobookBackground({
    super.key,
    required this.artUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (artUrl != null && artUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            artUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _GradientBackground(isDark: isDark),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: const SizedBox.expand(),
          ),
          Container(
            color: (isDark ? Colors.black : Colors.white)
                .withValues(alpha: isDark ? 0.62 : 0.72),
          ),
          Container(
            color: context.primaryColor.withValues(alpha: isDark ? 0.14 : 0.07),
          ),
        ],
      );
    }
    return _GradientBackground(isDark: isDark);
  }
}

class _GradientBackground extends StatelessWidget {
  final bool isDark;

  const _GradientBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (isDark) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.darkGradientStart,
              context.darkGradientMid,
              context.darkGradientEnd,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.primaryColor.withValues(alpha: 0.10),
            context.lightSurface,
          ],
        ),
      ),
    );
  }
}
