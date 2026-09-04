import 'package:dio/dio.dart';

import '../models/practice.dart';
import 'api_client.dart';

/// Teacher/principal-curated practice questions -- read-only from Flutter
/// for now (authoring happens on the web console).
class PracticeApi {
  PracticeApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<List<PracticeQuestion>> list(String chapterId) => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/practice', queryParameters: {'chapter_id': chapterId});
        return res.data!.map((q) => PracticeQuestion.fromJson(q as Map<String, dynamic>)).toList();
      });
}
