import 'package:flutter/material.dart';

class AudioSettingsWidget extends StatelessWidget {
  final bool loopEnabled;
  final bool autoplayEnabled;
  final Function(bool?) onLoopChanged;
  final Function(bool?) onAutoplayChanged;

  const AudioSettingsWidget({
    super.key,
    required this.loopEnabled,
    required this.autoplayEnabled,
    required this.onLoopChanged,
    required this.onAutoplayChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Audio Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 103, 43, 93),
          ),
        ),
        const SizedBox(height: 8),

        // Loop setting
        Row(
          children: [
            Checkbox(
              value: loopEnabled,
              onChanged: onLoopChanged,
              activeColor: const Color.fromARGB(255, 103, 43, 93),
            ),
            const Text('Loop this ayah'),
          ],
        ),

        // Autoplay setting
        Row(
          children: [
            Checkbox(
              value: autoplayEnabled,
              onChanged: onAutoplayChanged,
              activeColor: const Color.fromARGB(255, 103, 43, 93),
            ),
            const Text('Autoplay next ayah'),
          ],
        ),
      ],
    );
  }
}
