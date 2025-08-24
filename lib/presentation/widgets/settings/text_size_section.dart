import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/settings/preset_buttons_and_reset.dart';
import 'package:huda/presentation/widgets/settings/settings_card.dart';
import 'package:huda/presentation/widgets/settings/text_preview.dart';
import 'package:huda/presentation/widgets/settings/text_size_header.dart';
import 'package:huda/presentation/widgets/settings/text_size_slider.dart';

class TextSizeSection extends StatelessWidget {
  final bool isDark;

  const TextSizeSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextSizeHeader(isDark: isDark),
          SizedBox(height: 24.h),
          TextPreview(isDark: isDark),
          SizedBox(height: 20.h),
          const TextSizeSlider(),
          SizedBox(height: 16.h),
          const PresetButtonsAndReset(),
        ],
      ),
    );
  }
}
