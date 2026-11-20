import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/prayer_times_calculator.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_frame.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_time_adjustment_bottom_sheet.dart'
    show prayerMethodLabel;
import 'package:intl/intl.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';

const Set<String> onboardingHanafiCountries = {
  'PK', 'IN', 'BD', 'AF', 'TR', 'UZ', 'TJ', 'KZ', 'KG', 'TM', 'BA', 'AL',
  'XK', 'MK',
};

const Set<String> onboardingHanafiLanguages = {'ur', 'bn', 'tr'};

({String token, bool suggested}) onboardingAsrSuggestion({
  required String savedToken,
  required String? countryCode,
  required String languageCode,
}) {
  if (savedToken == 'hanafi') return (token: 'hanafi', suggested: false);
  final country = countryCode?.trim().toUpperCase() ?? '';
  final hanafi = country.isNotEmpty
      ? onboardingHanafiCountries.contains(country)
      : onboardingHanafiLanguages.contains(languageCode);
  return hanafi
      ? (token: 'hanafi', suggested: true)
      : (token: PrayerTimesCalculator.defaultMadhabToken, suggested: false);
}

const List<String> onboardingCommonMethods = [
  'muslimWorldLeague',
  'ummAlQura',
  'egyptian',
  'karachi',
  'northAmerica',
  'turkey',
];

class AsrStep extends StatefulWidget {
  const AsrStep({super.key});

  @override
  State<AsrStep> createState() => _AsrStepState();
}

class _AsrStepState extends State<AsrStep> {
  late final ({String token, bool suggested}) _suggestion = _suggest();
  late String _token = _suggestion.token;
  late String _method = context.read<PrayerTimesCubit>().calculationMethodToken;

  late bool _showMethods = _method != PrayerTimesCalculator.autoMethodToken;
  final _methodsKey = GlobalKey(debugLabel: 'onboarding-methods');

  void _scrollToMethods() {
    final tokens = context.tokens;
    final wait = tokens.motion.of(context, tokens.motion.medium);
    Future<void>.delayed(wait + const Duration(milliseconds: 16), () {
      final target = _methodsKey.currentContext;
      if (!mounted || target == null || !target.mounted) return;
      Scrollable.ensureVisible(
        target,
        duration: tokens.motion.of(context, tokens.motion.medium),
        curve: tokens.motion.standard,
      );
    });
  }

  bool _saving = false;

  String get _country =>
      OnboardingScope.read(context).environment.cache.getDataString(
        key: PrayerTimesCalculator.countryCodeKey,
      ) ??
      '';

  ({String token, bool suggested}) _suggest() {
    final cubit = context.read<PrayerTimesCubit>();
    final state = cubit.state;
    final placemarkCountry =
        state is PrayerTimesLoaded && state.placemarks.isNotEmpty
        ? state.placemarks.first.isoCountryCode
        : null;
    final cache = OnboardingScope.read(context).environment.cache;
    return onboardingAsrSuggestion(
      savedToken: cubit.madhabToken,
      countryCode:
          placemarkCountry ??
          cache.getDataString(key: PrayerTimesCalculator.countryCodeKey),
      languageCode: Localizations.localeOf(context).languageCode,
    );
  }

