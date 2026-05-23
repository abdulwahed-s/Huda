import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/tasbih/control_button.dart';

class TasbihControlsRow extends StatelessWidget {
  final bool isVibrationMode;
  final VoidCallback onDhikrTap;
  final VoidCallback onVibrationToggle;
  final VoidCallback onDecrement;
  final VoidCallback onReset;

  const TasbihControlsRow({
    super.key,
    required this.isVibrationMode,
    required this.onDhikrTap,
    required this.onVibrationToggle,
    required this.onDecrement,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ControlButton(
            icon: Icons.edit_note_rounded,
            label: l10n.dhikr,
            onPressed: onDhikrTap,
            color: context.accentColor,
          ),
          if (PlatformUtils.isMobile)
            ControlButton(
              icon: isVibrationMode ? Icons.vibration : Icons.phone_android,
              label: isVibrationMode ? l10n.vibrate : l10n.silent,
              onPressed: onVibrationToggle,
              color: isVibrationMode ? context.primaryColor : Colors.grey,
            ),
          ControlButton(
            icon: Icons.remove_rounded,
            label: l10n.minus,
            onPressed: onDecrement,
            color: context.primaryColor,
          ),
          ControlButton(
            icon: Icons.refresh_rounded,
            label: l10n.reset,
            onPressed: onReset,
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}
