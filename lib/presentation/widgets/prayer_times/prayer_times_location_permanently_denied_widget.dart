import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/action_button.dart';
import 'package:huda/presentation/widgets/prayer_times/error_card.dart';
import 'package:geolocator/geolocator.dart';
import 'package:huda/presentation/widgets/prayer_times/manual_location_search_dialog.dart';

class PrayerTimesLocationPermanentlyDeniedWidget extends StatelessWidget {
  const PrayerTimesLocationPermanentlyDeniedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorCard(
      message: AppLocalizations.of(context)!.locationPermissionPermanentlyDenied,
      actions: [
        if (!PlatformUtils.isLinux)
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
        SizedBox(width: 8.w),
        ActionButton(
          text: AppLocalizations.of(context)!.tryAgain,
          icon: Icons.refresh,
          onPressed: () =>
              context.read<PrayerTimesCubit>().refreshLocationAndPrayerTimes(),
        ),
        SizedBox(width: 8.w),
        ActionButton(
          text: AppLocalizations.of(context)!.searchManually,
          icon: Icons.search,
          onPressed: () async {
            final result = await showDialog<Map<String, dynamic>>(
              context: context,
              builder: (context) => const ManualLocationSearchDialog(),
            );
            if (result != null &&
                result['lat'] != null &&
                result['lon'] != null) {
              if (context.mounted) {
                context
                    .read<PrayerTimesCubit>()
                    .setManualLocation(result['lat'], result['lon']);
              }
            }
          },
        ),
      ],
    );
  }
}
