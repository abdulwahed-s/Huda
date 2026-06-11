import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:huda/data/models/placemark_model.dart';

class NominatimService {
  final _functions = Supabase.instance.client.functions;

  Future<PlacemarkModel> getPlacemark(double lat, double lon) async {
    final res = await _functions
        .invoke('geocode-proxy', body: {'lat': lat, 'lon': lon});
    return PlacemarkModel.fromJson(res.data);
  }

  Future<PlacemarkModel> searchLocation(String address) async {
    final res =
        await _functions.invoke('geocode-proxy', body: {'address': address});
    return PlacemarkModel.fromJson(res.data);
  }
}
