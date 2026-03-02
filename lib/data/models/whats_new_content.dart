import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/utils/platform_utils.dart';

class WhatsNewFeature {
  final String Function(BuildContext) title;
  final IconData icon;

  const WhatsNewFeature({
    required this.title,
    required this.icon,
  });
}

class WhatsNewContent {
  final String version;
  final String Function(BuildContext) title;
  final List<WhatsNewFeature> features;
  final String Function(BuildContext) buttonText;

  const WhatsNewContent({
    required this.version,
    required this.title,
    required this.features,
    required this.buttonText,
  });

  static final Map<String, WhatsNewContent> _versionContent = {
    '1.5.3': WhatsNewContent(
      version: '1.5.3',
      title: (context) => AppLocalizations.of(context)!.whatsNewTitle,
      features: [
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew153Feature1,
          icon: Icons.nightlight_round,
        ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew153Feature2,
          icon: Icons.shield_outlined,
        ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew153Feature3,
          icon: Icons.checklist_rounded,
        ),
      ],
      buttonText: (context) =>
          AppLocalizations.of(context)!.whatsNewExploreButton,
    ),
    '2.0.0': WhatsNewContent(
      version: '2.0.0',
      title: (context) => AppLocalizations.of(context)!.whatsNewTitle,
      features: [
        if (PlatformUtils.isMobile)
          WhatsNewFeature(
            title: (context) =>
                AppLocalizations.of(context)!.whatsNew200Feature1,
            icon: Icons.app_blocking_outlined,
          ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew200Feature2,
          icon: Icons.edit_calendar_outlined,
        ),
        if (PlatformUtils.isMobile)
          WhatsNewFeature(
            title: (context) =>
                AppLocalizations.of(context)!.whatsNew200Feature3,
            icon: Icons.alarm_on_outlined,
          ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew200Feature4,
          icon: Icons.auto_awesome_outlined,
        ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew200Feature5,
          icon: Icons.bug_report_outlined,
        ),
      ],
      buttonText: (context) => AppLocalizations.of(context)!.gotIt,
    ),
  };

  static WhatsNewContent? getForVersion(String version) {
    return _versionContent[version];
  }
}
