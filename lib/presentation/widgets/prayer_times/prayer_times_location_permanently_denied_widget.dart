import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/action_button.dart';
import 'package:huda/presentation/widgets/prayer_times/error_card.dart';
import 'package:permission_handler/permission_handler.dart';

class PrayerTimesLocationPermanentlyDeniedWidget extends StatelessWidget {
  const PrayerTimesLocationPermanentlyDeniedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorCard(
      message:
          "Location permission permanently denied. Please allow location access in your device settings.",
      actions: [
        ActionButton(
          text: AppLocalizations.of(context)!.openSettings,
          icon: Icons.settings,
          onPressed: () => openAppSettings(),
        ),
        SizedBox(width: 8.w),
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
