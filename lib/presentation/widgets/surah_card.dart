import 'package:flutter/material.dart';
import 'package:huda/data/models/quran_model.dart';
import 'revelation_type_badge.dart';

class SurahCard extends StatelessWidget {
  final QuranModel surah;
  final AnimationController animationController;
  final VoidCallback onTap;

  const SurahCard({
    super.key,
    required this.surah,
    required this.animationController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animationController.value)),
          child: Opacity(
            opacity: animationController.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.grey[50]!,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        // Surah Number Circle
                        _buildSurahNumberCircle(),
                        const SizedBox(width: 16),
                        // Surah Details
                        Expanded(
                          child: _buildSurahDetails(),
                        ),
                        // Ayahs Count and Revelation Badge
                        _buildSurahInfo(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSurahNumberCircle() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 103, 43, 93).withOpacity(0.8),
            const Color.fromARGB(255, 103, 43, 93),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 103, 43, 93).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${surah.number}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSurahDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                surah.name ?? '',
                style: const TextStyle(
                  fontSize: 22,
                  fontFamily: 'uthmanic',
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.enable('liga')],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          surah.englishName ?? '',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          surah.englishNameTranslation ?? '',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSurahInfo() {
    return Column(
      children: [
        // Revelation type badge
        RevelationTypeBadge(revelationType: surah.revelationType!),
        const SizedBox(height: 6),
        Text(
          '${surah.numberOfAyahs}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 103, 43, 93),
          ),
        ),
        Text(
          'Ayahs',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
