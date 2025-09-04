// onboarding_pages.dart
import 'package:flutter/material.dart';
import 'package:huda/data/models/onboarding_data.dart';
import 'package:huda/l10n/app_localizations.dart';

List<OnboardingData> getOnboardingPages(BuildContext context) {
  return [
    OnboardingData(
      title: AppLocalizations.of(context)!.onboardingWelcomeTitle,
      description: AppLocalizations.of(context)!.onboardingWelcomeDescription,
      icon: Icons.mosque,
      primaryColor: Colors.teal,
      secondaryColor: Colors.tealAccent,
    ),
    OnboardingData(
      title: AppLocalizations.of(context)!.onboardingQuranTitle,
      description: AppLocalizations.of(context)!.onboardingQuranDescription,
      icon: Icons.menu_book_rounded,
      primaryColor: Colors.green,
      secondaryColor: Colors.greenAccent,
    ),
    OnboardingData(
      title: AppLocalizations.of(context)!.onboardingPrayerTimesTitle,
      description:
          AppLocalizations.of(context)!.onboardingPrayerTimesDescription,
      icon: Icons.access_time_rounded,
      primaryColor: Colors.indigo,
      secondaryColor: Colors.indigoAccent,
    ),
    OnboardingData(
      title: AppLocalizations.of(context)!.onboardingAthkarTitle,
      description: AppLocalizations.of(context)!.onboardingAthkarDescription,
      icon: Icons.favorite_rounded,
      primaryColor: Colors.purple,
      secondaryColor: Colors.purpleAccent,
    ),
    OnboardingData(
      title: AppLocalizations.of(context)!.onboardingBooksTitle,
      description: AppLocalizations.of(context)!.onboardingBooksDescription,
      icon: Icons.library_books_rounded,
      primaryColor: Colors.deepOrange,
      secondaryColor: Colors.deepOrangeAccent,
    ),
    OnboardingData(
      title: AppLocalizations.of(context)!.onboardingHadithTitle,
      description: AppLocalizations.of(context)!.onboardingHadithDescription,
      icon: Icons.menu_book,
      primaryColor: Colors.brown,
      secondaryColor: Colors.brown.shade300,
    ),
    OnboardingData(
      title: AppLocalizations.of(context)!.onboardingAITitle,
      description: AppLocalizations.of(context)!.onboardingAIDescription,
      icon: Icons.smart_toy_rounded,
      primaryColor: Colors.blueGrey,
      secondaryColor: Colors.blueGrey.shade300,
    ),
    OnboardingData(
      title: AppLocalizations.of(context)!.onboardingHijriTitle,
      description: AppLocalizations.of(context)!.onboardingHijriDescription,
      icon: Icons.calendar_month_rounded,
      primaryColor: Colors.pink,
      secondaryColor: Colors.pinkAccent,
    ),
    OnboardingData(
      title: AppLocalizations.of(context)!.onboardingChecklistTitle,
      description: AppLocalizations.of(context)!.onboardingChecklistDescription,
      icon: Icons.check_circle_rounded,
      primaryColor: Colors.red,
      secondaryColor: Colors.redAccent,
    ),
    OnboardingData(
      title: AppLocalizations.of(context)!.onboardingQiblahTitle,
      description: AppLocalizations.of(context)!.onboardingQiblahDescription,
      icon: Icons.navigation_rounded,
      primaryColor: Colors.orange,
      secondaryColor: Colors.orangeAccent,
    ),
    OnboardingData(
      title: AppLocalizations.of(context)!.onboardingMultilingualTitle,
      description:
          AppLocalizations.of(context)!.onboardingMultilingualDescription,
      icon: Icons.language_rounded,
      primaryColor: Colors.cyan,
      secondaryColor: Colors.cyanAccent,
    ),
    OnboardingData(
      title: AppLocalizations.of(context)!.onboardingJourneyTitle,
      description: AppLocalizations.of(context)!.onboardingJourneyDescription,
      icon: Icons.star_rounded,
      primaryColor: Colors.blue,
      secondaryColor: Colors.blueAccent,
    ),
  ];
}
