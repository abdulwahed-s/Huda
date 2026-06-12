import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:home_widget/home_widget.dart';
import 'package:huda/core/services/prayer_widget_service.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.prayerWidgetUpdated),
        ),
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _commit(PrayerWidgetSettings next) async {
    setState(() => _settings = next);
    await PrayerWidgetService.updateCustomization(next);
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
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await PrayerWidgetService.resetCustomization();
    if (!mounted) return;
    setState(() => _settings = PrayerWidgetService.readSettings());
  }

  Future<void> _pickLanguage() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<PrayerWidgetLanguage>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final lang in PrayerWidgetLanguage.values)
              RadioListTile<PrayerWidgetLanguage>(
                value: lang,
                groupValue: _settings.language,
                title: Text(_languageLabel(l10n, lang)),
                onChanged: (selected) => Navigator.pop(ctx, selected),
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
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded,
                        size: 20.sp,
                        color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8.w),
                    Text(
                      l10n.prayerWidgetCustomization,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4.h),
              _SectionShell(
                isDark: isDark,
                title: l10n.design,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DesignTile(
                      title: l10n.designHero,
                      description: l10n.designHeroDescription,
                      icon: Icons.timer_rounded,
                      selected: _settings.design == PrayerWidgetDesign.hero,
                      onTap: () => _commit(
                        _settings.copyWith(design: PrayerWidgetDesign.hero),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    _DesignTile(
                      title: l10n.designCompact,
                      description: l10n.designCompactDescription,
                      icon: Icons.view_agenda_rounded,
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
                child: SizedBox(
                  height: 100.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: PrayerWidgetVisualTheme.values.length,
                    separatorBuilder: (_, __) => SizedBox(width: 10.w),
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
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    children: [
                      Text(l10n.contentSize),
                      Expanded(
                        child: Slider(
                          min: 60,
                          max: 140,
                          divisions: 16,
                          value: _settings.contentSize.toDouble(),
                          label: '${_settings.contentSize}%',
                          onChanged: (value) => setState(
                            () => _settings =
                                _settings.copyWith(contentSize: value.round()),
                          ),
                          onChangeEnd: (value) => _commit(
                              _settings.copyWith(contentSize: value.round())),
                        ),
                      ),
                      SizedBox(
                        width: 40.w,
                        child: Text('${_settings.contentSize}%',
                            textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                ),
              ),
              _SectionShell(
                isDark: isDark,
                title: l10n.language,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_languageLabel(l10n, _settings.language)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickLanguage,
                ),
              ),
              _SectionShell(
                isDark: isDark,
                title: l10n.advanced,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 44.h,
                      child: OutlinedButton.icon(
                        onPressed: _isRefreshing ? null : _refresh,
                        icon: _isRefreshing
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: const CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(_isRefreshing
                            ? l10n.prayerWidgetUpdating
                            : l10n.forcePrayerWidgetUpdate),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      width: double.infinity,
                      height: 44.h,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: Text(l10n.resetWidgetCustomization),
                        onPressed: _resetAll,
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
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.access_time_filled_rounded,
                color: accent, size: 24.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.prayerTimesWidget,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  l10n.prayerWidgetTagline,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[700],
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.add_to_home_screen_rounded,
                size: 18.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 8.w),
              Text(
                l10n.addPrayerWidgetTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.addPrayerWidgetDescription,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
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
              isDark: isDark,
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
  const _ManualSteps({required this.isDark, required this.steps});

  final bool isDark;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[800]!.withValues(alpha: 0.5)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
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
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
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
    required this.child,
    required this.isDark,
  });

  final String title;
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15.sp,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          child,
        ],
      ),
    );
  }
}

class _DesignTile extends StatelessWidget {
  const _DesignTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.10) : null,
          border: Border.all(
            color: selected ? accent : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: accent.withValues(alpha: 0.15),
              child: Icon(icon, color: accent),
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
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: accent, size: 20.sp),
          ],
        ),
      ),
    );
  }
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
    final bgColor = _parseHex(backgroundColor) ??
        (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final fgColor =
        _parseHex(contentColor) ?? (isDark ? Colors.white : Colors.black87);
    return GestureDetector(
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
