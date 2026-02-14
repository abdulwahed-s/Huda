import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/presentation/widgets/prayer_times/action_button.dart';
import 'package:huda/presentation/widgets/prayer_times/error_card.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';

class PrayerTimesLocationDeniedWidget extends StatelessWidget {
  const PrayerTimesLocationDeniedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorCard(
      message:
          "Location permission denied. Please allow location access in your device settings.",
      actions: [
        ActionButton(
          text: AppLocalizations.of(context)!.openSettings,
          icon: Icons.settings,
          onPressed: () async {
            if (await Geolocator.openLocationSettings()) {
              return;
            }
            await Geolocator.openAppSettings();
          },
        ),
        const SizedBox(width: 8),
        ActionButton(
          text: AppLocalizations.of(context)!.tryAgain,
          icon: Icons.refresh,
          onPressed: () =>
              context.read<PrayerTimesCubit>().refreshLocationAndPrayerTimes(),
        ),
      ],
    );
  }
}
