import 'package:flutter/material.dart';

class ForwardArrowIcon extends StatelessWidget {
  final bool isDark;

  const ForwardArrowIcon({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.arrow_forward_ios,
      size: 16,
      color: isDark ? Colors.white54 : Colors.grey[400],
    );
  }
}
