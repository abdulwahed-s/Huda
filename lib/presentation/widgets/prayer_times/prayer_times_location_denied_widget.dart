import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/presentation/widgets/prayer_times/action_button.dart';
import 'package:huda/presentation/widgets/prayer_times/error_card.dart';

class PrayerTimesLocationDeniedWidget extends StatelessWidget {
  const PrayerTimesLocationDeniedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorCard(
      message: "Location permission denied. Please allow location access in your device settings.",
      actions: [
        ActionButton(
          text: "Try Again",
          icon: Icons.refresh,
          onPressed: () => context
              .read<PrayerTimesCubit>()
              .refreshLocationAndPrayerTimes(),
        ),
      ],
    );
  }
}