import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/data/models/quran_model.dart';
import '../../../../core/theme/theme_extension.dart';
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 40.h * (1 - animationController.value)),
          child: Opacity(
            opacity: animationController.value,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              child: Card(
                elevation: isDarkMode ? 6 : 4,
                color: isDarkMode ? Theme.of(context).cardColor : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: onTap,
                  child: Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        // Surah Number Circle
                        _buildSurahNumberCircle(context),
                        SizedBox(width: 12.w),
                        // Surah Details
                        Expanded(
                          child: _buildSurahDetails(context),
                        ),
                        // Ayahs Count and Revelation Badge
                        _buildSurahInfo(context),
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

  Widget _buildSurahNumberCircle(BuildContext context) {
    return Container(
      width: 42.w,
      height: 42.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.primaryColor.withValues(alpha: 0.8),
            context.primaryColor,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withValues(alpha: 0.3),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${surah.number}',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildSurahDetails(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                surah.name ?? '',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontFamily: 'uthmanic',
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontFeatures: const [FontFeature.enable('liga')],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          surah.englishName ?? '',
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          surah.englishNameTranslation ?? '',
          style: TextStyle(
            fontSize: 12.sp,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSurahInfo(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Revelation type badge
        RevelationTypeBadge(revelationType: surah.revelationType!),
        SizedBox(height: 4.h),
        Text(
          '${surah.numberOfAyahs}',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: context.primaryColor,
          ),
        ),
        Text(
          'Ayahs',
          style: TextStyle(
            fontSize: 10.sp,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
