import 'package:dio/dio.dart';

import '../models/notes.dart';
import 'api_client.dart';

/// Teacher/principal-curated chapter notes -- read-only from Flutter for now
/// (authoring happens on the web console); `GET /notes` returns `null` when
/// nothing's been added for that chapter yet.
class NotesApi {
  NotesApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<ChapterNote?> get(String chapterId) => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>?>('/notes', queryParameters: {'chapter_id': chapterId});
        final data = res.data;
        return data == null ? null : ChapterNote.fromJson(data);
      });
}
