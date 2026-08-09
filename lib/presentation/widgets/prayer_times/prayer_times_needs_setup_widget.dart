import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/action_button.dart';
import 'package:huda/presentation/widgets/prayer_times/error_card.dart';
import 'package:huda/presentation/widgets/prayer_times/manual_location_search_dialog.dart';

class PrayerTimesNeedsSetupWidget extends StatelessWidget {
  const PrayerTimesNeedsSetupWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ErrorCard(
      message: l10n.prayerSetupRequired,
      actions: [
        ActionButton(
          text: l10n.tryAgain,
          icon: Icons.my_location,
          onPressed: () =>
              context.read<PrayerTimesCubit>().refreshLocationAndPrayerTimes(),
        ),
        const SizedBox(width: 8),
        ActionButton(
          text: l10n.searchManually,
          icon: Icons.search,
          onPressed: () => _searchManually(context),
        ),
      ],
    );
  }

  Future<void> _searchManually(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const ManualLocationSearchDialog(),
    );
    if (!context.mounted || result == null) return;

    final lat = result['lat'];
    final lon = result['lon'];
    if (lat is! num || lon is! num) return;

    await context.read<PrayerTimesCubit>().setManualLocation(
          lat.toDouble(),
          lon.toDouble(),
          cityName: result['name'] as String?,
          countryCode: result['country_code'] as String?,
        );
  }
}
