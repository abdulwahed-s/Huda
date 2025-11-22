import 'package:flutter/material.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../l10n/app_localizations.dart';

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? context.darkCardBackground
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? context.accentColor.withValues(alpha: 0.2)
              : context.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loop setting
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: loopEnabled
                  ? context.primaryColor.withValues(alpha: 0.1)
                  : (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey[50]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: loopEnabled
                    ? context.primaryColor.withValues(alpha: 0.3)
                    : (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF404040)
                        : Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: loopEnabled,
                    onChanged: onLoopChanged,
                    activeColor: context.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.loopThisAyah,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Autoplay setting
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: autoplayEnabled
                  ? context.primaryColor.withValues(alpha: 0.1)
                  : (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey[50]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: autoplayEnabled
                    ? context.primaryColor.withValues(alpha: 0.3)
                    : (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF404040)
                        : Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: autoplayEnabled,
                    onChanged: onAutoplayChanged,
                    activeColor: context.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.autoplayNextAyah,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
