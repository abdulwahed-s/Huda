import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/presentation/widgets/prayer_times/persistent_prayer_countdown_control_widget.dart';
import 'package:huda/presentation/widgets/prayer_times/next_prayer_countdown_card_widget.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_times_card_widget.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_times_error_widget.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_times_loaded_widget.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_times_loading_widget.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_times_location_denied_widget.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_times_location_permanently_denied_widget.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_times_location_service_disabled_widget.dart';
import 'package:huda/presentation/widgets/prayer_times/refresh_location_button_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:huda/l10n/app_localizations.dart';

class PrayerTimes extends StatefulWidget {
  const PrayerTimes({super.key});

  @override
  State<PrayerTimes> createState() => _PrayerTimesState();
}

class _PrayerTimesState extends State<PrayerTimes> {
  late PrayerTimesCubit _prayerTimesCubit;

  @override
  void initState() {
    super.initState();
    _prayerTimesCubit = context.read<PrayerTimesCubit>();
    _prayerTimesCubit.setContext(context);
    _prayerTimesCubit.loadPrayerTimes();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    // Request exact alarm permission (Android 12+)
    if (PlatformUtils.isAndroid &&
        await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
        backgroundColor: Colors.transparent,
        title: Text(AppLocalizations.of(context)!.prayerTimes,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              fontFamily: "Amiri",
              color: isDark ? Colors.white : Colors.black87,
            )),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        child: Column(
          children: [
            // Location Card
            Card(
              elevation: 3,
              margin: EdgeInsets.only(bottom: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.primaryColor.withValues(alpha: 0.1),
                      context.primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                padding: EdgeInsets.all(16.w),
                child: BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
                  builder: (context, state) {
                    if (state is PrayerTimesLoading) {
                      return const PrayerTimesLoadingWidget();
                    } else if (state is PrayerTimesLoaded) {
                      return PrayerTimesLoadedWidget(state: state);
                    } else if (state is PrayerTimesLocationServiceDisabled) {
                      return const PrayerTimesLocationServiceDisabledWidget();
                    } else if (state is PrayerTimesLocationDenied) {
                      return const PrayerTimesLocationDeniedWidget();
                    } else if (state is PrayerTimesLocationPermanentlyDenied) {
                      return const PrayerTimesLocationPermanentlyDeniedWidget();
                    } else if (state is PrayerTimesError) {
                      return PrayerTimesErrorWidget(state: state);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),

            // Prayer Times Card
            BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
              builder: (context, state) {
                if (state is PrayerTimesLoaded) {
                  return PrayerTimesCardWidget(state: state);
                }
                return const SizedBox.shrink();
              },
            ),

// Next Prayer Countdown Card
            BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
              builder: (context, state) {
                if (state is PrayerTimesLoaded) {
                  return NextPrayerCountdownCardWidget(
                    state: state,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  );
                }
                return const SizedBox.shrink();
              },
            ),

// Refresh Button
            const RefreshLocationButtonWidget(),

// Persistent Prayer Countdown Control Widget
            if (PlatformUtils.isMobile)
              const PersistentPrayerCountdownControlWidget(),
          ],
        ),
      ),
    );
  }
}
