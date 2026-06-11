import 'package:huda/core/constants/end_points.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChapterServices {
  final _functions = Supabase.instance.client.functions;

  Future<Map<String, dynamic>> getChaptersByBook(String bookName) async {
    try {
      final res = await _functions.invoke('hadith-proxy', body: {
        'path': EndPoints.bookChapter(bookName),
        'query': {'limit': 100},
      });
      return Map<String, dynamic>.from(res.data as Map);
    } on FunctionException catch (e) {
      throw Exception(e.details ?? 'Failed to load chapters');
    }
  }
}
