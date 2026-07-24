import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:huda/presentation/widgets/home/focused_theme_layout.dart';
import 'package:huda/presentation/widgets/home/shared/home_section_widgets.dart';
import 'package:huda/presentation/widgets/home/themes/prayer_today/prayer_focus_dashboard.dart';
import 'package:huda/presentation/widgets/home/themes/prayer_today/prayer_special_event_ribbon.dart';
import 'package:huda/presentation/widgets/home/themes/prayer_today/prayer_supporting_tools.dart';
import 'package:huda/presentation/widgets/home/themes/prayer_today/prayer_today_header.dart';
import 'package:huda/presentation/widgets/home/themes/prayer_today/prayer_today_motion.dart';
import 'package:huda/presentation/widgets/home/themes/prayer_today/prayer_today_visual_style.dart';

class PrayerTodayHome extends StatefulWidget {
  const PrayerTodayHome({
    super.key,
    required this.configuration,
    required this.features,
    required this.actions,
    required this.isDark,
    required this.openLastReadSurah,
    required this.openLastReciterAudio,
    required this.openLastRadioStation,
    required this.onCustomize,
  });

  final HomeThemeConfiguration configuration;
  final List<HomeFeatureDefinition> features;
  final HomeDashboardActions actions;
  final bool isDark;
  final Function(Map<String, dynamic>) openLastReadSurah;
  final Function(dynamic) openLastReciterAudio;
  final Function(dynamic) openLastRadioStation;
  final VoidCallback onCustomize;

  @override
  State<PrayerTodayHome> createState() => _PrayerTodayHomeState();
}

class _PrayerTodayHomeState extends State<PrayerTodayHome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  bool _entranceStarted = false;
  bool _entranceScheduled = false;
  bool _reduceMotion = false;
  bool _tickerEnabled = true;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: PrayerTodayMotion.entrance,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    if (_reduceMotion) {
      _entranceController.value = 1;
      _entranceStarted = true;
      return;
    }
    if (!_entranceStarted && _tickerEnabled) {
      _scheduleEntranceAfterFirstPaint();
    }
  }

  void _scheduleEntranceAfterFirstPaint() {
    if (_entranceStarted || _entranceScheduled) return;
    _entranceScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceScheduled = false;
      if (!mounted || _entranceStarted) return;
      if (_reduceMotion) {
        _entranceController.value = 1;
        _entranceStarted = true;
        return;
      }
      if (!_tickerEnabled) return;

      _entranceStarted = true;
      _entranceController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('prayer-today-wide-shell'),
      decoration: PrayerTodayVisualStyle.toolsSurface(context, widget.isDark),
      child: Column(
        key: const ValueKey('prayer-today-root'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrayerFocusDashboard(
            entranceAnimation: _entranceController,
            isDark: widget.isDark,
            onOpenPrayerTimes: widget.actions.openPrayerTimes,
            header: PrayerTodayHeaderSection(
              entranceAnimation: _entranceController,
              onCustomize: widget.onCustomize,
            ),
            event: PrayerTodayMotionReveal(
              key: const ValueKey('prayer-special-event-reveal'),
              animation: _entranceController,
              begin: 0.08,
              end: 0.34,
              distance: 4,
              beginScale: 0.996,
              child: ActiveIslamicEventBuilder(
                isDark: widget.isDark,
                builder: (context, presentation, onActivate) =>
                    PrayerSpecialEventRibbon(
                  presentation: presentation,
                  onActivate: onActivate,
                ),
              ),
            ),
          ),
          AnnotatedRegion<SystemUiOverlayStyle>(
            key: const ValueKey('prayer-home-surface-overlay'),
            value: (widget.isDark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark)
                .copyWith(
              statusBarColor: Colors.transparent,
              systemStatusBarContrastEnforced: false,
            ),
            child: FocusedThemeContentFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
                    child: PrayerSupportingTools(
                      entranceAnimation: _entranceController,
                      configuration: widget.configuration,
                      features: widget.features,
                      actions: widget.actions,
                      isDark: widget.isDark,
                      openLastReadSurah: widget.openLastReadSurah,
                      openLastReciterAudio: widget.openLastReciterAudio,
                      openLastRadioStation: widget.openLastRadioStation,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
