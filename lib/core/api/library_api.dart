import 'package:dio/dio.dart';

import '../models/library_item.dart';
import 'api_client.dart';

class LibraryApi {
  LibraryApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<List<LibraryItem>> list({String? gradeId, String? subjectId}) => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/library', queryParameters: {
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
        final res = await _dio.post<Map<String, dynamic>>('/library', data: {
          'title': title,
          'description': ?description,
          'url': url,
          'grade_id': ?gradeId,
          'subject_id': ?subjectId,
        });
        return LibraryItem.fromJson(res.data!);
      });

  static Future<void> delete(String id) => apiCall(() async {
        await _dio.delete<void>('/library/$id');
      });
}
