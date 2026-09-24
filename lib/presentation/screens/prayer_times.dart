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
import 'package:huda/presentation/widgets/prayer_times/prayer_times_loading_widget.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_times_location_denied_widget.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_times_location_permanently_denied_widget.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_times_location_service_disabled_widget.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_times_needs_setup_widget.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_travel_settings_card.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/notifications/notification_requirements_section.dart';
import 'package:huda/presentation/widgets/notifications/permission_handlers.dart';
import 'package:permission_handler/permission_handler.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preparePrayerTimes();
    });
  }

  Future<void> _preparePrayerTimes() async {
    if (!mounted) return;

    if (PlatformUtils.isAndroid || PlatformUtils.isIOS) {
      final notificationStatus = await Permission.notification.status;
      if (!mounted) return;
      if (notificationStatus.isDenied) {
        await PermissionHandlers.requestNotificationPermission(context);
      }
    }

    if (!mounted) return;
    _prayerTimesCubit.loadCachedPrayerTimes();
    final state = _prayerTimesCubit.state;
    if (state is PrayerTimesLoaded ||
        state is PrayerTimesLoading ||
        state is PrayerTimesLocationDenied ||
        state is PrayerTimesLocationPermanentlyDenied ||
        state is PrayerTimesLocationServiceDisabled ||
        state is PrayerTimesError) {
      return;
    }

    // Initial/NeedsSetup is the only automatic location attempt. Once an
    // attempt fails, retries are user-initiated from the visible action card.
    await _prayerTimesCubit.loadPrayerTimes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      _prayerTimesCubit.setLocalizations(localizations);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          title: Text(
            AppLocalizations.of(context)!.prayerTimes,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator.adaptive(
          onRefresh: _prayerTimesCubit.refreshLocationAndPrayerTimes,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        children: [
                          NotificationRequirementsSection(
                            feature: NotificationFeature.prayerTimes,
                            onNotificationEnabled:
                                _prayerTimesCubit.refreshNotificationSchedule,
                            bottomSpacing: 12.h,
                          ),
                          BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
                            builder: (context, state) => AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: KeyedSubtree(
                                key: ValueKey(state.runtimeType),
                                child: _buildStateContent(context, state),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent(BuildContext context, PrayerTimesState state) {
    if (state is PrayerTimesLoaded) {
      return Column(
        children: [
          _PrayerLocationSummary(
            state: state,
            locationMode: _prayerTimesCubit.locationMode,
            onRefresh: _prayerTimesCubit.refreshLocationAndPrayerTimes,
          ),
          NextPrayerCountdownCardWidget(
            state: state,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          PrayerTimesCardWidget(state: state),
          PrayerTravelSettingsCard(
            locationMode: _prayerTimesCubit.locationMode,
          ),
          if (PlatformUtils.isAndroid)
            const PersistentPrayerCountdownControlWidget(),
        ],
      );
    }

    final child = switch (state) {
      PrayerTimesInitial() ||
      PrayerTimesLoading() => const PrayerTimesLoadingWidget(),
      PrayerTimesLocationServiceDisabled() =>
        const PrayerTimesLocationServiceDisabledWidget(),
      PrayerTimesLocationDenied() => const PrayerTimesLocationDeniedWidget(),
      PrayerTimesLocationPermanentlyDenied() =>
        const PrayerTimesLocationPermanentlyDeniedWidget(),
      PrayerTimesNeedsSetup() => const PrayerTimesNeedsSetupWidget(),
      PrayerTimesError() => PrayerTimesErrorWidget(state: state),
      _ => const SizedBox.shrink(),
    };

    return _PrayerStateCard(child: child);
  }
}

class _PrayerStateCard extends StatelessWidget {
  const _PrayerStateCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = context.primaryColor;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: primary.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PrayerLocationSummary extends StatelessWidget {
  const _PrayerLocationSummary({
    required this.state,
    required this.locationMode,
    required this.onRefresh,
  });

  final PrayerTimesLoaded state;
  final PrayerLocationMode locationMode;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final primary = context.primaryColor;
    final location = _locationName(l10n);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsetsDirectional.fromSTEB(14.w, 12.h, 8.w, 12.h),
      decoration: BoxDecoration(
        color: primary.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.14 : 0.07,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.location_on_rounded, color: primary, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.location,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(99.r),
                      ),
                      child: Text(
                        locationMode == PrayerLocationMode.automatic
                            ? l10n.automatic
                            : l10n.manual,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  location,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            tooltip: l10n.refreshLocation,
            icon: const Icon(Icons.refresh_rounded),
            color: primary,
          ),
        ],
      ),
    );
  }

  String _locationName(AppLocalizations l10n) {
    if (state.placemarks.isEmpty) return l10n.unknown;
    final place = state.placemarks.first;
    final parts = <String?>[
      place.locality,
      place.country,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();
    return parts.isEmpty ? l10n.unknown : parts.join(', ');
  }
}
