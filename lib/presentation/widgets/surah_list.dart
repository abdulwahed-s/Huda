import 'package:flutter/material.dart';
import 'package:huda/data/models/quran_model.dart';
import 'surah_card.dart';

class SurahList extends StatelessWidget {
  final List<QuranModel> surahs;
  final AnimationController animationController;
  final Function(QuranModel) onSurahTap;

  const SurahList({
    super.key,
    required this.surahs,
    required this.animationController,
    required this.onSurahTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: surahs.length,
      itemBuilder: (context, index) {
        final surah = surahs[index];
        return SurahCard(
          surah: surah,
          animationController: animationController,
          onTap: () => onSurahTap(surah),
        );
      },
    );
  }
}
