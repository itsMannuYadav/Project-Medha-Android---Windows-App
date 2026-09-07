import 'package:dio/dio.dart';

import '../models/english.dart';
import 'api_client.dart';
import 'sse_client.dart';

/// Student Learn English (`/english/*`), gated `require_student`.
class EnglishApi {
  EnglishApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<EnglishSession> createSession({String? lessonTopic}) => apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>('/english/sessions', data: {
          'lesson_topic': ?lessonTopic,
        });
        return EnglishSession.fromJson(res.data!);
      });

  static Future<EnglishSessionDetail> getSession(String sessionId) => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/english/sessions/$sessionId');
        return EnglishSessionDetail.fromJson(res.data!);
      });

  static Future<void> sendMessage({
    required String sessionId,
    required String content,
    required void Function(String text) onToken,
    required void Function(Map<String, dynamic> data) onDone,
    required void Function(String message) onError,
  }) =>
      streamSse(
        dio: _dio,
        path: '/english/sessions/$sessionId/messages',
        body: {'content': content},
        onToken: onToken,
        onDone: onDone,
        onError: onError,
      );
}
