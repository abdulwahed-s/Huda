import 'dart:async';
import 'dart:math' show max, min;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/location_search_error.dart';
import 'package:huda/data/models/location_search_suggestion.dart';
import 'package:huda/data/services/location_service.dart';
import 'package:huda/l10n/app_localizations.dart';

class ManualLocationSearchDialog extends StatefulWidget {
  const ManualLocationSearchDialog({super.key});

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
  final LocationService _locationService = LocationService();

  List<LocationSearchSuggestion> _searchResults = const [];
  Timer? _debounce;
  LocationSearchErrorType? _errorType;
  bool _isLoading = false;
  bool _isSelecting = false;
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
        setState(() => _isSelecting = false);
      }
    }
  }

  void _showSelectionError(LocationSearchErrorType type) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_errorMessage(l10n, type))),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _scheduleSearch('');
    _searchFocusNode.requestFocus();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.sizeOf(context);
    final availableHeight =
        screenSize.height - MediaQuery.viewInsetsOf(context).vertical;
    final dialogHeight = min(max(availableHeight - 48.0, 0.0), 560.0);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      child: SizedBox(
        width: min(screenSize.width - 32.0, 520.0),
        height: dialogHeight,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 16.h),
          child: Column(
            children: [
              _buildHeader(context, l10n),
              SizedBox(height: 18.h),
              _buildSearchField(context, l10n, isDark),
              SizedBox(height: 12.h),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildSearchContent(l10n, isDark)),
                    if (_isSelecting)
                      Positioned.fill(
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.24),
                          child: Center(
                            child: Semantics(
                              liveRegion: true,
                              label: l10n.searchLocationTitle,
                              child: CircularProgressIndicator(
                                color: context.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      namesRoute: true,
      label: l10n.searchLocationTitle,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.travel_explore_rounded,
              color: context.primaryColor,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              l10n.searchLocationTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            style: IconButton.styleFrom(
              backgroundColor: colors.onSurface.withValues(alpha: 0.06),
              foregroundColor: colors.onSurfaceVariant,
            ),
            icon: const Icon(Icons.close_rounded),
            onPressed: _isSelecting ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final colors = Theme.of(context).colorScheme;
    final fieldColor = colors.surfaceContainerHighest.withValues(
      alpha: isDark ? 0.42 : 0.62,
    );
    final outlineColor = colors.outlineVariant.withValues(
      alpha: isDark ? 0.56 : 0.72,
    );

    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      autofocus: true,
      enabled: !_isSelecting,
      textInputAction: TextInputAction.search,
      onChanged: _onSearchChanged,
      onSubmitted: _onSearchSubmitted,
      style: TextStyle(
        color: colors.onSurface,
        fontSize: 16.sp,
      ),
      decoration: InputDecoration(
        hintText: l10n.searchCityHint,
        hintStyle: TextStyle(
          color: colors.onSurfaceVariant,
          fontSize: 14.sp,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: context.primaryColor,
        ),
        suffixIcon: _isLoading
            ? Padding(
                padding: EdgeInsets.all(14.w),
                child: SizedBox(
                  height: 18.w,
                  width: 18.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.primaryColor,
                  ),
                ),
              )
            : _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.clear,
                    onPressed: _clearSearch,
                    icon: Icon(
                      Icons.cancel_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
        filled: true,
        fillColor: fieldColor,
        contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: outlineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: outlineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: context.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildSearchContent(AppLocalizations l10n, bool isDark) {
    if (_isLoading) {
      return _buildLoadingState(isDark);
    }

    if (_errorType != null) {
      return _buildStatus(
        icon: Icons.cloud_off_rounded,
        message: _errorMessage(l10n, _errorType!),
        isDark: isDark,
        action: FilledButton.tonalIcon(
          onPressed: _retrySearch,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.tryAgain),
        ),
      );
    }

    if (_noResults) {
      return _buildStatus(
        icon: Icons.search_off_rounded,
        message: l10n.noResultsFound,
        isDark: isDark,
      );
    }

    if (_searchResults.isEmpty) {
      return _buildStatus(
        icon: Icons.location_city_outlined,
        message: l10n.typeCityNameHint,
        isDark: isDark,
      );
    }

    return Scrollbar(
      child: ListView.separated(
        padding: EdgeInsets.only(top: 4.h, bottom: 8.h),
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) => SizedBox(height: 8.h),
        itemBuilder: (context, index) =>
            _buildSuggestionTile(_searchResults[index], isDark),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Semantics(
        liveRegion: true,
        label: AppLocalizations.of(context)!.searchLocationTitle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 28.w,
              width: 28.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: context.primaryColor,
              ),
            ),
            SizedBox(height: 18.h),
            Container(
              width: 124.w,
              height: 8.h,
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(
                  alpha: isDark ? 0.12 : 0.08,
                ),
                borderRadius: BorderRadius.circular(99.r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus({
    required IconData icon,
    required String message,
    required bool isDark,
    Widget? action,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Semantics(
        liveRegion: true,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(
                    alpha: isDark ? 0.16 : 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 34.sp,
                  color: context.primaryColor,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 15.sp,
                  height: 1.4,
                ),
              ),
              if (action != null) ...[
                SizedBox(height: 18.h),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(
    LocationSearchSuggestion suggestion,
    bool isDark,
  ) {
    final colors = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final radius = BorderRadius.circular(16.r);

    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.38 : 0.52,
            ),
            border: Border.all(
              color: colors.outlineVariant.withValues(
                alpha: isDark ? 0.42 : 0.56,
              ),
            ),
            borderRadius: radius,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: _isSelecting ? null : () => _selectSuggestion(suggestion),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(9.w),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_city_rounded,
                      color: context.primaryColor,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          suggestion.primaryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (suggestion.secondaryText.isNotEmpty) ...[
                          SizedBox(height: 3.h),
                          Text(
                            suggestion.secondaryText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 13.sp,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    isRtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
