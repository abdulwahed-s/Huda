import 'package:flutter/material.dart';

class MemorizationStopFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const MemorizationStopFab({
    super.key,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: Colors.red,
      icon: const Icon(Icons.stop_rounded, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
