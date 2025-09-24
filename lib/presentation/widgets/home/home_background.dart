import 'package:flutter/material.dart';

class HomeBackground extends StatelessWidget {
  final bool isDarkMode;
  final Widget child;

  const HomeBackground({
    super.key,
    required this.isDarkMode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [
                  const Color(0xFF0B0F14),
                  const Color(0xFF0E141B),
                ]
              : [
                  const Color(0xFFF7FAFF),
                  const Color(0xFFFFFFFF),
                ],
        ),
      ),
      child: child,
    );
  }
}
