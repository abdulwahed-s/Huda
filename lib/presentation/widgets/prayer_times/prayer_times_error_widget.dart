import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/action_button.dart';
import 'package:huda/presentation/widgets/prayer_times/error_card.dart';

class PrayerTimesErrorWidget extends StatelessWidget {
  final PrayerTimesError state;
  
  const PrayerTimesErrorWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorCard(
      message: '${AppLocalizations.of(context)!.error}: ${state.message}',
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