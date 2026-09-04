import 'package:dio/dio.dart';

import '../models/chat.dart';
import 'api_client.dart';
import 'sse_client.dart';

class ChatApi {
  ChatApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<ChatSession> createSession({
    required String gradeId,
    required String subjectId,
    String? chapterId,
    String? topicId,
  }) =>
      apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>('/chat/sessions', data: {
          'grade_id': gradeId,
          'subject_id': subjectId,
          'chapter_id': ?chapterId,
          'topic_id': ?topicId,
        });
        return ChatSession.fromJson(res.data!);
      });

  static Future<ChatSessionDetail> getSession(String sessionId) => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/chat/sessions/$sessionId');
        return ChatSessionDetail.fromJson(res.data!);
      });

  /// Free-form question -> streamed explanation. `onDone` carries
  /// `{module_id, artifact_id, message_id}`.
  static Future<void> sendMessage({
    required String sessionId,
    required String content,
    required void Function(String text) onToken,
    required void Function(Map<String, dynamic> data) onDone,
    required void Function(String message) onError,
  }) =>
      streamSse(
        dio: _dio,
        path: '/chat/sessions/$sessionId/messages',
        body: {'content': content},
        onToken: onToken,
        onDone: onDone,
        onError: onError,
      );

  /// Quiz/Activity generation -> streamed raw JSON tokens (not prose -- the
  /// `done` event doesn't carry the parsed artifact, so callers should
  /// `GET /modules/{module_id}` afterwards for the authoritative content
  /// rather than parsing the accumulated stream text themselves).
  static Future<void> generate({
    required String sessionId,
    required String artifactType, // "quiz" | "activity"
    required void Function(String text) onToken,
    required void Function(Map<String, dynamic> data) onDone,
    required void Function(String message) onError,
  }) =>
      streamSse(
        dio: _dio,
        path: '/chat/sessions/$sessionId/generate',
        body: {'artifact_type': artifactType},
        onToken: onToken,
        onDone: onDone,
        onError: onError,
      );
}
