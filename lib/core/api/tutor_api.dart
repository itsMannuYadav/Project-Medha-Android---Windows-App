import 'package:dio/dio.dart';

import '../models/tutor.dart';
import 'api_client.dart';
import 'sse_client.dart';

/// The student doubt-chat backend (`/tutor/*`), separate from the teacher's
/// `/chat/*` -- gated `require_student` server-side.
class TutorApi {
  TutorApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<TutorSession> createSession({required String subjectId, required String chapterId}) =>
      apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>('/tutor/sessions', data: {
          'subject_id': subjectId,
          'chapter_id': chapterId,
        });
        return TutorSession.fromJson(res.data!);
      });

  static Future<TutorSessionDetail> getSession(String sessionId) => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/tutor/sessions/$sessionId');
        return TutorSessionDetail.fromJson(res.data!);
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
        path: '/tutor/sessions/$sessionId/messages',
        body: {'content': content},
        onToken: onToken,
        onDone: onDone,
        onError: onError,
      );
}
