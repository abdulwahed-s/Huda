import 'package:huda/core/constants/end_points.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HadithServices {
  // Read when used, so the class can be built without Supabase (tests).
  FunctionsClient get _functions => Supabase.instance.client.functions;

  Future<Map<String, dynamic>> getAllBooks() async {
    try {
      final res = await _functions
          .invoke('hadith-proxy', body: {'path': EndPoints.hadithBooks});
      return Map<String, dynamic>.from(res.data as Map);
    } on FunctionException catch (e) {
      throw Exception(e.details ?? 'Failed to load hadith books');
    }
  }
}
