import 'package:dio/dio.dart';

import '../models/notes.dart';
import 'api_client.dart';

class NotesApi {
  NotesApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<ChapterNote?> get(String chapterId) => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>?>('/notes', queryParameters: {'chapter_id': chapterId});
        final data = res.data;
        return data == null ? null : ChapterNote.fromJson(data);
      });

  static Future<ChapterNote> upsert({
    required String chapterId,
    required String summary,
    List<String> keyPoints = const [],
    List<String> importantTerms = const [],
  }) =>
      apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>('/notes', data: {
          'chapter_id': chapterId,
          'summary': summary,
          'key_points': keyPoints,
          'important_terms': importantTerms,
        });
        return ChapterNote.fromJson(res.data!);
      });

  static Future<void> delete(String id) => apiCall(() async {
        await _dio.delete<void>('/notes/$id');
      });
}
