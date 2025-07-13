import 'package:flutter/material.dart';

class SurahLoadingStateWidget extends StatelessWidget {
  const SurahLoadingStateWidget({super.key});

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
            'Loading Surah...',
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
