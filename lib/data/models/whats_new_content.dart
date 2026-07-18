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
    '3.0.0': WhatsNewContent(
      version: '3.0.0',
      title: (context) => AppLocalizations.of(context)!.whatsNewTitle,
      features: [
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew300Feature1,
          icon: Icons.find_in_page_outlined,
        ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew300Feature2,
          icon: Icons.menu_book_outlined,
        ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew300Feature3,
          icon: Icons.auto_stories_outlined,
        ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew300Feature4,
          icon: Icons.headphones_outlined,
        ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew300Feature5,
          icon: Icons.radio_outlined,
        ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew300Feature6,
          icon: Icons.access_time_outlined,
        ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew300Feature7,
          icon: Icons.auto_awesome_outlined,
        ),
      ],
      buttonText: (context) => AppLocalizations.of(context)!.gotIt,
    ),
    '3.1.0': WhatsNewContent(
      version: '3.1.0',
      title: (context) => AppLocalizations.of(context)!.whatsNewTitle,
      features: [
        if (PlatformUtils.isIOS)
          WhatsNewFeature(
            title: (context) =>
                AppLocalizations.of(context)!.whatsNew310Feature1iOS,
            icon: Icons.access_time_outlined,
          ),
        if (PlatformUtils.isAndroid)
          WhatsNewFeature(
            title: (context) =>
                AppLocalizations.of(context)!.whatsNew310Feature1Android,
            icon: Icons.access_time_outlined,
          ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew310Feature2,
          icon: Icons.auto_awesome_outlined,
        ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew310Feature3,
          icon: Icons.bug_report_outlined,
        ),
      ],
      buttonText: (context) => AppLocalizations.of(context)!.gotIt,
    ),
    '3.3.0': WhatsNewContent(
      version: '3.3.0',
      title: (context) => AppLocalizations.of(context)!.whatsNewTitle,
      features: [
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew330Feature1,
          icon: Icons.menu_book_outlined,
        ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew330Feature2,
          icon: Icons.bug_report_outlined,
        ),
      ],
      buttonText: (context) => AppLocalizations.of(context)!.gotIt,
    ),
    '3.4.0': WhatsNewContent(
      version: '3.4.0',
      title: (context) => AppLocalizations.of(context)!.whatsNewTitle,
      features: [
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew340Feature1,
          icon: Icons.headphones_outlined,
        ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew340Feature2,
          icon: Icons.play_circle_outlined,
        ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew340Feature3,
          icon: Icons.menu_book_outlined,
        ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew340Feature4,
          icon: Icons.bug_report_outlined,
        ),
      ],
      buttonText: (context) => AppLocalizations.of(context)!.gotIt,
    ),
    '3.5.0': WhatsNewContent(
      version: '3.5.0',
      title: (context) => AppLocalizations.of(context)!.whatsNewTitle,
      features: [
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew350Feature1,
          icon: Icons.text_fields_outlined,
        ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew350Feature3,
          icon: Icons.auto_awesome_outlined,
        ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew350Feature2,
          icon: Icons.bug_report_outlined,
        ),
      ],
      buttonText: (context) => AppLocalizations.of(context)!.gotIt,
    ),
    '3.7.0': WhatsNewContent(
      version: '3.7.0',
      title: (context) => AppLocalizations.of(context)!.whatsNewTitle,
      features: [
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew370Feature1,
          icon: Icons.access_time_outlined,
        ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew370Feature2,
          icon: Icons.explore_outlined,
        ),
        WhatsNewFeature(
          title: (context) => AppLocalizations.of(context)!.whatsNew370Feature3,
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
