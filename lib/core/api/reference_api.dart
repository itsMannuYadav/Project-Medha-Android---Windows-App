import 'package:dio/dio.dart';

import '../models/reference.dart';
import 'api_client.dart';

/// Public reference/curriculum data -- no auth required on any of these.
class ReferenceApi {
  ReferenceApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<List<GradeRef>> grades() => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/reference/grades');
        return res.data!.map((g) => GradeRef.fromJson(g as Map<String, dynamic>)).toList();
      });

  static Future<List<SubjectRef>> subjects() => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/reference/subjects');
        return res.data!.map((s) => SubjectRef.fromJson(s as Map<String, dynamic>)).toList();
      });

  static Future<List<SchoolSearchResult>> searchSchools(String query) => apiCall(() async {
        if (query.trim().isEmpty) return <SchoolSearchResult>[];
        final res = await _dio.get<List<dynamic>>('/schools/search', queryParameters: {'q': query});
        return res.data!.map((s) => SchoolSearchResult.fromJson(s as Map<String, dynamic>)).toList();
      });

  static Future<List<ChapterRef>> chapters({required String gradeId, required String subjectId}) => apiCall(() async {
        final res = await _dio.get<List<dynamic>>(
          '/curriculum/chapters',
          queryParameters: {'grade_id': gradeId, 'subject_id': subjectId},
        );
        return res.data!.map((c) => ChapterRef.fromJson(c as Map<String, dynamic>)).toList();
      });

  static Future<List<TopicRef>> topics(String chapterId) => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/curriculum/topics', queryParameters: {'chapter_id': chapterId});
        return res.data!.map((t) => TopicRef.fromJson(t as Map<String, dynamic>)).toList();
      });
}
