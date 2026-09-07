import 'package:dio/dio.dart';

import '../models/library_item.dart';
import '../models/library_presentation.dart';
import 'api_client.dart';

class LibraryApi {
  LibraryApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<List<LibraryItem>> list({String? gradeId, String? subjectId}) => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/library/items', queryParameters: {
          'grade_id': ?gradeId,
          'subject_id': ?subjectId,
        });
        return res.data!.map((i) => LibraryItem.fromJson(i as Map<String, dynamic>)).toList();
      });

  static Future<LibraryItem> add({
    required String title,
    String? description,
    required String url,
    String? gradeId,
    String? subjectId,
  }) =>
      apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>('/library/items', data: {
          'title': title,
          'description': ?description,
          'url': url,
          'grade_id': ?gradeId,
          'subject_id': ?subjectId,
        });
        return LibraryItem.fromJson(res.data!);
      });

  static Future<void> delete(String id) => apiCall(() async {
        await _dio.delete<void>('/library/items/$id');
      });

  static Future<List<LibraryPresentationItem>> presentations({
    String? gradeId,
    String? subjectId,
    String? q,
  }) =>
      apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/library/presentations', queryParameters: {
          'grade_id': ?gradeId,
          'subject_id': ?subjectId,
          'q': ?q,
        });
        return res.data!
            .map((p) => LibraryPresentationItem.fromJson(p as Map<String, dynamic>))
            .toList();
      });

  static Future<LibraryPresentationDetail> presentation(String id) => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/library/presentations/$id');
        return LibraryPresentationDetail.fromJson(res.data!);
      });
}