  DateTime? _asr(Madhab madhab) {
    final cubit = context.read<PrayerTimesCubit>();
    final cache = OnboardingScope.read(context).environment.cache;
    final coordinates = PrayerTimesCalculator.coordinatesFromCache(cache);
    if (coordinates == null) return null;
    try {
      return PrayerTimesCalculator.compute(
        coordinates,
        DateTime.now(),
        methodToken: _method,
        countryCode: _country,
        timeZoneName: cubit.prayerTimeZoneId,
        madhab: madhab,
        highLatitudeRule: PrayerTimesCalculator.highLatitudeRuleFromToken(
          cubit.highLatitudeRuleToken,
        ),
        customAngles: cubit.customPrayerAngles,
      ).asr;
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    final cubit = context.read<PrayerTimesCubit>();
    final onboarding = context.read<OnboardingCubit>();
    if (_token != cubit.madhabToken ||
        _method != cubit.calculationMethodToken) {
      setState(() => _saving = true);
      try {
        await cubit.savePrayerSettings(
          methodToken: _method,
          madhabToken: _token,
          highLatToken: cubit.highLatitudeRuleToken,
          offsets: cubit.prayerOffsets,
          customAngles: cubit.customPrayerAngles,
        );
      } catch (error) {
        debugPrint('Onboarding calculation not saved: $error');
      }
      if (!mounted) return;
      setState(() => _saving = false);
    }
    if (!mounted) return;
    onboarding.next();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    context.watch<PrayerTimesCubit>();
    final locale = Localizations.localeOf(context).toString();
    String? today(Madhab madhab) {
      final time = _asr(madhab);
      return time == null
          ? null
          : '${l10n.today} · ${DateFormat.jm(locale).format(time)}';
    }

    final hanafi = _token == 'hanafi';
    final resolved = PrayerTimesCalculator.resolveMethod(
      PrayerTimesCalculator.autoMethodToken,
      _country,
    ).name;
    final others = [
      ...onboardingCommonMethods,
      for (final token in PrayerTimesCalculator.pickerMethodTokens)
        if (token != PrayerTimesCalculator.autoMethodToken &&
            token != 'other' &&
            !onboardingCommonMethods.contains(token))
          token,
    ];
    return OnboardingStepFrame(
      message: l10n.setupAsrMessage,
      primary: OnboardingAction(
        l10n.continueButton,
        advances: true,
        busyLabel: _saving ? l10n.prayerAlertSaving : null,
        onPressed: _save,
      ),
      children: [
        HudaEyebrow(l10n.asr, header: true),
        SizedBox(height: space.sm),
        OnboardingOptionGrid(
          minTileWidth: 150,
          children: [
            OnboardingOption(
              key: const ValueKey('onboarding-asr-standard'),
              title: l10n.setupAsrStandard,
              subtitle:
                  '${l10n.setupAsrStandardSchools}\n${l10n.setupAsrShadowOnce}',
              detail: today(Madhab.shafi),
              selected: !hanafi,
              previewAbove: true,
              preview: AsrShadowDiagram(lengths: 1, lit: !hanafi),
              badge: _suggestion.suggested && _suggestion.token != 'hanafi'
                  ? l10n.setupSuggested
                  : null,
              onTap: () => setState(
                () => _token = PrayerTimesCalculator.defaultMadhabToken,
              ),
            ),
            OnboardingOption(
              key: const ValueKey('onboarding-asr-hanafi'),
              title: l10n.prayerMadhabHanafi,
              subtitle:
                  '${l10n.setupAsrHanafiNote}\n${l10n.setupAsrShadowTwice}',
              detail: today(Madhab.hanafi),
              selected: hanafi,
              previewAbove: true,
              preview: AsrShadowDiagram(lengths: 2, lit: hanafi),
              badge: _suggestion.suggested && _suggestion.token == 'hanafi'
                  ? l10n.setupSuggested
                  : null,
              onTap: () => setState(() => _token = 'hanafi'),
            ),
          ],
        ),
        SizedBox(height: space.xl),
        HudaEyebrow(l10n.prayerCalculationMethod, header: true),
        SizedBox(height: space.sm),
        OnboardingOption(
          key: const ValueKey('onboarding-method-auto'),
          title: l10n.prayerMethodAuto,
          subtitle: l10n.setupMethodUses(prayerMethodLabel(l10n, resolved)),
          badge: l10n.setupSuggested,
          selected: _method == PrayerTimesCalculator.autoMethodToken,
          onTap: () =>
              setState(() => _method = PrayerTimesCalculator.autoMethodToken),
        ),
        SizedBox(height: space.xs),
        Text(
          l10n.setupCalcMessage,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: space.sm),
        HudaCard(
          key: const ValueKey('onboarding-method-change'),
          padding: EdgeInsets.zero,
          onTap: () {
            setState(() => _showMethods = !_showMethods);
            if (!_showMethods) return;
            _scrollToMethods();
          },
          child: Semantics(
            expanded: _showMethods,
            child: HudaSettingsRow(
              icon: Icons.tune_rounded,
              title: l10n.setupMethodOther,
              subtitle: _method == PrayerTimesCalculator.autoMethodToken
                  ? null
                  : prayerMethodLabel(l10n, _method),
              trailing: AnimatedRotation(
                turns: _showMethods ? 0.5 : 0,
                duration: context.tokens.motion.of(
                  context,
                  context.tokens.motion.short,
                ),
                child: const Icon(Icons.expand_more_rounded),
              ),
            ),
          ),
        ),
        HudaStateSwitcher(
          stateKey: _showMethods,
          child: !_showMethods
              ? const SizedBox(width: double.infinity)
              : Padding(
                  key: _methodsKey,
                  padding: EdgeInsets.only(top: space.sm),
                  child: _MethodList(
                    onFocus: _scrollToMethods,
                    tokens: others,
                    selected: _method,
                    onSelected: (token) => setState(() => _method = token),
                  ),
                ),
        ),
      ],
    );
  }
}

class _MethodList extends StatefulWidget {
  const _MethodList({
    required this.onFocus,
    required this.tokens,
    required this.selected,
    required this.onSelected,
  });

