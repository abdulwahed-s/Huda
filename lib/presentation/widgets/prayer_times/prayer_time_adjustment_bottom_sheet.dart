import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:huda/core/services/android_prayer_countdown.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_search_field.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:vector_graphics/vector_graphics.dart';

/// Prayer time settings: the calculation method (custom angles for
/// "Other"), the Asr method, the high-latitude rule and minute offsets per
/// prayer. Nothing changes until Apply; Reset returns to the defaults.
/// Opens as a bottom sheet on phones and a dialog from medium width.
void showPrayerTimeAdjustmentSheet(BuildContext context) {
  final cubit = context.read<PrayerTimesCubit>();
  showHudaSheet<void>(
    context: context,
    title: AppLocalizations.of(context)!.prayerSettingsTitle,
    expand: true,
    maxDialogWidth: 600,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const PrayerTimeAdjustmentBottomSheet(),
    ),
  );
}

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
  late final TextEditingController _fajrAngleController;
  late final TextEditingController _maghribAngleController;
  late final TextEditingController _ishaAngleController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<PrayerTimesCubit>();
    _offsets = Map.from(cubit.prayerOffsets);
    _methodToken = cubit.calculationMethodToken;
    _madhabToken = cubit.madhabToken;
    _highLatToken = cubit.highLatitudeRuleToken;
    _countryCode = PrayerTimesCalculator.countryCodeFromCache(
      cubit.cacheHelper,
    );
    _fajrAngleController = TextEditingController(
      text: CustomPrayerAngles.canonical(cubit.customPrayerAngles.fajr),
    );
    _maghribAngleController = TextEditingController(
      text: CustomPrayerAngles.canonical(cubit.customPrayerAngles.maghrib),
    );
    _ishaAngleController = TextEditingController(
      text: CustomPrayerAngles.canonical(cubit.customPrayerAngles.isha),
    );
  }

  @override
  void dispose() {
    _fajrAngleController.dispose();
    _maghribAngleController.dispose();
    _ishaAngleController.dispose();
    super.dispose();
  }

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

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

  String _methodDisplayLabel(String token) =>
      prayerMethodDisplayLabel(_l10n, token, _countryCode);

  String _offsetLabel(int offset) {
    if (offset == 0) return '0';
    return offset > 0 ? '+$offset' : '$offset';
  }

  void _step(String key, int delta) {
    const limit = PrayerTimesCalculator.maxManualOffsetMinutes;
    final next = ((_offsets[key] ?? 0) + delta).clamp(-limit, limit);
    HudaHaptics.selection(context);
    setState(() => _offsets[key] = next);
  }

  void _reset() {
    HudaHaptics.light(context);
    setState(() {
      _methodToken = PrayerTimesCalculator.defaultMethodToken;
      _madhabToken = PrayerTimesCalculator.defaultMadhabToken;
      _highLatToken = PrayerTimesCalculator.defaultHighLatitudeToken;
      _offsets = PrayerTimesCalculator.zeroOffsets();
      _setAngleText(_fajrAngleController, CustomPrayerAngles.defaultFajr);
      _setAngleText(_maghribAngleController, CustomPrayerAngles.defaultMaghrib);
      _setAngleText(_ishaAngleController, CustomPrayerAngles.defaultIsha);
    });
  }

  double? _angleValue(TextEditingController controller) =>
      CustomPrayerAngles.tryParseLocalized(controller.text);

  bool get _customAnglesAreValid =>
      CustomPrayerAngles.isValidTwilightAngle(
        _angleValue(_fajrAngleController),
      ) &&
      CustomPrayerAngles.isValidMaghribAngle(
        _angleValue(_maghribAngleController),
      ) &&
      CustomPrayerAngles.isValidTwilightAngle(
        _angleValue(_ishaAngleController),
      );

  CustomPrayerAngles get _customAnglesOrSaved {
    if (!_customAnglesAreValid) {
      return context.read<PrayerTimesCubit>().customPrayerAngles;
    }
    return CustomPrayerAngles(
      fajr: _angleValue(_fajrAngleController)!,
      maghrib: _angleValue(_maghribAngleController)!,
      isha: _angleValue(_ishaAngleController)!,
    );
  }

  void _setAngleText(TextEditingController controller, double value) {
    final text = CustomPrayerAngles.canonical(value);
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _stepAngle(
    TextEditingController controller,
    double delta, {
    required bool allowsZero,
  }) {
    final fallback = allowsZero
        ? CustomPrayerAngles.defaultMaghrib
        : CustomPrayerAngles.defaultFajr;
    final current = _angleValue(controller) ?? fallback;
    final minimum = allowsZero ? 0.0 : 0.1;
    final stepped = ((current + delta) * 10).round() / 10;
    final clamped = stepped.clamp(minimum, CustomPrayerAngles.maximum);
    HudaHaptics.selection(context);
    setState(() => _setAngleText(controller, clamped.toDouble()));
  }

  Future<void> _apply() async {
    if (_methodToken == 'other' && !_customAnglesAreValid) return;
    if (_saving) return;
    final cubit = context.read<PrayerTimesCubit>();
    setState(() => _saving = true);
    try {
      await cubit.savePrayerSettings(
        methodToken: _methodToken,
        madhabToken: _madhabToken,
        highLatToken: _highLatToken,
        offsets: _offsets,
        customAngles: _customAnglesOrSaved,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showHudaToast(
        context,
        message: _l10n.errorUpdatingWidget('$error'),
        kind: HudaToastKind.failed,
      );
      return;
    }

    if (PlatformUtils.isAndroid) {
      try {
        await AndroidPrayerCountdown.refresh();
      } catch (_) {
        // The native countdown also refreshes when the widget settings commit.
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openMethodPicker() async {
    final l10n = _l10n;
    final picked = await showHudaSheet<String>(
      context: context,
      title: l10n.prayerCalculationMethod,
      builder: (_) => _PickerList(
        selected: _methodToken,
        searchHint: l10n.searchHint,
        options: [
          for (final token in PrayerTimesCalculator.pickerMethodTokens)
            (
              token: token,
              label: _methodDisplayLabel(token),
              icon: token == PrayerTimesCalculator.autoMethodToken
                  ? Icons.my_location_rounded
                  : Icons.public_rounded,
            ),
        ],
      ),
    );
    if (!mounted || picked == null) return;
    setState(() => _methodToken = picked);
  }

  Future<void> _openHighLatitudePicker() async {
    final picked = await showHudaSheet<String>(
      context: context,
      title: _l10n.prayerHighLatitudeRule,
      builder: (_) => _PickerList(
        selected: _highLatitudeTokens.contains(_highLatToken)
            ? _highLatToken
            : PrayerTimesCalculator.defaultHighLatitudeToken,
        options: [
          for (final token in _highLatitudeTokens)
            (
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
      ),
    );
    if (!mounted || picked == null) return;
    setState(() => _highLatToken = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final space = tokens.space;
    final state = context.read<PrayerTimesCubit>().state;
    final locale = Localizations.localeOf(context).toString();
    final times = state is PrayerTimesLoaded ? state.prayerTimes : null;
    final adjusted = _offsets.values.where((offset) => offset != 0).length;
    final canApply = _methodToken != 'other' || _customAnglesAreValid;
    final highLat = _highLatitudeTokens.contains(_highLatToken)
        ? _highLatToken
        : PrayerTimesCalculator.defaultHighLatitudeToken;

    final entries = [
      ('fajr', l10n.fajr, times?.fajr, Icons.wb_twilight_rounded, null),
      (
        'sunrise',
        l10n.prayerSunriseLabel,
        times?.sunrise,
        null,
        'assets/images/sunrise.svg.vec',
      ),
      ('dhuhr', l10n.dhuhr, times?.dhuhr, Icons.wb_sunny_rounded, null),
      ('asr', l10n.asr, times?.asr, Icons.wb_sunny_outlined, null),
      (
        'maghrib',
        l10n.maghrib,
        times?.maghrib,
        null,
        'assets/images/sunset.svg.vec',
      ),
      ('isha', l10n.isha, times?.isha, Icons.nights_stay_rounded, null),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header: the title, what it's for, and Close.
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            space.xl,
            space.sm,
            space.xs,
            space.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.prayerSettingsTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      l10n.prayerSettingsSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              space.md,
              space.xs,
              space.md,
              space.lg,
            ),
            children: [
              HudaSectionHeader(l10n.prayerCalculationMethod),
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HudaSettingsRow(
                      key: const ValueKey('prayer-method'),
                      icon: Icons.public_rounded,
                      title: l10n.prayerCalculationMethod,
                      subtitle: _methodDisplayLabel(_methodToken),
                      trailing: const _Chevron(),
                      onTap: _openMethodPicker,
                    ),
                    if (_methodToken == 'other') ...[
                      const Divider(indent: 16, endIndent: 16),
                      _buildCustomAngles(),
                    ],
                    const Divider(indent: 16, endIndent: 16),
                    _ControlRow(
                      icon: Icons.balance_rounded,
                      title: l10n.prayerAsrMethod,
                      control: SegmentedButton<String>(
                        key: const ValueKey('prayer-madhab'),
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: 'shafi',
                            label: Text(l10n.prayerMadhabShafi),
                          ),
                          ButtonSegment(
                            value: 'hanafi',
                            label: Text(l10n.prayerMadhabHanafi),
                          ),
                        ],
                        selected: {_madhabToken},
                        onSelectionChanged: (value) {
                          HudaHaptics.selection(context);
                          setState(() => _madhabToken = value.first);
                        },
                      ),
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    HudaSettingsRow(
                      key: const ValueKey('prayer-high-latitude'),
                      icon: Icons.travel_explore_rounded,
                      title: l10n.prayerHighLatitudeRule,
                      subtitle: _highLatLabel(highLat),
                      trailing: const _Chevron(),
                      onTap: _openHighLatitudePicker,
                    ),
                  ],
                ),
              ),
              SizedBox(height: space.lg),
              HudaSectionHeader(
                l10n.prayerTimeAdjustment,
                trailing: adjusted == 0
                    ? null
                    : Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: space.xs,
                          vertical: space.xxs / 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(tokens.radius.sm),
                        ),
                        child: Text(
                          NumberFormat.decimalPattern(locale).format(adjusted),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
              ),
              Card(
                child: Column(
                  children: [
                    for (final (i, entry) in entries.indexed) ...[
                      if (i > 0) const Divider(indent: 16, endIndent: 16),
                      _OffsetRow(
                        prayerKey: entry.$1,
                        name: entry.$2,
                        time: entry.$3 == null
                            ? '--:--'
                            : DateFormat.jm(locale).format(
                                entry.$3!.add(
                                  Duration(minutes: _offsets[entry.$1] ?? 0),
                                ),
                              ),
                        icon: entry.$4,
                        asset: entry.$5,
                        offset: _offsets[entry.$1] ?? 0,
                        label: _offsetLabel(_offsets[entry.$1] ?? 0),
                        onStep: (delta) => _step(entry.$1, delta),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  space.xxs,
                  space.xs,
                  space.xxs,
                  0,
                ),
                child: Text(
                  l10n.prayerAdjustmentSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Pinned: its surface reaches the edge, its buttons sit above the
        // navigation bar.
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              space.md + MediaQuery.paddingOf(context).left,
              space.sm,
              space.md + MediaQuery.paddingOf(context).right,
              space.sm + MediaQuery.paddingOf(context).bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('prayer-settings-reset'),
                    onPressed: _saving ? null : _reset,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(l10n.reset),
                  ),
                ),
                SizedBox(width: space.sm),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    key: const ValueKey('prayer-settings-apply'),
                    onPressed: canApply && !_saving ? _apply : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(l10n.prayerSettingsApply),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomAngles() {
    final l10n = _l10n;
    final theme = Theme.of(context);
    final space = context.tokens.space;
    return Padding(
      key: const ValueKey('custom-prayer-angles'),
      padding: EdgeInsets.fromLTRB(space.md, space.sm, space.md, space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.prayerCustomAnglesTitle, style: theme.textTheme.titleSmall),
          Text(
            l10n.prayerCustomAnglesSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: space.sm),
          _angleRow(
            const ValueKey('custom-fajr-angle'),
            l10n.fajr,
            _fajrAngleController,
            allowsZero: false,
          ),
          SizedBox(height: space.xs),
          _angleRow(
            const ValueKey('custom-maghrib-angle'),
            l10n.maghrib,
            _maghribAngleController,
            allowsZero: true,
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(top: space.xxs),
            child: Text(
              l10n.prayerMaghribZeroMeansSunset,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(height: space.xs),
          _angleRow(
            const ValueKey('custom-isha-angle'),
            l10n.isha,
            _ishaAngleController,
            allowsZero: false,
          ),
        ],
      ),
    );
  }

  Widget _angleRow(
    Key fieldKey,
    String label,
    TextEditingController controller, {
    required bool allowsZero,
  }) {
    final theme = Theme.of(context);
    final space = context.tokens.space;
    final value = _angleValue(controller);
    final valid = allowsZero
        ? CustomPrayerAngles.isValidMaghribAngle(value)
        : CustomPrayerAngles.isValidTwilightAngle(value);
    final error = allowsZero
        ? _l10n.prayerAngleRangeInclusive
        : _l10n.prayerAngleRangeExclusive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
            _StepButton(
              icon: Icons.remove_rounded,
              tooltip: '$label −',
              onPressed: () =>
                  _stepAngle(controller, -0.1, allowsZero: allowsZero),
            ),
            SizedBox(width: space.xxs),
            SizedBox(
              width: 92,
              child: TextField(
                key: fieldKey,
                controller: controller,
                onChanged: (_) => setState(() {}),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: const [_LocalizedAngleInputFormatter()],
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  isDense: true,
                  suffixText: '°',
                  errorText: valid ? null : '',
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                ),
              ),
            ),
            SizedBox(width: space.xxs),
            _StepButton(
              icon: Icons.add_rounded,
              tooltip: '$label +',
              onPressed: () =>
                  _stepAngle(controller, 0.1, allowsZero: allowsZero),
            ),
          ],
        ),
        if (!valid)
          Padding(
            padding: EdgeInsetsDirectional.only(top: space.xxs),
            child: Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) => Icon(
    Icons.chevron_right_rounded,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}

/// A labeled row with a control (a segmented choice) that wraps under the
/// label when there's no room beside it.
class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.icon,
    required this.title,
    required this.control,
  });

  final IconData icon;
  final String title;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: space.md, vertical: space.sm),
      child: Wrap(
        spacing: space.sm,
        runSpacing: space.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HudaIconMark(icon),
              SizedBox(width: space.md),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          control,
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton.outlined(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 20),
  );
}

class _OffsetRow extends StatelessWidget {
  const _OffsetRow({
    required this.prayerKey,
    required this.name,
    required this.time,
    required this.icon,
    required this.asset,
    required this.offset,
    required this.label,
    required this.onStep,
  });

  final String prayerKey;
  final String name;
  final String time;
  final IconData? icon;
  final String? asset;
  final int offset;
  final String label;
  final void Function(int delta) onStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final active = offset != 0;
    final color = active ? scheme.primary : scheme.onSurfaceVariant;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        space.md,
        space.xs,
        space.xs,
        space.xs,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: asset != null
                ? SvgPicture(
                    AssetBytesLoader(asset!),
                    width: 19,
                    height: 19,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  )
                : Icon(icon, size: 20, color: color),
          ),
          SizedBox(width: space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.bodyLarge),
                Text(
                  time,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: active ? FontWeight.w700 : null,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          _StepButton(
            icon: Icons.remove_rounded,
            tooltip: '$name −',
            onPressed: () => onStep(-1),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44),
            child: AnimatedDefaultTextStyle(
              duration: tokens.motion.of(context, tokens.motion.short),
              style: (theme.textTheme.titleMedium ?? const TextStyle())
                  .copyWith(
                    color: active ? scheme.primary : scheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
              child: Text(
                label,
                key: ValueKey('prayer-offset-$prayerKey'),
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            tooltip: '$name +',
            onPressed: () => onStep(1),
          ),
        ],
      ),
    );
  }
}

/// A choice list for a picker sheet: a search field when [searchHint] is
/// given, the options with the selected one checked; a tap picks.
class _PickerList extends StatefulWidget {
  const _PickerList({
    required this.options,
    required this.selected,
    this.searchHint,
  });

  final List<({String token, String label, IconData icon})> options;
  final String selected;
  final String? searchHint;

  @override
  State<_PickerList> createState() => _PickerListState();
}

class _PickerListState extends State<_PickerList> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final space = context.tokens.space;
    final query = _query.trim().toLowerCase();
    final shown = [
      for (final option in widget.options)
        if (query.isEmpty || option.label.toLowerCase().contains(query)) option,
    ];
    final hint = widget.searchHint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hint != null) ...[
          HudaSearchField(
            controller: _search,
            hintText: hint,
            onChanged: (value) => setState(() => _query = value),
          ),
          SizedBox(height: space.sm),
        ],
        if (shown.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: space.xl),
            child: Text(
              AppLocalizations.of(context)!.tryDifferentSearch,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (final (i, option) in shown.indexed) ...[
                  if (i > 0) const Divider(indent: 16, endIndent: 16),
                  HudaSettingsRow(
                    key: ValueKey('prayer-pick-${option.token}'),
                    icon: option.icon,
                    title: option.label,
                    selected: option.token == widget.selected,
                    trailing: option.token == widget.selected
                        ? Icon(
                            Icons.check_rounded,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(option.token),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _LocalizedAngleInputFormatter extends TextInputFormatter {
  const _LocalizedAngleInputFormatter();

  static final RegExp _allowedCharacters = RegExp(r'^[0-9٠-٩۰-۹.,٫]*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (!_allowedCharacters.hasMatch(text)) return oldValue;

    final separators =
        '.'.allMatches(text).length +
        ','.allMatches(text).length +
        '٫'.allMatches(text).length;
    if (separators > 1) return oldValue;

    final separatorIndex = text.indexOf(RegExp(r'[.,٫]'));
    if (separatorIndex >= 0 && text.length - separatorIndex - 1 > 1) {
      return oldValue;
    }
    return newValue;
  }
}

/// A method's name for display; "Automatic" names the method it resolves
/// to for [countryCode] ("Automatic (Umm al-Qura)").
String prayerMethodDisplayLabel(
  AppLocalizations l10n,
  String token,
  String countryCode,
) {
  if (token != PrayerTimesCalculator.autoMethodToken) {
    return prayerMethodLabel(l10n, token);
  }
  final resolved = PrayerTimesCalculator.resolveMethod(token, countryCode);
  final autoLabel = prayerMethodLabel(l10n, PrayerTimesCalculator.autoMethodToken);
  final prefix = autoLabel.split('(').first.trim();
  return '$prefix (${prayerMethodLabel(l10n, resolved.name)})';
}

/// The page's card for how the times are calculated: the method, the Asr
/// method and how many times are adjusted; a tap opens the settings. It
/// replaced the app bar's tune button (owner round 2).
class PrayerTimeSettingsCard extends StatelessWidget {
  const PrayerTimeSettingsCard({
    super.key,
    required this.cubit,
    required this.onOpen,
  });

  final PrayerTimesCubit cubit;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final space = context.tokens.space;
    final country = PrayerTimesCalculator.countryCodeFromCache(
      cubit.cacheHelper,
    );
    final method = prayerMethodDisplayLabel(
      l10n,
      cubit.calculationMethodToken,
      country,
    );
    final madhab = cubit.madhabToken == 'hanafi'
        ? l10n.prayerMadhabHanafi
        : l10n.prayerMadhabShafi;
    final adjusted = cubit.prayerOffsets.values.where((v) => v != 0).length;
    final locale = Localizations.localeOf(context).toString();
    return Card(
      child: InkWell(
        key: const ValueKey('prayer-settings'),
        onTap: onOpen,
        child: Padding(
          padding: EdgeInsets.all(space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const HudaIconMark(Icons.tune_rounded),
                  SizedBox(width: space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.prayerSettingsTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          method,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              SizedBox(height: space.sm),
              Wrap(
                spacing: space.xs,
                runSpacing: space.xs,
                children: [
                  _Fact(icon: Icons.balance_rounded, label: madhab),
                  if (adjusted > 0)
                    _Fact(
                      icon: Icons.schedule_rounded,
                      label: l10n.prayerSettingsAdjusted(
                        adjusted,
                        NumberFormat.decimalPattern(locale).format(adjusted),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A setting at a glance on the settings card.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space.xs,
        vertical: tokens.space.xxs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.radius.sm),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          SizedBox(width: tokens.space.xxs),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A calculation method's name, by its token (also used by onboarding's
/// method choice).
String prayerMethodLabel(AppLocalizations l10n, String token) {
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
