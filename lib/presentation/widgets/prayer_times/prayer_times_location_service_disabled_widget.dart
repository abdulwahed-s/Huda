import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/action_button.dart';
import 'package:huda/presentation/widgets/prayer_times/error_card.dart';

class PrayerTimesLocationServiceDisabledWidget extends StatelessWidget {
  const PrayerTimesLocationServiceDisabledWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorCard(
      message: AppLocalizations.of(context)!.locationServicesDisabled,
      actions: [
        ActionButton(
          text: AppLocalizations.of(context)!.tryAgain,
          icon: Icons.refresh,
          onPressed: () =>
              context.read<PrayerTimesCubit>().refreshLocationAndPrayerTimes(),
        ),
        SizedBox(width: 8.w),
        ActionButton(
          text: AppLocalizations.of(context)!.openSettings,
          icon: Icons.settings,
          onPressed: () => Geolocator.openLocationSettings(),
        ),
      ],
    );
  }
}
