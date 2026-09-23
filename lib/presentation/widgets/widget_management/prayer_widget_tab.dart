import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:home_widget/home_widget.dart';
import 'package:huda/core/services/prayer_widget_service.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';

class PrayerWidgetTab extends StatefulWidget {
  const PrayerWidgetTab({super.key, required this.isDark});

  final bool isDark;

  @override
  State<PrayerWidgetTab> createState() => _PrayerWidgetTabState();
}

class _PrayerWidgetTabState extends State<PrayerWidgetTab> {
  late PrayerWidgetSettings _settings;
  bool _isPinSupported = false;
  bool _checkingPinSupport = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _settings = PrayerWidgetService.readSettings();
    _checkPinSupport();
  }

  Future<void> _checkPinSupport() async {
    if (!Platform.isAndroid) {
      setState(() {
        _isPinSupported = false;
        _checkingPinSupport = false;
      });
      return;
    }
    try {
      final supported = await HomeWidget.isRequestPinWidgetSupported();
      if (!mounted) return;
      setState(() {
        _isPinSupported = supported == true;
        _checkingPinSupport = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPinSupported = false;
        _checkingPinSupport = false;
      });
    }
  }

  Future<void> _requestPin() async {
    try {
      await HomeWidget.requestPinWidget(
        androidName: 'PrayerWidgetReceiver',
        qualifiedAndroidName: PrayerWidgetService.androidReceiverName,
      );
    } catch (e) {
      debugPrint('⚠️ requestPinWidget(prayer) failed: $e');
    }
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    try {
      await PrayerWidgetService.forceUpdate();
      if (!mounted) return;
      HudaSnackBar.success(
        context,
        message: AppLocalizations.of(context)!.prayerWidgetUpdated,
      );
    } catch (error) {
      if (!mounted) return;
      HudaSnackBar.error(
        context,
        message: AppLocalizations.of(context)!.errorUpdatingWidget('$error'),
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _commit(PrayerWidgetSettings next) async {
    setState(() => _settings = next);
    try {
      await PrayerWidgetService.updateCustomization(next);
    } catch (error) {
      if (!mounted) return;
      setState(() => _settings = PrayerWidgetService.readSettings());
      HudaSnackBar.error(
        context,
        message: AppLocalizations.of(context)!.errorUpdatingWidget('$error'),
      );
    }
  }

  Future<void> _resetAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.resetWidgetCustomization),
        content: Text(l10n.resetWidgetCustomizationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await PrayerWidgetService.resetCustomization();
      if (!mounted) return;
      setState(() => _settings = PrayerWidgetService.readSettings());
    } catch (error) {
      if (!mounted) return;
      HudaSnackBar.error(context, message: l10n.errorUpdatingWidget('$error'));
    }
  }

  Future<void> _pickLanguage() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<PrayerWidgetLanguage>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.84,
        child: Column(
          children: [
            _LanguageSheetHeader(
              title: l10n.language,
              onClose: () => Navigator.pop(ctx),
            ),
            Divider(height: 1, color: Theme.of(ctx).dividerColor),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  16.w,
                  12.h,
                  16.w,
                  20.h + MediaQuery.viewPaddingOf(ctx).bottom,
                ),
                itemCount: PrayerWidgetLanguage.values.length,
                separatorBuilder: (_, _) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final language = PrayerWidgetLanguage.values[index];
                  return _LanguageOption(
                    title: _languageLabel(l10n, language),
                    code: language == PrayerWidgetLanguage.auto
                        ? null
                        : language.code,
                    selected: language == _settings.language,
                    onTap: () => Navigator.pop(ctx, language),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await _commit(_settings.copyWith(language: picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = widget.isDark;
    final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            0,
            16.h,
            0,
            16.h + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _PrayerHeaderCard(isDark: isDark),
              ),
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _AddCard(
                  isDark: isDark,
                  isPinSupported: _isPinSupported,
                  checkingPinSupport: _checkingPinSupport,
                  onRequestPin: _requestPin,
                ),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _CustomizationHeading(
                  title: l10n.prayerWidgetCustomization,
                ),
              ),
              SizedBox(height: 12.h),
              _SectionShell(
                isDark: isDark,
                title: l10n.design,
                icon: Icons.dashboard_customize_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DesignTile(
                      title: l10n.designHero,
                      description: l10n.designHeroDescription,
                      design: PrayerWidgetDesign.hero,
                      selected: _settings.design == PrayerWidgetDesign.hero,
                      onTap: () => _commit(
                        _settings.copyWith(design: PrayerWidgetDesign.hero),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    _DesignTile(
                      title: l10n.designCompact,
                      description: l10n.designCompactDescription,
                      design: PrayerWidgetDesign.compact,
                      selected: _settings.design == PrayerWidgetDesign.compact,
                      onTap: () => _commit(
                        _settings.copyWith(design: PrayerWidgetDesign.compact),
                      ),
                    ),
                  ],
                ),
              ),
              _SectionShell(
                isDark: isDark,
                title: l10n.widgetTheme,
                icon: Icons.palette_outlined,
                child: SizedBox(
                  height: 108.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: PrayerWidgetVisualTheme.values.length,
                    separatorBuilder: (_, _) => SizedBox(width: 10.w),
                    itemBuilder: (context, index) {
                      final theme = PrayerWidgetVisualTheme.values[index];
                      final selected = _settings.visualTheme == theme;
                      return _ThemeCard(
                        label: _themeLabel(l10n, theme),
                        backgroundColor: theme.backgroundColor,
                        contentColor: theme.contentColor,
                        selected: selected,
                        isDark: isDark,
                        onTap: () =>
                            _commit(_settings.copyWith(visualTheme: theme)),
                      );
                    },
                  ),
                ),
              ),
              _SectionShell(
                isDark: isDark,
                title: l10n.content,
                icon: Icons.text_fields_rounded,
                child: _ContentSizeControl(
                  label: l10n.contentSize,
                  value: _settings.contentSize,
                  onChanged: (value) => setState(
                    () => _settings = _settings.copyWith(contentSize: value),
                  ),
                  onChangeEnd: (value) =>
                      _commit(_settings.copyWith(contentSize: value)),
                ),
              ),
              _SectionShell(
                isDark: isDark,
                title: l10n.language,
                icon: Icons.language_rounded,
                child: _SelectionTile(
                  title: _languageLabel(l10n, _settings.language),
                  icon: _settings.language == PrayerWidgetLanguage.auto
                      ? Icons.language_rounded
                      : Icons.translate_rounded,
                  onTap: _pickLanguage,
                ),
              ),
              _SectionShell(
                isDark: isDark,
                title: l10n.prayerWidgetTimeFormat,
                icon: Icons.schedule_rounded,
                child: SegmentedButton<PrayerWidgetTimeFormat>(
                  segments: [
                    ButtonSegment(
                      value: PrayerWidgetTimeFormat.twelveHour,
                      label: Text(l10n.prayerWidgetTwelveHour),
                    ),
                    ButtonSegment(
                      value: PrayerWidgetTimeFormat.twentyFourHour,
                      label: Text(l10n.prayerWidgetTwentyFourHour),
                    ),
                  ],
                  selected: {_effectiveTimeFormat(context)},
                  onSelectionChanged: (selection) {
                    if (selection.isEmpty) return;
                    _commit(_settings.copyWith(timeFormat: selection.first));
                  },
                ),
              ),
              _SectionShell(
                isDark: isDark,
                title: l10n.advanced,
                icon: Icons.settings_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: FilledButton.icon(
                        onPressed: _isRefreshing ? null : _refresh,
                        icon: _isRefreshing
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(
                          _isRefreshing
                              ? l10n.prayerWidgetUpdating
                              : l10n.forcePrayerWidgetUpdate,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      width: double.infinity,
                      height: 44.h,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: Text(l10n.resetWidgetCustomization),
                        onPressed: _resetAll,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(
                            color: colorScheme.error.withValues(alpha: 0.42),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PrayerWidgetTimeFormat _effectiveTimeFormat(BuildContext context) {
    if (_settings.timeFormat != PrayerWidgetTimeFormat.system) {
      return _settings.timeFormat;
    }
    return MediaQuery.alwaysUse24HourFormatOf(context)
        ? PrayerWidgetTimeFormat.twentyFourHour
        : PrayerWidgetTimeFormat.twelveHour;
  }

  String _languageLabel(AppLocalizations l10n, PrayerWidgetLanguage lang) {
    switch (lang) {
      case PrayerWidgetLanguage.auto:
        return l10n.automatic;
      case PrayerWidgetLanguage.ar:
        return l10n.arabic;
      case PrayerWidgetLanguage.en:
        return l10n.english;
      case PrayerWidgetLanguage.tr:
        return l10n.turkish;
      case PrayerWidgetLanguage.fr:
        return l10n.french;
      case PrayerWidgetLanguage.es:
        return l10n.spanish;
      case PrayerWidgetLanguage.de:
        return l10n.german;
      case PrayerWidgetLanguage.ru:
        return l10n.russian;
      case PrayerWidgetLanguage.ur:
        return l10n.urdu;
      case PrayerWidgetLanguage.ms:
        return l10n.malay;
      case PrayerWidgetLanguage.bn:
        return l10n.bengali;
    }
  }

  String _themeLabel(AppLocalizations l10n, PrayerWidgetVisualTheme theme) {
    switch (theme) {
      case PrayerWidgetVisualTheme.auto:
        return l10n.themeAuto;
      case PrayerWidgetVisualTheme.ocean:
        return l10n.themeOcean;
      case PrayerWidgetVisualTheme.sunset:
        return l10n.themeSunset;
      case PrayerWidgetVisualTheme.forest:
        return l10n.themeForest;
      case PrayerWidgetVisualTheme.midnight:
        return l10n.themeMidnight;
      case PrayerWidgetVisualTheme.sandstone:
        return l10n.themeSandstone;
      case PrayerWidgetVisualTheme.rose:
        return l10n.themeRose;
      case PrayerWidgetVisualTheme.lavender:
        return l10n.themeLavender;
      case PrayerWidgetVisualTheme.charcoal:
        return l10n.themeCharcoal;
      case PrayerWidgetVisualTheme.amber:
        return l10n.themeAmber;
      case PrayerWidgetVisualTheme.arctic:
        return l10n.themeArctic;
      case PrayerWidgetVisualTheme.burgundy:
        return l10n.themeBurgundy;
      case PrayerWidgetVisualTheme.sage:
        return l10n.themeSage;
    }
  }
}

class _PrayerHeaderCard extends StatelessWidget {
  const _PrayerHeaderCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            accent.withValues(alpha: isDark ? 0.26 : 0.16),
            colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: accent.withValues(alpha: 0.18)),
            ),
            child: Icon(
              Icons.access_time_filled_rounded,
              color: accent,
              size: 27.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.prayerTimesWidget,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18.sp,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  l10n.prayerWidgetTagline,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.4,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard({
    required this.isDark,
    required this.isPinSupported,
    required this.checkingPinSupport,
    required this.onRequestPin,
  });

  final bool isDark;
  final bool isPinSupported;
  final bool checkingPinSupport;
  final VoidCallback onRequestPin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Icon(
                  Icons.add_to_home_screen_rounded,
                  size: 17.sp,
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Text(
                  l10n.addPrayerWidgetTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.addPrayerWidgetDescription,
            style: TextStyle(
              fontSize: 13.sp,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          SizedBox(height: 12.h),
          if (checkingPinSupport)
            const Center(child: CircularProgressIndicator())
          else if (Platform.isAndroid && isPinSupported)
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: FilledButton.icon(
                onPressed: onRequestPin,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.addPrayerWidget),
              ),
            )
          else
            _ManualSteps(
              steps: Platform.isIOS
                  ? [
                      l10n.iosWidgetStep1,
                      l10n.iosWidgetStep2,
                      l10n.iosWidgetStep3,
                      l10n.iosWidgetStep4,
                    ]
                  : [
                      l10n.androidWidgetStep1,
                      l10n.androidWidgetStep2,
                      l10n.androidWidgetStep3,
                      l10n.androidWidgetStep4,
                    ],
            ),
        ],
      ),
    );
  }
}

class _ManualSteps extends StatelessWidget {
  const _ManualSteps({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 9.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 11.r,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.35,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.title,
    required this.icon,
    required this.child,
    required this.isDark,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Icon(icon, size: 17.sp, color: colorScheme.primary),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}

class _CustomizationHeading extends StatelessWidget {
  const _CustomizationHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 34.w,
          height: 34.w,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            Icons.tune_rounded,
            size: 19.sp,
            color: colorScheme.primary,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17.sp,
              letterSpacing: -0.15,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContentSizeControl extends StatelessWidget {
  const _ContentSizeControl({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Aa',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: (18 * (value / 100)).clamp(13, 25).sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 11.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(minWidth: 52.w),
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '$value%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 7.h),
          Row(
            children: [
              Text(
                'A',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Slider(
                  min: 60,
                  max: 140,
                  divisions: 16,
                  value: value.toDouble(),
                  label: '$value%',
                  onChanged: (next) => onChanged(next.round()),
                  onChangeEnd: (next) => onChangeEnd(next.round()),
                ),
              ),
              Text(
                'A',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.all(13.w),
          child: Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colorScheme.primary, size: 21.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSheetHeader extends StatelessWidget {
  const _LanguageSheetHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 2.h, 12.w, 16.h),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Icon(
              Icons.language_rounded,
              color: colorScheme.primary,
              size: 23.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 19.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.cancel,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.title,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.10)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
          side: BorderSide(
            color: selected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 11.h),
            child: Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: code == null
                      ? Icon(
                          Icons.language_rounded,
                          size: 20.sp,
                          color: selected
                              ? colorScheme.onPrimary
                              : colorScheme.primary,
                        )
                      : Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            code!.toUpperCase(),
                            style: TextStyle(
                              color: selected
                                  ? colorScheme.onPrimary
                                  : colorScheme.primary,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  size: 22.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesignTile extends StatelessWidget {
  const _DesignTile({
    required this.title,
    required this.description,
    required this.design,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final PrayerWidgetDesign design;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.10)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
            border: Border.all(
              color: selected
                  ? accent
                  : colorScheme.outlineVariant.withValues(alpha: 0.55),
              width: selected ? 1.8 : 1,
            ),
            borderRadius: BorderRadius.circular(13.r),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48.w,
                height: 40.h,
                child: CustomPaint(
                  painter: _DesignMiniaturePainter(
                    design: design,
                    accent: accent,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.35,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? accent : colorScheme.outlineVariant,
                size: 21.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesignMiniaturePainter extends CustomPainter {
  const _DesignMiniaturePainter({required this.design, required this.accent});

  final PrayerWidgetDesign design;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.height * 0.24);
    final background = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF144441), Color(0xFF06191F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), background);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.6), radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = accent.withValues(alpha: 0.62),
    );

    final cream = Paint()..color = const Color(0xFFF7F4E9);
    final muted = Paint()..color = const Color(0xFFB9D0CC);
    final gold = Paint()..color = const Color(0xFFE4C777);
    final glow = Paint()..color = accent.withValues(alpha: 0.85);

    if (design == PrayerWidgetDesign.hero) {
      canvas.drawCircle(
        Offset(size.width * 0.18, size.height * 0.22),
        2.1,
        gold,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.14,
            size.height * 0.38,
            size.width * 0.45,
            3.2,
          ),
          const Radius.circular(2),
        ),
        cream,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.14,
            size.height * 0.52,
            size.width * 0.58,
            5,
          ),
          const Radius.circular(2),
        ),
        cream,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.14,
            size.height * 0.72,
            size.width * 0.68,
            4,
          ),
          const Radius.circular(3),
        ),
        glow,
      );
      final horizon = Path()
        ..moveTo(0, size.height * 0.78)
        ..quadraticBezierTo(
          size.width * 0.48,
          size.height * 0.53,
          size.width,
          size.height * 0.76,
        );
      canvas.drawPath(
        horizon,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = accent.withValues(alpha: 0.42),
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.24,
          size.height * 0.14,
          0.8,
          size.height * 0.28,
        ),
        gold,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.09,
            size.height * 0.18,
            size.width * 0.10,
            5,
          ),
          const Radius.circular(2),
        ),
        cream,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.32,
            size.height * 0.20,
            size.width * 0.42,
            3,
          ),
          const Radius.circular(2),
        ),
        muted,
      );
      const columns = 3;
      const rows = 2;
      final gap = size.width * 0.035;
      final cellWidth = (size.width * 0.82 - gap * (columns - 1)) / columns;
      final cellHeight = size.height * 0.16;
      for (var row = 0; row < rows; row++) {
        for (var column = 0; column < columns; column++) {
          final cell = Rect.fromLTWH(
            size.width * 0.09 + column * (cellWidth + gap),
            size.height * 0.49 + row * (cellHeight + 2),
            cellWidth,
            cellHeight,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(cell, const Radius.circular(2.5)),
            row == 1 && column == 1
                ? glow
                : (Paint()..color = cream.color.withValues(alpha: 0.18)),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DesignMiniaturePainter oldDelegate) =>
      oldDelegate.design != design || oldDelegate.accent != accent;
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.backgroundColor,
    required this.contentColor,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final String? backgroundColor;
  final String? contentColor;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final bgColor =
        _parseHex(backgroundColor) ??
        (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final fgColor =
        _parseHex(contentColor) ?? (isDark ? Colors.white : Colors.black87);
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 80.w,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: selected ? accent : Colors.grey.withValues(alpha: 0.3),
              width: selected ? 2.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (backgroundColor == null)
                Icon(Icons.palette_outlined, color: accent, size: 24.sp)
              else
                Text(
                  'Aa',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22.sp,
                    color: fgColor,
                  ),
                ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: backgroundColor == null
                      ? (isDark ? Colors.white70 : Colors.black54)
                      : fgColor.withValues(alpha: 0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (selected)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Icon(Icons.check_circle, color: accent, size: 16.sp),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Color? _parseHex(String? hex) {
    if (hex == null) return null;
    var s = hex.replaceFirst('#', '').toUpperCase();
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    final v = int.tryParse(s, radix: 16);
    return v == null ? null : Color(v);
  }
}
