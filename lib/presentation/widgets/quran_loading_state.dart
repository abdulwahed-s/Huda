import 'package:flutter/material.dart';

class QuranLoadingState extends StatelessWidget {
  const QuranLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color.fromARGB(255, 103, 43, 93),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading Quran...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
