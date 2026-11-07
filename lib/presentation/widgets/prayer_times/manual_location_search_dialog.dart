import 'dart:async';
import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_theme_scope.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_search_field.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_attention_items.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_attention_strip.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_setup_checklist.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_sky.dart';
import 'package:huda/data/models/location_search_error.dart';
import 'package:huda/data/models/location_search_suggestion.dart';
import 'package:huda/data/services/location_service.dart';
import 'package:huda/l10n/app_localizations.dart';

class ManualLocationSearchDialog extends StatefulWidget {
  const ManualLocationSearchDialog({super.key, this.service});

  /// The search without the network, for tests and the device matrix.
  @visibleForTesting
  final LocationService? service;

  @override
  State<ManualLocationSearchDialog> createState() =>
      _ManualLocationSearchDialogState();
}

class _ManualLocationSearchDialogState
    extends State<ManualLocationSearchDialog> {
  static const _minimumQueryLength = 2;
  static const _debounceDuration = Duration(milliseconds: 400);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late final LocationService _locationService =
      widget.service ?? LocationService();

  List<LocationSearchSuggestion> _searchResults = const [];
  Timer? _debounce;
  LocationSearchErrorType? _errorType;
  bool _isLoading = false;
  bool _isSelecting = false;
  String? _selectingId;
  LocationSearchErrorType? _selectionError;
  bool _noResults = false;
  int _searchGeneration = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) => _scheduleSearch(query);

  void _onSearchSubmitted(String query) {
    _scheduleSearch(query, immediately: true);
  }

  void _scheduleSearch(String rawQuery, {bool immediately = false}) {
    _debounce?.cancel();

    final query = rawQuery.trim();
    final generation = ++_searchGeneration;
    if (query.length < _minimumQueryLength) {
      setState(() {
        _searchResults = const [];
        _errorType = null;
        _isLoading = false;
        _noResults = false;
      });
      return;
    }

    setState(() {
      _searchResults = const [];
      _errorType = null;
      _isLoading = true;
      _noResults = false;
    });

    if (immediately) {
      unawaited(_performSearch(query, generation));
    } else {
      _debounce = Timer(
        _debounceDuration,
        () => _performSearch(query, generation),
      );
    }
  }

  Future<void> _performSearch(String query, int generation) async {
    final languageCode = Localizations.localeOf(context).languageCode;

    try {
      final results = await _locationService.searchCity(
        query,
        languageCode: languageCode,
      );
      if (!_isCurrentSearch(generation)) return;

      setState(() {
        _searchResults = results;
        _noResults = results.isEmpty;
      });
    } on LocationSearchException catch (error) {
      if (!_isCurrentSearch(generation)) return;

      setState(() {
        _errorType = error.type;
        _searchResults = const [];
      });
    } catch (_) {
      if (!_isCurrentSearch(generation)) return;

      setState(() {
        _errorType = LocationSearchErrorType.unknown;
        _searchResults = const [];
      });
    } finally {
      if (_isCurrentSearch(generation)) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isCurrentSearch(int generation) {
    return mounted && generation == _searchGeneration;
  }

  Future<void> _selectSuggestion(LocationSearchSuggestion suggestion) async {
    if (_isSelecting) return;

    setState(() {
      _isSelecting = true;
      _selectingId = suggestion.placeId;
      _selectionError = null;
      _errorType = null;
    });

    var selected = false;
    final languageCode = Localizations.localeOf(context).languageCode;
    try {
      final location = await _locationService.resolveCity(
        suggestion,
        languageCode: languageCode,
      );
      if (!mounted) return;

      selected = true;
      Navigator.of(context).pop(location);
    } on LocationSearchException catch (error) {
      if (mounted) _showSelectionError(error.type);
    } catch (_) {
      if (mounted) _showSelectionError(LocationSearchErrorType.unknown);
    } finally {
      if (mounted && !selected) {
        setState(() {
          _isSelecting = false;
          _selectingId = null;
        });
      }
    }
  }

  // Shown in the sheet, above the results (a snack bar would sit behind
  // the sheet).
  void _showSelectionError(LocationSearchErrorType type) {
    setState(() => _selectionError = type);
  }

  void _retrySearch() {
    _scheduleSearch(_searchController.text, immediately: true);
  }

  String _errorMessage(AppLocalizations l10n, LocationSearchErrorType type) {
    switch (type) {
      case LocationSearchErrorType.rateLimit:
        return l10n.tooManyRequests;
      case LocationSearchErrorType.noConnection:
        return l10n.noInternetSettings;
      case LocationSearchErrorType.server:
      case LocationSearchErrorType.unknown:
        return l10n.somethingWentWrong;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final media = MediaQuery.of(context);
    // Above the keyboard, or the navigation bar when there's none.
    final bottom = max(media.viewInsets.bottom, media.padding.bottom);
    // The night band follows the sheet's or dialog's rounded top.
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(tokens.radius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CitySearchHeader(
            title: l10n.prayerChooseCity,
            closeEnabled: !_isSelecting,
            field: HudaSearchField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              hintText: l10n.searchCityHint,
              onChanged: (query) {
                if (_selectionError != null) {
                  setState(() => _selectionError = null);
                }
                _onSearchChanged(query);
              },
              onSubmitted: _onSearchSubmitted,
            ),
          ),
          if (_selectionError != null)
            Padding(
              padding: EdgeInsets.fromLTRB(space.lg, space.md, space.lg, 0),
              child: PrayerSetupWarningNote(
                tone: PrayerAttentionTone.error,
                title: l10n.prayerChooseCity,
                text: _errorMessage(l10n, _selectionError!),
                icon: Icons.error_outline_rounded,
              ),
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottom),
              child: HudaStateSwitcher(
                stateKey: _contentKey,
                child: _buildSearchContent(l10n),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _contentKey => _isLoading
      ? 'loading'
      : _errorType != null
      ? 'error'
      : _noResults
      ? 'none'
      : _searchResults.isEmpty
      ? 'hint'
      : 'results';

  Widget _buildSearchContent(AppLocalizations l10n) {
    final space = context.tokens.space;
    if (_isLoading) return const _CitySkeleton();
    if (_errorType != null) {
      return _status(
        error: true,
        message: _errorMessage(l10n, _errorType!),
        action: FilledButton.icon(
          onPressed: _retrySearch,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(l10n.tryAgain),
        ),
      );
    }
    if (_noResults) return _status(message: l10n.noResultsFound);
    if (_searchResults.isEmpty) return _status(message: l10n.typeCityNameHint);
    final query = _searchController.text.trim();
    return Scrollbar(
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(space.sm, space.sm, space.sm, space.md),
        itemCount: _searchResults.length,
        separatorBuilder: (_, _) => const Divider(indent: 64, endIndent: 16),
        itemBuilder: (context, index) {
          final suggestion = _searchResults[index];
          return HudaReveal(
            index: index,
            child: _CityRow(
              key: ValueKey('city-${suggestion.placeId}'),
              suggestion: suggestion,
              query: query,
              selecting: _selectingId == suggestion.placeId,
              onTap: _isSelecting ? null : () => _selectSuggestion(suggestion),
            ),
          );
        },
      ),
    );
  }

  /// The quiet states (hint, nothing found) under the horizon; an error
  /// leads with the lamp, as every Prayer problem does.
  Widget _status({
    required String message,
    bool error = false,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    final space = context.tokens.space;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(space.xl, space.xl, space.xl, space.lg),
      child: Column(
        children: [
          if (error) ...[
            const PrayerNoticeLamp(tone: PrayerAttentionTone.error),
            SizedBox(height: space.sm),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[SizedBox(height: space.md), action],
        ],
      ),
    );
  }
}

/// The search's night band: the title and Close over the horizon, where a
/// gilt pin settles onto the day path, then the search field on the
/// chrome.
class _CitySearchHeader extends StatelessWidget {
  const _CitySearchHeader({
    required this.title,
    required this.field,
    required this.closeEnabled,
  });

  final String title;
  final Widget field;
  final bool closeEnabled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    return HudaNight(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Stack(
            children: [
              // The page's living sky (a plain day at the device's time
              // when the search opens from somewhere without one).
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    final scope = PrayerSkyScope.maybeOf(context);
                    return PrayerSky(
                      times: scope?.times ?? PrayerSkyTimes.fallback,
                      hour: scope?.hour ?? prayerSkyHour(DateTime.now()),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  space.lg,
                  space.sm,
                  space.xs,
                  space.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: tokens.onChrome,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          color: tokens.onChrome,
                          onPressed: closeEnabled
                              ? () => Navigator.of(context).maybePop()
                              : null,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    // Short windows keep the room for the results.
                    if (MediaQuery.sizeOf(context).height >= 480)
                      const _PinOnHorizon()
                    else
                      SizedBox(height: space.xs),
                    Padding(
                      padding: EdgeInsetsDirectional.only(end: space.sm),
                      // The field on the chrome: a raised tint of the band,
                      // not the night's near-black surface.
                      child: Theme(
                        data: theme.copyWith(
                          colorScheme: theme.colorScheme.copyWith(
                            surfaceContainerLowest: Color.alphaBlend(
                              tokens.onChrome.withValues(alpha: 0.1),
                              tokens.chrome,
                            ),
                          ),
                        ),
                        child: field,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The horizon with its hour ticks and a faint day path; a gilt pin drops
/// onto it once the search has opened (500 ms, once). Reduce motion: in
/// place.
class _PinOnHorizon extends StatelessWidget {
  const _PinOnHorizon();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      height: 64,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduce ? 1 : 0, end: 1),
        // Once the sheet has landed (~250 ms), the pin settles (500 ms).
        duration: reduce ? Duration.zero : const Duration(milliseconds: 750),
        curve: const Interval(0.33, 1, curve: Curves.easeOutBack),
        builder: (context, t, _) => Ornament(
          painter: _PinHorizonPainter(
            drop: t,
            gilt: tokens.gilt,
            onChrome: tokens.onChrome,
          ),
        ),
      ),
    );
  }
}

class _PinHorizonPainter extends CustomPainter {
  _PinHorizonPainter({
    required this.drop,
    required this.gilt,
    required this.onChrome,
  });

  final double drop;
  final Color gilt;
  final Color onChrome;

  @override
  void paint(Canvas canvas, Size size) {
    final ground = size.height * 0.86;
    final cx = size.width / 2;
    // Its light on the ground, once it has landed.
    final landed = drop.clamp(0.0, 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, ground),
        width: 10 + 26 * landed,
        height: 4 + 5 * landed,
      ),
      Paint()..color = gilt.withValues(alpha: 0.35 * landed),
    );
    // The pin: a teardrop whose point rests on the ground.
    final tip = Offset(cx, ground - (1 - drop) * 26);
    const r = 9.0;
    final head = Offset(tip.dx, tip.dy - r * 2.1);
    final pin = Path()
      ..moveTo(tip.dx, tip.dy)
      ..cubicTo(
        tip.dx - r * 0.6,
        tip.dy - r * 0.9,
        head.dx - r,
        head.dy + r * 0.6,
        head.dx - r,
        head.dy,
      )
      ..arcToPoint(
        Offset(head.dx + r, head.dy),
        radius: const Radius.circular(r),
      )
      ..cubicTo(
        head.dx + r,
        head.dy + r * 0.6,
        tip.dx + r * 0.6,
        tip.dy - r * 0.9,
        tip.dx,
        tip.dy,
      )
      ..close();
    canvas.drawPath(pin, Paint()..color = gilt);
    canvas.drawCircle(
      head,
      r * 0.38,
      Paint()..color = Color.lerp(gilt, onChrome, 0.6)!,
    );
  }

  @override
  bool shouldRepaint(covariant _PinHorizonPainter old) =>
      old.drop != drop || old.gilt != gilt || old.onChrome != onChrome;
}

/// A result: a station on its little horizon, the city with the typed part
/// in the reading color, the country under it; while it's being used, the
/// lamp turns in its place.
class _CityRow extends StatelessWidget {
  const _CityRow({
    super.key,
    required this.suggestion,
    required this.query,
    required this.selecting,
    required this.onTap,
  });

  final LocationSearchSuggestion suggestion;
  final String query;
  final bool selecting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final name = suggestion.primaryText;
    final start = query.isEmpty
        ? -1
        : name.toLowerCase().indexOf(query.toLowerCase());
    final base = theme.textTheme.titleMedium?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w400,
    );
    final title = start < 0
        ? TextSpan(text: name)
        : TextSpan(
            children: [
              TextSpan(text: name.substring(0, start)),
              TextSpan(
                text: name.substring(start, start + query.length),
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(text: name.substring(start + query.length)),
            ],
          );
    return Semantics(
      button: true,
      label: suggestion.displayName,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: space.sm,
              vertical: space.xs,
            ),
            child: Row(
              children: [
                Ornament(
                  size: const Size(36, 36),
                  painter: _StationMarkPainter(
                    line: tokens.ornament,
                    fill: selecting ? scheme.primary : null,
                  ),
                ),
                SizedBox(width: space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(title, style: base),
                      if (suggestion.secondaryText.isNotEmpty)
                        Text(
                          suggestion.secondaryText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: space.xs),
                SizedBox.square(
                  dimension: 24,
                  child: AnimatedSwitcher(
                    duration: tokens.motion.of(context, tokens.motion.short),
                    child: selecting
                        ? HudaLampSpinner(
                            key: const ValueKey('busy'),
                            size: 22,
                            color: scheme.primary,
                          )
                        : Icon(
                            Icons.chevron_right_rounded,
                            key: const ValueKey('go'),
                            color: scheme.onSurfaceVariant,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A station: a short horizon, a gnomon and its roundel (filled while the
/// city is being used).
class _StationMarkPainter extends CustomPainter {
  _StationMarkPainter({required this.line, this.fill});

  final Color line;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * 0.78;
    final stroke = Paint()
      ..color = line
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(w * 0.12, horizon),
      Offset(w * 0.88, horizon),
      stroke,
    );
    final top = Offset(w / 2, h * 0.32);
    canvas.drawLine(Offset(w / 2, horizon), top, stroke..strokeWidth = 1);
    final fill = this.fill;
    if (fill != null) canvas.drawCircle(top, 5, Paint()..color = fill);
    canvas.drawCircle(
      top,
      5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = fill ?? line,
    );
  }

  @override
  bool shouldRepaint(covariant _StationMarkPainter old) =>
      old.line != line || old.fill != fill;
}

/// Searching: rows shaped like results.
class _CitySkeleton extends StatelessWidget {
  const _CitySkeleton();

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(space.lg, space.md, space.lg, space.md),
      child: HudaSkeleton(
        child: Column(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) SizedBox(height: space.lg),
              Row(
                children: [
                  const HudaSkeletonBlock(width: 28, height: 28, circle: true),
                  SizedBox(width: space.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HudaSkeletonBlock(width: 140, height: 16),
                        SizedBox(height: 6),
                        HudaSkeletonBlock(width: 90, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// What happened after [pickPrayerCity]: whether a city was picked, and if
/// so what stopped it from being used (null once the times follow it).
typedef PrayerCityPick = ({bool picked, PrayerLocationProblem? problem});

/// Opens the city search and, when a city is picked, uses it (the
/// "A city I choose" mode). The one way every screen picks a city.
///
/// [onPicked] runs once a city is picked, before it's applied (to show the
/// caller's own busy state only while the place is being used).
Future<PrayerCityPick> pickPrayerCity(
  BuildContext context,
  PrayerTimesCubit cubit, {
  VoidCallback? onPicked,
  // The search without the network (tests and the device matrix).
  LocationService? service,
}) async {
  // The sheet is its own route: it takes the page's sky along.
  final scope = PrayerSkyScope.maybeOf(context);
  final result = await showHudaSheet<Map<String, dynamic>>(
    context: context,
    title: AppLocalizations.of(context)!.prayerChooseCity,
    expand: true,
    builder: (_) => scope == null
        ? ManualLocationSearchDialog(service: service)
        : PrayerSkyScope(
            times: scope.times,
            hour: scope.hour,
            child: ManualLocationSearchDialog(service: service),
          ),
  );
  final lat = result?['lat'];
  final lon = result?['lon'];
  if (lat is! num || lon is! num) return (picked: false, problem: null);
  onPicked?.call();
  final problem = await cubit.setManualLocation(
    lat.toDouble(),
    lon.toDouble(),
    cityName: result!['name'] as String?,
    countryCode: result['country_code'] as String?,
  );
  return (picked: true, problem: problem);
}
