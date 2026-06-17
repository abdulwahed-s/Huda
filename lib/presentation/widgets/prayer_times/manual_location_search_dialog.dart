import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/location_search_error.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;
  LocationSearchErrorType? _errorType;
  bool _noResults = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorType = null;
        _noResults = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 600), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _errorType = null;
      _noResults = false;
    });

    try {
      final results = await _locationService.searchCity(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _noResults = results.isEmpty;
      });
    } on LocationSearchException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorType = e.type;
        _searchResults = [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorType = LocationSearchErrorType.unknown;
        _searchResults = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      child: Container(
        width: 1.sw * 0.9,
        height: 1.sh * 0.7,
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.searchLocationTitle,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      color: isDark ? Colors.white70 : Colors.black54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16.sp,
              ),
              decoration: InputDecoration(
                hintText: l10n.searchCityHint,
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black38,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: context.primaryColor,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
              ),
            ),
            SizedBox(height: 16.h),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorType != null)
              Expanded(
                child: Center(
                  child: Text(
                    _errorMessage(l10n, _errorType!),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              )
            else if (_noResults)
              Expanded(
                child: Center(
                  child: Text(
                    l10n.noResultsFound,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              )
            else if (_searchResults.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_city,
                        size: 64.sp,
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        l10n.typeCityNameHint,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => Divider(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: context.primaryColor,
                          size: 20.sp,
                        ),
                      ),
                      title: Text(
                        result['name'],
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Lat: ${result['lat'].toStringAsFixed(4)}, Lon: ${result['lon'].toStringAsFixed(4)}',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 12.sp,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop({
                          'lat': result['lat'],
                          'lon': result['lon'],
                        });
                      },
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
