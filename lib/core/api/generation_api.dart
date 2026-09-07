import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/generation.dart';
import 'api_client.dart';
import 'sse_client.dart';

/// Content generation v2 (`POST /generate/{type}`, `/generations/*`).
class GenerationApi {
  GenerationApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<List<GenerationListItem>> list({String? type, bool? favorite, String? q}) =>
      apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/generations', queryParameters: {
          'type': ?type,
          if (favorite == true) 'favorite': 'true',
          'q': ?q,
        });
        return res.data!.map((g) => GenerationListItem.fromJson(g as Map<String, dynamic>)).toList();
      });

  static Future<GenerationDetail> get(String id) => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/generations/$id');
        return GenerationDetail.fromJson(res.data!);
      });

  static Future<GenerationDetail> patch(
    String id, {
    bool? isFavorite,
    String? title,
    Map<String, dynamic>? contentJson,
  }) =>
      apiCall(() async {
        final res = await _dio.patch<Map<String, dynamic>>('/generations/$id', data: {
          'is_favorite': ?isFavorite,
          'title': ?title,
          'content_json': ?contentJson,
        });
        return GenerationDetail.fromJson(res.data!);
      });

  static Future<void> delete(String id) => apiCall(() async {
        await _dio.delete<void>('/generations/$id');
      });

  static Future<void> feedback(String id, {required int rating, String? comment}) => apiCall(() async {
        await _dio.post<void>('/generations/$id/feedback', data: {
          'rating': rating,
          'comment': ?comment,
        });
      });

  static Future<Map<String, dynamic>> answerKey(String id, {Map<String, dynamic>? contentJson}) =>
      apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>('/generations/$id/answer-key', data: {
          'content_json': ?contentJson,
        });
        return res.data!;
      });

  /// Downloads export bytes and opens the system share sheet.
  static Future<void> exportAndShare(String id, String fmt) => apiCall(() async {
        final res = await _dio.get<List<int>>(
          '/generations/$id/export/$fmt',
          options: Options(responseType: ResponseType.bytes),
        );
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/medha_$id.$fmt';
        final file = File(path);
        await file.writeAsBytes(res.data!, flush: true);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(path, mimeType: _mime(fmt), name: 'medha_$id.$fmt')]),
        );
      });

  static Future<void> regenerate({
    required String id,
    Map<String, dynamic>? params,
    String? language,
    required void Function(String text) onToken,
    void Function(String stage, int done, int total)? onProgress,
    required void Function(Map<String, dynamic> data) onDone,
    required void Function(String message) onError,
  }) =>
      streamSse(
        dio: _dio,
        path: '/generations/$id/regenerate',
        body: {
          'params': ?params,
          'language': ?language,
        },
        onToken: onToken,
        onProgress: onProgress,
        onDone: onDone,
        onError: onError,
      );

  static Future<void> generate({
    required String type,
    required String gradeId,
    required String subjectId,
    String? chapterId,
    String? topicId,
    Map<String, dynamic> params = const {},
    String? language,
    required void Function(String text) onToken,
    void Function(String stage, int done, int total)? onProgress,
    required void Function(Map<String, dynamic> data) onDone,
    required void Function(String message) onError,
  }) =>
      streamSse(
        dio: _dio,
        path: '/generate/$type',
        body: {
          'scope': {
            'grade_id': gradeId,
            'subject_id': subjectId,
            'chapter_id': ?chapterId,
            'topic_id': ?topicId,
          },
          'params': params,
          'language': ?language,
        },
        onToken: onToken,
        onProgress: onProgress,
        onDone: onDone,
        onError: onError,
      );

  static String _mime(String fmt) => switch (fmt) {
        'pdf' => 'application/pdf',
        'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        _ => 'application/octet-stream',
      };
}
