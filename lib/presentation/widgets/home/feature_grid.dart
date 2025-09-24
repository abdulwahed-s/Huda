import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'feature_card.dart';

class FeatureGrid extends StatelessWidget {
  final bool isDarkMode;
  final List<FeatureItem> features;

  const FeatureGrid({
    super.key,
    required this.isDarkMode,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaler.scale(1.0);
    final adjustedAspectRatio =
        (0.65 / (textScaleFactor * 0.8)).clamp(0.45, 0.75);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: adjustedAspectRatio,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return FeatureCard(
          title: feature.title,
          svgAsset: feature.svgAsset,
          icon: feature.icon,
          onTap: () {
            feature.onTap();
          },
          isDarkMode: isDarkMode,
          index: index,
        );
      },
    );
  }
}

class FeatureItem {
  final String title;
  final String? svgAsset;
  final IconData? icon;
  final VoidCallback onTap;

  FeatureItem({
    required this.title,
    this.svgAsset,
    this.icon,
    required this.onTap,
  });
}