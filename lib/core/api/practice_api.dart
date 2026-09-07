import 'package:dio/dio.dart';

import '../models/practice.dart';
import 'api_client.dart';

class PracticeApi {
  PracticeApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<List<PracticeQuestion>> list(String chapterId) => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/practice', queryParameters: {'chapter_id': chapterId});
        return res.data!.map((q) => PracticeQuestion.fromJson(q as Map<String, dynamic>)).toList();
      });

  static Future<PracticeQuestion> add({
    required String chapterId,
    required String question,
    required String type,
    List<String>? options,
    required String answer,
    String difficulty = 'medium',
  }) =>
      apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>('/practice', data: {
          'chapter_id': chapterId,
          'question': question,
          'type': type,
          'options': ?options,
          'answer': answer,
          'difficulty': difficulty,
        });
        return PracticeQuestion.fromJson(res.data!);
      });

  static Future<void> delete(String id) => apiCall(() async {
        await _dio.delete<void>('/practice/$id');
      });
}
