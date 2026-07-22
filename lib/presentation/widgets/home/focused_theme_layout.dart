import 'package:flutter/material.dart';

const double focusedThemeContentMaxWidth = 1120;

class FocusedThemeContentFrame extends StatelessWidget {
  const FocusedThemeContentFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: focusedThemeContentMaxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