  final VoidCallback onFocus;
  final List<String> tokens;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  State<_MethodList> createState() => _MethodListState();
}

class _MethodListState extends State<_MethodList> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus) widget.onFocus();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final shown = [
      for (final token in widget.tokens)
        if (query.isEmpty ||
            prayerMethodLabel(l10n, token).toLowerCase().contains(query) ||
            token.toLowerCase().contains(query))
          token,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('onboarding-method-search'),
          controller: _search,
          focusNode: _focus,
          onChanged: (value) => setState(() => _query = value),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.setupMethodSearch,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).deleteButtonTooltip,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() {
                      _search.clear();
                      _query = '';
                    }),
                  ),
          ),
        ),
        SizedBox(height: space.sm),
        HudaStateSwitcher(
          stateKey: shown.isEmpty,
          child: shown.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: space.md),
                  child: Text(
                    l10n.noResultsFound,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : OnboardingOptionGrid(
                  minTileWidth: 150,
                  maxColumns: 3,
                  children: [
                    for (final token in shown)
                      OnboardingOption(
                        key: ValueKey('onboarding-method-$token'),
                        title: prayerMethodLabel(l10n, token),
                        selected: widget.selected == token,
                        onTap: () => widget.onSelected(token),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class AsrShadowDiagram extends StatelessWidget {
  const AsrShadowDiagram({super.key, required this.lengths, this.lit = false});

  final int lengths;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 2,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              tokens.gilt.withValues(alpha: dark ? 0.08 : 0.06),
              scheme.surfaceContainerLow,
            ),
            borderRadius: BorderRadius.circular(tokens.radius.sm),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: lit ? 1 : 0),
            duration: tokens.motion.of(context, tokens.motion.medium),
            builder: (context, t, _) => CustomPaint(
              painter: _ShadowPainter(
                lengths: lengths,
                line: Color.lerp(scheme.onSurfaceVariant, scheme.primary, t)!,
                shadow: Color.lerp(
                  scheme.onSurfaceVariant.withValues(alpha: 0.35),
                  scheme.primary.withValues(alpha: 0.55),
                  t,
                )!,
                sun: scheme.tertiary,
                ghost: scheme.outline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShadowPainter extends CustomPainter {
  const _ShadowPainter({
    required this.lengths,
    required this.line,
    required this.shadow,
    required this.sun,
    required this.ghost,
  });

  final int lengths;
  final Color line;
  final Color shadow;
  final Color sun;
  final Color ghost;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ground = h * 0.84;
    final stick = h * 0.5;
    final base = Offset(w * 0.3, ground);
    final top = Offset(base.dx, ground - stick);
    final unit = math.min(stick, w * 0.3);
    final end = Offset(base.dx + unit * lengths, ground);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5
      ..color = line;

    canvas.drawLine(
      Offset(w * 0.06, ground),
      Offset(w * 0.94, ground),
      Paint()
        ..strokeWidth = 1
        ..color = ghost,
    );
    final other = Offset(base.dx + unit * (lengths == 1 ? 2 : 1), ground);
    canvas.drawLine(
      other.translate(0, -h * 0.06),
      other.translate(0, h * 0.06),
      Paint()
        ..strokeWidth = 1
        ..color = ghost,
    );
    canvas.drawLine(
      base,
      end,
      Paint()
        ..strokeWidth = math.max(4, h * 0.07)
        ..strokeCap = StrokeCap.round
        ..color = shadow,
    );
    canvas.drawLine(
      end.translate(0, -h * 0.08),
      end.translate(0, h * 0.08),
      stroke,
    );
    final direction = top - end;
    final sunAt = top + direction * (0.42 / lengths);
    final ray = Paint()
      ..strokeWidth = 1
      ..color = sun.withValues(alpha: 0.6);
    const dashes = 7;
    for (var i = 0; i < dashes; i++) {
      final a = Offset.lerp(sunAt, end, i / dashes)!;
      final b = Offset.lerp(sunAt, end, (i + 0.5) / dashes)!;
      canvas.drawLine(a, b, ray);
    }
    canvas.drawCircle(sunAt, h * 0.08, Paint()..color = sun);
    canvas.drawLine(base, top, stroke..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(_ShadowPainter old) =>
      old.lengths != lengths ||
      old.line != line ||
      old.shadow != shadow ||
      old.sun != sun ||
      old.ghost != ghost;
}
