import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:huda/data/models/location_search_suggestion.dart';
import 'package:huda/data/models/placemark_model.dart';

class NominatimService {
  final _functions = Supabase.instance.client.functions;

  Future<PlacemarkModel> getPlacemark(
    double lat,
    double lon, {
    String languageCode = 'en',
  }) async {
    final res = await _functions.invoke(
      'geocode-proxy',
      body: {'lat': lat, 'lon': lon, 'language': languageCode},
    );
    return PlacemarkModel.fromJson(res.data);
  }

  Future<List<LocationSearchSuggestion>> autocompleteCities(
    String query, {
    required String languageCode,
  }) async {
    final res = await _functions.invoke(
      'geocode-proxy',
      body: {
        'action': 'autocomplete',
        'query': query,
        'language': languageCode,
      },
    );

    final data = res.data;
    if (data is! Map) return const [];

    final rawSuggestions = data['suggestions'];
    if (rawSuggestions is! List) return const [];

    return rawSuggestions
        .whereType<Map>()
        .map((item) =>
            LocationSearchSuggestion.fromJson(Map<String, dynamic>.from(item)))
        .where((suggestion) => suggestion.isValid)
        .toList();
  }

  Future<PlacemarkModel> resolvePlace(
    String placeId, {
    required String languageCode,
  }) async {
    final res = await _functions.invoke(
      'geocode-proxy',
      body: {'placeId': placeId, 'language': languageCode},
    );
    return PlacemarkModel.fromJson(res.data);
  }
}
