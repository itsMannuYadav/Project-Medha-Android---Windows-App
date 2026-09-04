import 'package:dio/dio.dart';

import '../models/module.dart';
import 'api_client.dart';

class ModulesApi {
  ModulesApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<List<ModuleListItem>> list({String? gradeId, String? subjectId, String? chapterId}) =>
      apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/modules', queryParameters: {
          'grade_id': ?gradeId,
          'subject_id': ?subjectId,
          'chapter_id': ?chapterId,
        });
        return res.data!.map((m) => ModuleListItem.fromJson(m as Map<String, dynamic>)).toList();
      });

  static Future<ModuleDetail> detail(String moduleId) => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/modules/$moduleId');
        return ModuleDetail.fromJson(res.data!);
      });

  static Future<void> delete(String moduleId) => apiCall(() async {
        await _dio.delete<void>('/modules/$moduleId');
      });

  static Future<void> giveFeedback(String moduleId, {required int rating, String? comment}) => apiCall(() async {
        await _dio.post<void>('/modules/$moduleId/feedback', data: {
          'rating': rating, // 1 | -1
          'comment': ?comment,
        });
      });
}
