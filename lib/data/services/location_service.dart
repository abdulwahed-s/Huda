import 'package:geocoding/geocoding.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/data/api/nominatim_service.dart';

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

        return [
          Placemark(
            name: placemarkModel.name,
            street: placemarkModel.address['road'] ??
                placemarkModel.address['pedestrian'] ??
                '',
            isoCountryCode:
                placemarkModel.address['country_code']?.toUpperCase() ?? '',
            country: placemarkModel.address['country'] ?? '',
            postalCode: placemarkModel.address['postcode'] ?? '',
            administrativeArea: placemarkModel.address['state'] ?? '',
            subAdministrativeArea: placemarkModel.address['county'] ?? '',
            locality: placemarkModel.address['city'] ??
                placemarkModel.address['town'] ??
                placemarkModel.address['village'] ??
                '',
            subLocality: placemarkModel.address['suburb'] ?? '',
            thoroughfare: placemarkModel.address['road'] ?? '',
            subThoroughfare: '',
          )
        ];
      } catch (e) {
        // Fallback or rethrow
        throw Exception('Failed to get placemark from Nominatim: $e');
      }
    }
  }
}
