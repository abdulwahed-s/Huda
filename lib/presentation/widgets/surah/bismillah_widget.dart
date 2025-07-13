import 'package:flutter/material.dart';

class BismillahWidget extends StatelessWidget {
  const BismillahWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          '﷽',
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 28,
            color: Color.fromARGB(255, 103, 43, 93),
          ),
        ),
      ),
    );
  }
}
