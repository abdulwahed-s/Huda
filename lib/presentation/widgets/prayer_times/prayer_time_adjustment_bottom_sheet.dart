import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:huda/core/services/persistent_prayer_countdown_service.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/core/utils/text_utils.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:vector_graphics/vector_graphics.dart';

class PrayerTimeAdjustmentBottomSheet extends StatefulWidget {
  const PrayerTimeAdjustmentBottomSheet({super.key});

  @override
  State<PrayerTimeAdjustmentBottomSheet> createState() =>
      _PrayerTimeAdjustmentBottomSheetState();
}

class _PrayerTimeAdjustmentBottomSheetState
    extends State<PrayerTimeAdjustmentBottomSheet> {
  static const List<String> _highLatitudeTokens = [
    'automatic',
    'none',
    'middleOfTheNight',
    'seventhOfTheNight',
    'twilightAngle',
  ];

  late Map<String, int> _offsets;
  late String _methodToken;
  late String _madhabToken;
  late String _highLatToken;
  late String _countryCode;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<PrayerTimesCubit>();
    _offsets = Map.from(cubit.prayerOffsets);
    _methodToken = cubit.calculationMethodToken;
    _madhabToken = cubit.madhabToken;
    _highLatToken = cubit.highLatitudeRuleToken;
    _countryCode =
        PrayerTimesCalculator.countryCodeFromCache(cubit.cacheHelper);
  }


  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  String _methodLabel(String token) {
    final l10n = _l10n;
    switch (token) {
      case PrayerTimesCalculator.autoMethodToken:
        return l10n.prayerMethodAuto;
      case 'ummAlQura':
        return l10n.prayerMethodUmmAlQura;
      case 'muslimWorldLeague':
        return l10n.prayerMethodMuslimWorldLeague;
      case 'egyptian':
        return l10n.prayerMethodEgyptian;
      case 'karachi':
        return l10n.prayerMethodKarachi;
      case 'northAmerica':
        return l10n.prayerMethodNorthAmerica;
      case 'emirates':
        return l10n.prayerMethodEmirates;
      case 'dubai':
        return l10n.prayerMethodDubai;
      case 'qatar':
        return l10n.prayerMethodQatar;
      case 'kuwait':
        return l10n.prayerMethodKuwait;
      case 'oman':
        return l10n.prayerMethodOman;
      case 'omanMuscat':
        return l10n.prayerMethodOmanMuscat;
      case 'jordan':
        return l10n.prayerMethodJordan;
      case 'palestine':
        return l10n.prayerMethodPalestine;
      case 'syria':
        return l10n.prayerMethodSyria;
      case 'iraq':
        return l10n.prayerMethodIraq;
      case 'morocco':
        return l10n.prayerMethodMorocco;
      case 'azrou':
        return l10n.prayerMethodAzrou;
      case 'algeria':
        return l10n.prayerMethodAlgeria;
      case 'tunisia':
        return l10n.prayerMethodTunisia;
      case 'libya':
        return l10n.prayerMethodLibya;
      case 'sudan':
        return l10n.prayerMethodSudan;
      case 'turkey':
        return l10n.prayerMethodTurkey;
      case 'malaysia':
        return l10n.prayerMethodMalaysia;
      case 'malaysia2':
        return l10n.prayerMethodMalaysia2;
      case 'indonesia':
        return l10n.prayerMethodIndonesia;
      case 'kazakhstan':
        return l10n.prayerMethodKazakhstan;
      case 'tajikistan':
        return l10n.prayerMethodTajikistan;
      case 'maldives':
        return l10n.prayerMethodMaldives;
      case 'southKorea':
        return l10n.prayerMethodSouthKorea;
      case 'uoif':
        return l10n.prayerMethodUoif;
      case 'paris':
        return l10n.prayerMethodParis;
      case 'toulouse':
        return l10n.prayerMethodToulouse;
      case 'lyon':
        return l10n.prayerMethodLyon;
      case 'orleans':
        return l10n.prayerMethodOrleans;
      case 'moscow':
        return l10n.prayerMethodMoscow;
      case 'czech':
        return l10n.prayerMethodCzech;
      case 'switzerland':
        return l10n.prayerMethodSwitzerland;
      case 'fribourg':
        return l10n.prayerMethodFribourg;
      case 'belgium':
        return l10n.prayerMethodBelgium;
      case 'luxembourg':
        return l10n.prayerMethodLuxembourg;
      case 'austria':
        return l10n.prayerMethodAustria;
      case 'london':
        return l10n.prayerMethodLondon;
      case 'birmingham':
        return l10n.prayerMethodBirmingham;
      case 'blackburn':
        return l10n.prayerMethodBlackburn;
      case 'aachen':
        return l10n.prayerMethodAachen;
      case 'munchen':
        return l10n.prayerMethodMunchen;
      case 'potsdam':
        return l10n.prayerMethodPotsdam;
      case 'nurnberg':
        return l10n.prayerMethodNurnberg;
      case 'rotterdam':
        return l10n.prayerMethodRotterdam;
      case 'dordrecht':
        return l10n.prayerMethodDordrecht;
      case 'eindhoven':
        return l10n.prayerMethodEindhoven;
      case 'montreal':
        return l10n.prayerMethodMontreal;
      case 'windsor':
        return l10n.prayerMethodWindsor;
      case 'calgary':
        return l10n.prayerMethodCalgary;
      case 'mississauga':
        return l10n.prayerMethodMississauga;
      case 'other':
        return l10n.prayerMethodOther;
      default:
        return token;
    }
  }

  String _highLatLabel(String token) {
    final l10n = _l10n;
    switch (token) {
      case 'automatic':
        return l10n.automatic;
      case 'middleOfTheNight':
        return l10n.prayerHighLatitudeMiddleOfTheNight;
      case 'seventhOfTheNight':
        return l10n.prayerHighLatitudeSeventhOfTheNight;
      case 'twilightAngle':
        return l10n.prayerHighLatitudeTwilightAngle;
      case 'none':
      default:
        return l10n.prayerHighLatitudeNone;
    }
  }

  String _methodDisplayLabel(String token) {
    if (token != PrayerTimesCalculator.autoMethodToken) {
      return _methodLabel(token);
    }

    final resolvedMethod = PrayerTimesCalculator.resolveMethod(
      token,
      _countryCode,
    );
    final autoLabel = _methodLabel(PrayerTimesCalculator.autoMethodToken);
    final prefix = autoLabel.split('(').first.trim();
    return '$prefix (${_methodLabel(resolvedMethod.name)})';
  }

  String _offsetLabel(int offset) {
    if (offset == 0) return '0';
    return offset > 0 ? '+$offset' : '$offset';
  }

  void _increment(String key) {
    setState(() => _offsets[key] = (_offsets[key] ?? 0) + 1);
  }

  void _decrement(String key) {
    setState(() => _offsets[key] = (_offsets[key] ?? 0) - 1);
  }

  void _reset() {
    setState(() {
      _methodToken = PrayerTimesCalculator.defaultMethodToken;
      _madhabToken = PrayerTimesCalculator.defaultMadhabToken;
      _highLatToken = PrayerTimesCalculator.defaultHighLatitudeToken;
      _offsets = PrayerTimesCalculator.zeroOffsets();
    });
  }

  Future<void> _apply() async {
    final cubit = context.read<PrayerTimesCubit>();
    await cubit.savePrayerSettings(
      methodToken: _methodToken,
      madhabToken: _madhabToken,
      highLatToken: _highLatToken,
      offsets: _offsets,
    );

    if (PlatformUtils.isAndroid) {
      final service = PersistentPrayerCountdownService();
      if (service.isRunning) {
        await service.restart();
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.appColors;
    final state = context.read<PrayerTimesCubit>().state;
    final locale = Localizations.localeOf(context).toString();

    final bgColor = isDark ? colors.darkGradientMid : colors.lightSurface;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28.r),
            topRight: Radius.circular(28.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
              blurRadius: 28,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(colors),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSettingsCard(
                      isDark: isDark,
                      colors: colors,
                      children: [
                        _buildSectionHeader(
                          l10n.prayerCalculationMethod,
                          Icons.public_rounded,
                          isDark,
                          colors,
                        ),
                        SizedBox(height: 8.h),
                        _buildMethodDropdown(isDark, colors),
                        SizedBox(height: 16.h),
                        _buildSectionHeader(
                          l10n.prayerAsrMethod,
                          Icons.balance_rounded,
                          isDark,
                          colors,
                        ),
                        SizedBox(height: 8.h),
                        _buildMadhabToggle(isDark, colors),
                        SizedBox(height: 16.h),
                        _buildSectionHeader(
                          l10n.prayerHighLatitudeRule,
                          Icons.travel_explore_rounded,
                          isDark,
                          colors,
                        ),
                        SizedBox(height: 8.h),
                        _buildHighLatDropdown(isDark, colors),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    _buildSettingsCard(
                      isDark: isDark,
                      colors: colors,
                      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 8.h),
                      children: [
                        _buildSectionHeader(
                          l10n.prayerTimeAdjustment,
                          Icons.schedule_rounded,
                          isDark,
                          colors,
                          trailing: _buildAdjustmentSummary(isDark, colors),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          l10n.prayerAdjustmentSubtitle,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            height: 1.3,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        _buildOffsetList(state, locale, isDark, colors),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildFooter(isDark, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorScheme colors) {
    final l10n = _l10n;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryDark, colors.primary, colors.accent],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.r),
          topRight: Radius.circular(28.r),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 14.h),
      child: Column(
        children: [
          Container(
            width: 42.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 12.h),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.prayerSettingsTitle,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.prayerSettingsSubtitle,
              style: TextStyle(
                fontSize: 11.5.sp,
                height: 1.25,
                color: Colors.white.withValues(alpha: 0.74),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required bool isDark,
    required AppColorScheme colors,
    required List<Widget> children,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark
            ? colors.darkCardBackground.withValues(alpha: 0.74)
            : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : colors.primaryExtraLight.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    bool isDark,
    AppColorScheme colors, {
    Widget? trailing,
  }) {
    return Row(
      children: [
        _IconBadge(icon: icon, colors: colors, isDark: isDark),
        SizedBox(width: 9.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? colors.darkText : colors.primaryDark,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  BoxDecoration _fieldDecoration(bool isDark, AppColorScheme colors) {
    return BoxDecoration(
      color: isDark
          ? colors.darkGradientMid.withValues(alpha: 0.6)
          : colors.primaryExtraLight.withValues(alpha: 0.32),
      borderRadius: BorderRadius.circular(14.r),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : colors.primaryExtraLight,
        width: 1,
      ),
    );
  }

  Widget _buildAdjustmentSummary(bool isDark, AppColorScheme colors) {
    final adjustedCount = _offsets.values.where((offset) => offset != 0).length;
    if (adjustedCount == 0) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: colors.accent.withValues(alpha: isDark ? 0.34 : 0.22),
        ),
      ),
      child: Text(
        adjustedCount.toString(),
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          color: isDark ? colors.primaryLight : colors.primary,
        ),
      ),
    );
  }

  Widget _buildMethodDropdown(bool isDark, AppColorScheme colors) {
    return _SelectionField(
      value: _methodDisplayLabel(_methodToken),
      icon: Icons.public_rounded,
      colors: colors,
      isDark: isDark,
      onTap: () => _openMethodPicker(isDark, colors),
    );
  }

  Widget _buildHighLatDropdown(bool isDark, AppColorScheme colors) {
    final selectedToken = _highLatitudeTokens.contains(_highLatToken)
        ? _highLatToken
        : PrayerTimesCalculator.defaultHighLatitudeToken;

    return _SelectionField(
      value: _highLatLabel(selectedToken),
      icon: Icons.travel_explore_rounded,
      colors: colors,
      isDark: isDark,
      onTap: () => _openHighLatitudePicker(isDark, colors),
    );
  }

  Future<void> _openMethodPicker(
    bool isDark,
    AppColorScheme colors,
  ) async {
    final l10n = _l10n;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectionPickerSheet(
        title: l10n.prayerCalculationMethod,
        selectedToken: _methodToken,
        options: [
          for (final token in PrayerTimesCalculator.pickerMethodTokens)
            _SelectionOption(
              token: token,
              label: _methodDisplayLabel(token),
              icon: token == PrayerTimesCalculator.autoMethodToken
                  ? Icons.my_location_rounded
                  : Icons.public_rounded,
            ),
        ],
        colors: colors,
        isDark: isDark,
        searchable: true,
        searchHint: l10n.searchHint,
      ),
    );

    if (!mounted || picked == null) return;
    setState(() => _methodToken = picked);
  }

  Future<void> _openHighLatitudePicker(
    bool isDark,
    AppColorScheme colors,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectionPickerSheet(
        title: _l10n.prayerHighLatitudeRule,
        selectedToken: _highLatitudeTokens.contains(_highLatToken)
            ? _highLatToken
            : PrayerTimesCalculator.defaultHighLatitudeToken,
        options: [
          for (final token in _highLatitudeTokens)
            _SelectionOption(
              token: token,
              label: _highLatLabel(token),
              icon: switch (token) {
                'automatic' => Icons.auto_mode_rounded,
                'none' => Icons.block_rounded,
                'middleOfTheNight' => Icons.nightlight_round,
                'seventhOfTheNight' => Icons.pie_chart_outline_rounded,
                'twilightAngle' => Icons.wb_twilight_rounded,
                _ => Icons.travel_explore_rounded,
              },
            ),
        ],
        colors: colors,
        isDark: isDark,
      ),
    );

    if (!mounted || picked == null) return;
    setState(() => _highLatToken = picked);
  }

  Widget _buildMadhabToggle(bool isDark, AppColorScheme colors) {
    final l10n = _l10n;
    Widget segment(String token, String label) {
      final selected = _madhabToken == token;
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [colors.primary, colors.primaryVariant],
                  )
                : null,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.24),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            child: InkWell(
              onTap: () => setState(() => _madhabToken = token),
              borderRadius: BorderRadius.circular(12.r),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? Colors.white
                        : (isDark ? Colors.white70 : colors.primaryDark),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: _fieldDecoration(isDark, colors),
      child: Row(
        children: [
          segment('shafi', l10n.prayerMadhabShafi),
          SizedBox(width: 4.w),
          segment('hanafi', l10n.prayerMadhabHanafi),
        ],
      ),
    );
  }

  Widget _buildOffsetList(
    Object state,
    String locale,
    bool isDark,
    AppColorScheme colors,
  ) {
    final times = state is PrayerTimesLoaded ? state.prayerTimes : null;

    final prayers = <_PrayerEntry>[
      _PrayerEntry(
          key: 'fajr',
          name: _prayerName('fajr'),
          baseTime: times?.fajr,
          icon: Icons.wb_twilight_rounded),
      _PrayerEntry(
          key: 'sunrise',
          name: _prayerName('sunrise'),
          baseTime: times?.sunrise,
          iconAsset: 'assets/images/sunrise.svg.vec'),
      _PrayerEntry(
          key: 'dhuhr',
          name: _prayerName('dhuhr'),
          baseTime: times?.dhuhr,
          icon: Icons.wb_sunny_rounded),
      _PrayerEntry(
          key: 'asr',
          name: _prayerName('asr'),
          baseTime: times?.asr,
          icon: Icons.wb_sunny_outlined),
      _PrayerEntry(
          key: 'maghrib',
          name: _prayerName('maghrib'),
          baseTime: times?.maghrib,
          iconAsset: 'assets/images/sunset.svg.vec'),
      _PrayerEntry(
          key: 'isha',
          name: _prayerName('isha'),
          baseTime: times?.isha,
          icon: Icons.dark_mode_rounded),
    ];

    return Column(
      children: [
        for (int i = 0; i < prayers.length; i++) ...[
          _buildOffsetRow(prayers[i], locale, isDark, colors),
          if (i != prayers.length - 1) SizedBox(height: 8.h),
        ],
      ],
    );
  }

  Widget _buildOffsetRow(
    _PrayerEntry entry,
    String locale,
    bool isDark,
    AppColorScheme colors,
  ) {
    final offset = _offsets[entry.key] ?? 0;
    final hasOffset = offset != 0;
    final base = entry.baseTime;
    final timeStr = base == null
        ? '--:--'
        : DateFormat.jm(locale).format(base.add(Duration(minutes: offset)));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: hasOffset
            ? colors.primary.withValues(alpha: isDark ? 0.18 : 0.08)
            : (isDark
                ? colors.darkGradientMid.withValues(alpha: 0.45)
                : colors.lightSurface.withValues(alpha: 0.82)),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: hasOffset
              ? colors.primaryVariant.withValues(alpha: isDark ? 0.46 : 0.28)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : colors.primaryExtraLight.withValues(alpha: 0.85)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: hasOffset
                  ? colors.primary.withValues(alpha: 0.16)
                  : colors.primaryExtraLight
                      .withValues(alpha: isDark ? 0.1 : 0.5),
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: _PrayerEntryIcon(
              entry: entry,
              size: 19.sp,
              color: hasOffset
                  ? (isDark ? colors.primaryLight : colors.primary)
                  : (isDark
                      ? Colors.white54
                      : colors.primary.withValues(alpha: 0.7)),
            ),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? colors.darkText : colors.lightText,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: hasOffset
                        ? (isDark ? colors.primaryLight : colors.primary)
                        : (isDark ? Colors.white54 : Colors.black45),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          _ThemedButton(
            icon: Icons.remove_rounded,
            onTap: () => _decrement(entry.key),
            colors: colors,
            isDark: isDark,
          ),
          SizedBox(width: 7.w),
          _OffsetValue(
            label: _offsetLabel(offset),
            active: hasOffset,
            colors: colors,
            isDark: isDark,
          ),
          SizedBox(width: 7.w),
          _ThemedButton(
            icon: Icons.add_rounded,
            onTap: () => _increment(entry.key),
            colors: colors,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark, AppColorScheme colors) {
    final l10n = _l10n;
    final bgColor = isDark ? colors.darkGradientMid : colors.lightSurface;
    return Container(
      color: bgColor,
      padding: EdgeInsets.fromLTRB(
        16.w,
        12.h,
        16.w,
        12.h + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: _FooterButton(
              label: l10n.reset,
              onTap: _reset,
              colors: colors,
              isDark: isDark,
              isPrimary: false,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 2,
            child: _FooterButton(
              label: l10n.prayerSettingsApply,
              onTap: _apply,
              colors: colors,
              isDark: isDark,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }

  String _prayerName(String key) {
    final l10n = _l10n;
    switch (key) {
      case 'fajr':
        return l10n.fajr;
      case 'sunrise':
        return l10n.sunrise;
      case 'dhuhr':
        return l10n.dhuhr;
      case 'asr':
        return l10n.asr;
      case 'maghrib':
        return l10n.maghrib;
      case 'isha':
        return l10n.isha;
      default:
        return key;
    }
  }
}

class _PrayerEntry {
  final String key;
  final String name;
  final DateTime? baseTime;
  final IconData? icon;
  final String? iconAsset;

  const _PrayerEntry({
    required this.key,
    required this.name,
    required this.baseTime,
    this.icon,
    this.iconAsset,
  }) : assert(icon != null || iconAsset != null);
}

class _PrayerEntryIcon extends StatelessWidget {
  final _PrayerEntry entry;
  final double size;
  final Color color;

  const _PrayerEntryIcon({
    required this.entry,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (entry.iconAsset != null) {
      return Center(
        child: SvgPicture(
          AssetBytesLoader(entry.iconAsset!),
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      );
    }

    return Icon(
      entry.icon,
      size: size,
      color: color,
    );
  }
}

class _SelectionOption {
  final String token;
  final String label;
  final IconData icon;

  const _SelectionOption({
    required this.token,
    required this.label,
    required this.icon,
  });
}

class _SelectionField extends StatelessWidget {
  final String value;
  final IconData icon;
  final AppColorScheme colors;
  final bool isDark;
  final VoidCallback onTap;

  const _SelectionField({
    required this.value,
    required this.icon,
    required this.colors,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(14.r);
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          padding: EdgeInsets.fromLTRB(12.w, 11.h, 11.w, 11.h),
          decoration: BoxDecoration(
            color: isDark
                ? colors.darkGradientMid.withValues(alpha: 0.6)
                : colors.primaryExtraLight.withValues(alpha: 0.32),
            borderRadius: borderRadius,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : colors.primaryExtraLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Icon(
                  icon,
                  size: 18.sp,
                  color: isDark ? colors.primaryLight : colors.primary,
                ),
              ),
              SizedBox(width: 11.w),
              Expanded(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: isDark ? colors.darkText : colors.lightText,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20.sp,
                  color: isDark ? colors.primaryLight : colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionPickerSheet extends StatefulWidget {
  final String title;
  final String selectedToken;
  final List<_SelectionOption> options;
  final AppColorScheme colors;
  final bool isDark;
  final bool searchable;
  final String? searchHint;

  const _SelectionPickerSheet({
    required this.title,
    required this.selectedToken,
    required this.options,
    required this.colors,
    required this.isDark,
    this.searchable = false,
    this.searchHint,
  });

  @override
  State<_SelectionPickerSheet> createState() => _SelectionPickerSheetState();
}

class _SelectionPickerSheetState extends State<_SelectionPickerSheet> {
  String _query = '';

  String _normalizeSearchText(String value) {
    return TextUtils.removeDiacriticsAndNormalize(value).toLowerCase();
  }

  List<_SelectionOption> get _filteredOptions {
    final normalized = _normalizeSearchText(_query.trim());
    if (normalized.isEmpty) return widget.options;
    return widget.options.where((option) {
      return _normalizeSearchText(option.label).contains(normalized) ||
          _normalizeSearchText(option.token).contains(normalized);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final isDark = widget.isDark;
    final filteredOptions = _filteredOptions;
    final background = isDark ? colors.darkGradientMid : colors.lightSurface;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.76,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(26.r),
            topRight: Radius.circular(26.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.46 : 0.16),
              blurRadius: 26,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 10.h, 14.w, 12.h),
              child: Column(
                children: [
                  Container(
                    width: 42.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.28)
                          : Colors.black.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900,
                            color:
                                isDark ? colors.darkText : colors.primaryDark,
                          ),
                        ),
                      ),
                      Material(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(11.r),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(11.r),
                          child: Padding(
                            padding: EdgeInsets.all(8.w),
                            child: Icon(
                              Icons.close_rounded,
                              size: 19.sp,
                              color:
                                  isDark ? Colors.white70 : colors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.searchable) ...[
                    SizedBox(height: 12.h),
                    _PickerSearchField(
                      hint: widget.searchHint ?? '',
                      colors: colors,
                      isDark: isDark,
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ],
                ],
              ),
            ),
            Flexible(
              child: filteredOptions.isEmpty
                  ? _PickerEmptyState(colors: colors, isDark: isDark)
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(
                        14.w,
                        0,
                        14.w,
                        14.h + MediaQuery.paddingOf(context).bottom,
                      ),
                      itemCount: filteredOptions.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
                        final option = filteredOptions[index];
                        final selected = option.token == widget.selectedToken;

                        return _SelectionOptionTile(
                          option: option,
                          selected: selected,
                          colors: colors,
                          isDark: isDark,
                          onTap: () => Navigator.of(context).pop(option.token),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerSearchField extends StatelessWidget {
  final String hint;
  final AppColorScheme colors;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _PickerSearchField({
    required this.hint,
    required this.colors,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: true,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        color: isDark ? colors.darkText : colors.lightText,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: isDark ? Colors.white54 : colors.primary,
          size: 20.sp,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.82),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : colors.primaryExtraLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : colors.primaryExtraLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: colors.primaryVariant, width: 1.2),
        ),
      ),
    );
  }
}

class _PickerEmptyState extends StatelessWidget {
  final AppColorScheme colors;
  final bool isDark;

  const _PickerEmptyState({
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.w,
        28.h,
        20.w,
        28.h + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 28.sp,
            color:
                isDark ? Colors.white38 : colors.primary.withValues(alpha: 0.5),
          ),
          SizedBox(height: 10.h),
          Text(
            l10n.tryDifferentSearch,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionOptionTile extends StatelessWidget {
  final _SelectionOption option;
  final bool selected;
  final AppColorScheme colors;
  final bool isDark;
  final VoidCallback onTap;

  const _SelectionOptionTile({
    required this.option,
    required this.selected,
    required this.colors,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(15.r);
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.all(11.w),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: isDark ? 0.24 : 0.1)
                : (isDark
                    ? colors.darkCardBackground.withValues(alpha: 0.68)
                    : Colors.white),
            borderRadius: borderRadius,
            border: Border.all(
              color: selected
                  ? colors.primaryVariant.withValues(alpha: isDark ? 0.5 : 0.3)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : colors.primaryExtraLight.withValues(alpha: 0.85)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primary.withValues(alpha: isDark ? 0.28 : 0.14)
                      : colors.primaryExtraLight
                          .withValues(alpha: isDark ? 0.1 : 0.45),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  option.icon,
                  size: 18.sp,
                  color: selected
                      ? (isDark ? colors.primaryLight : colors.primary)
                      : (isDark
                          ? Colors.white54
                          : colors.primary.withValues(alpha: 0.68)),
                ),
              ),
              SizedBox(width: 11.w),
              Expanded(
                child: Text(
                  option.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.25,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    color: isDark ? colors.darkText : colors.lightText,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? colors.primary
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : colors.primaryExtraLight.withValues(alpha: 0.4)),
                  border: Border.all(
                    color: selected
                        ? colors.primary
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : colors.primaryExtraLight),
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18.sp,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemedButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final AppColorScheme colors;
  final bool isDark;

  const _ThemedButton({
    required this.icon,
    required this.onTap,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                colors.primary.withValues(alpha: isDark ? 0.35 : 0.14),
                colors.primaryVariant.withValues(alpha: isDark ? 0.24 : 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color:
                  colors.primaryVariant.withValues(alpha: isDark ? 0.48 : 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 18.sp,
            color: isDark ? colors.primaryLight : colors.primary,
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final AppColorScheme colors;
  final bool isDark;

  const _IconBadge({
    required this.icon,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28.w,
      height: 28.w,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(9.r),
      ),
      child: Icon(
        icon,
        size: 15.sp,
        color: isDark ? colors.primaryLight : colors.primary,
      ),
    );
  }
}

class _OffsetValue extends StatelessWidget {
  final String label;
  final bool active;
  final AppColorScheme colors;
  final bool isDark;

  const _OffsetValue({
    required this.label,
    required this.active,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 44.w,
      padding: EdgeInsets.symmetric(vertical: 7.h),
      decoration: BoxDecoration(
        color: active
            ? colors.primary.withValues(alpha: isDark ? 0.24 : 0.12)
            : (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(
          color: active
              ? colors.primaryVariant.withValues(alpha: isDark ? 0.48 : 0.28)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : colors.primaryExtraLight.withValues(alpha: 0.9)),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w900,
          color: active
              ? (isDark ? colors.primaryLight : colors.primary)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.45)
                  : Colors.black38),
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final AppColorScheme colors;
  final bool isDark;
  final bool isPrimary;

  const _FooterButton({
    required this.label,
    required this.onTap,
    required this.colors,
    required this.isDark,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(15.r);
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [colors.accent, colors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isPrimary
                ? null
                : (isDark
                    ? colors.darkGradientEnd.withValues(alpha: 0.58)
                    : Colors.white),
            borderRadius: borderRadius,
            border: isPrimary
                ? null
                : Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : colors.primaryExtraLight,
                  ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5.sp,
              fontWeight: FontWeight.w900,
              color: isPrimary
                  ? Colors.white
                  : (isDark
                      ? colors.darkText.withValues(alpha: 0.78)
                      : colors.primary),
            ),
          ),
        ),
      ),
    );
  }
}

void showPrayerTimeAdjustmentSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<PrayerTimesCubit>(),
      child: const PrayerTimeAdjustmentBottomSheet(),
    ),
  );
}
