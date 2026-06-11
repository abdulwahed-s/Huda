import 'package:huda/core/constants/end_points.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailsServices {
  final _functions = Supabase.instance.client.functions;

  Future<Map<String, dynamic>> getAllDetails(
      String chapterNumber, String bookName, int pageNumber) async {
    try {
      final res = await _functions.invoke('hadith-proxy', body: {
        'path': EndPoints.hadithDetail(bookName, chapterNumber),
        'query': {'page': pageNumber},
      });

      final data = Map<String, dynamic>.from(res.data as Map);

      if (data.containsKey('error')) {
        throw Exception('Server Error');
      }

      return data;
    } on FunctionException catch (e) {
      throw Exception(e.details ?? 'Failed to load hadith details');
    }
  }
}
