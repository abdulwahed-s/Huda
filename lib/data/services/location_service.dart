import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/data/api/nominatim_service.dart';
import 'package:huda/data/models/location_search_error.dart';
import 'package:huda/data/models/location_search_suggestion.dart';
import 'package:huda/data/models/placemark_model.dart';

class LocationService {
  final NominatimService _nominatimService;

  LocationService({NominatimService? nominatimService})
      : _nominatimService = nominatimService ?? NominatimService();

  Future<List<Placemark>> getPlacemarks(double lat, double lon) async {
    if (PlatformUtils.isMobile) {
      return await placemarkFromCoordinates(lat, lon);
    } else {
      try {
        final placemarkModel = await _nominatimService.getPlacemark(lat, lon);

        final result = _findBestResult(placemarkModel.results);

        if (result == null) {
          return [const Placemark(name: 'Unknown Location')];
        }

        final components = result.addressComponents ?? [];
        final addressMap = _parseAddressComponents(components);

        return [
          Placemark(
            name: result.formattedAddress ?? addressMap['name'] ?? '',
            street: addressMap['street'] ?? addressMap['route'] ?? '',
            isoCountryCode: addressMap['country_code'] ?? '',
            country: addressMap['country'] ?? '',
            postalCode: addressMap['postal_code'] ?? '',
            administrativeArea: addressMap['administrative_area_level_1'] ?? '',
            subAdministrativeArea:
                addressMap['administrative_area_level_2'] ?? '',
            locality: addressMap['locality'] ?? '',
            subLocality:
                addressMap['sublocality'] ?? addressMap['neighborhood'] ?? '',
            thoroughfare: addressMap['route'] ?? '',
            subThoroughfare: addressMap['street_number'] ?? '',
          )
        ];
      } catch (e) {
        throw Exception('Failed to get placemark from Google Maps: $e');
      }
    }
  }

  Results? _findBestResult(List<Results>? results) {
    if (results == null || results.isEmpty) return null;

    final priorityTypes = [
      'establishment',
      'gym',
      'health',
      'point_of_interest',
      'locality',
      'neighborhood',
      'route',
      'administrative_area_level_1',
      'country'
    ];

    for (final type in priorityTypes) {
      final result = results.firstWhere(
        (r) => r.types?.contains(type) ?? false,
        orElse: () => Results(),
      );
      if (result.types != null && result.types!.isNotEmpty) {
        return result;
      }
    }

    return results.first;
  }

  Map<String, String> _parseAddressComponents(
      List<AddressComponents> components) {
    final map = <String, String>{};

    for (final component in components) {
      final types = component.types ?? [];
      final longName = component.longName ?? '';
      final shortName = component.shortName ?? '';

      if (types.contains('country')) {
        map['country'] = longName;
        map['country_code'] = shortName;
      } else if (types.contains('administrative_area_level_1')) {
        map['administrative_area_level_1'] = longName;
      } else if (types.contains('administrative_area_level_2')) {
        map['administrative_area_level_2'] = longName;
      } else if (types.contains('locality')) {
        map['locality'] = longName;
      } else if (types.contains('sublocality') ||
          types.contains('sublocality_level_1')) {
        map['sublocality'] = longName;
      } else if (types.contains('neighborhood')) {
        map['neighborhood'] = longName;
      } else if (types.contains('route')) {
        map['route'] = longName;
      } else if (types.contains('street_number')) {
        map['street_number'] = longName;
      } else if (types.contains('postal_code')) {
        map['postal_code'] = longName;
      }
    }

    return map;
  }

  Future<List<LocationSearchSuggestion>> searchCity(
    String query, {
    required String languageCode,
  }) {
    return _withSearchErrorHandling(
      () => _nominatimService.autocompleteCities(
        query,
        languageCode: languageCode,
      ),
    );
  }

  Future<Map<String, dynamic>> resolveCity(
    LocationSearchSuggestion suggestion, {
    required String languageCode,
  }) {
    return _withSearchErrorHandling(() async {
      final placemarkModel = await _nominatimService.resolvePlace(
        suggestion.placeId,
        languageCode: languageCode,
      );
      final result = _findBestResult(placemarkModel.results);
      final location = result?.geometry?.location;
      final latitude = location?.lat;
      final longitude = location?.lng;

      if (result == null || latitude == null || longitude == null) {
        throw const LocationSearchException(LocationSearchErrorType.unknown);
      }

      final addressMap =
          _parseAddressComponents(result.addressComponents ?? []);
      final formattedAddress = result.formattedAddress?.trim();

      return {
        'name': formattedAddress == null || formattedAddress.isEmpty
            ? suggestion.displayName
            : formattedAddress,
        'lat': latitude,
        'lon': longitude,
        'country_code': addressMap['country_code'] ?? '',
      };
    });
  }

  Future<T> _withSearchErrorHandling<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on LocationSearchException {
      rethrow;
    } on FunctionException catch (e) {
      if (e.status == 429) {
        throw const LocationSearchException(LocationSearchErrorType.rateLimit);
      }
      if (e.status >= 500) {
        throw const LocationSearchException(LocationSearchErrorType.server);
      }
      throw const LocationSearchException(LocationSearchErrorType.unknown);
    } on SocketException {
      throw const LocationSearchException(LocationSearchErrorType.noConnection);
    } on ClientException {
      throw const LocationSearchException(LocationSearchErrorType.noConnection);
    } catch (e) {
      throw const LocationSearchException(LocationSearchErrorType.unknown);
    }
  }
}
