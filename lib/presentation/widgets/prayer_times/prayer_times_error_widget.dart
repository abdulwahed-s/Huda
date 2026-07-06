import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/action_button.dart';
import 'package:huda/presentation/widgets/prayer_times/error_card.dart';
import 'package:huda/presentation/widgets/prayer_times/manual_location_search_dialog.dart';

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
          text: AppLocalizations.of(context)!.tryAgain,
          icon: Icons.refresh,
          onPressed: () =>
              context.read<PrayerTimesCubit>().refreshLocationAndPrayerTimes(),
        ),
        const SizedBox(width: 8),
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
                context.read<PrayerTimesCubit>().setManualLocation(
                      result['lat'],
                      result['lon'],
                      cityName: result['name'],
                    );
              }
            }
          },
        ),
      ],
    );
  }
}
