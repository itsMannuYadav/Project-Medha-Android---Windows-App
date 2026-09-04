import 'package:dio/dio.dart';

import '../models/homework.dart';
import 'api_client.dart';

class HomeworkApi {
  HomeworkApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<HomeworkDetail> create({
    required String gradeId,
    String? subjectId,
    required String title,
    String? description,
    DateTime? dueDate,
  }) =>
      apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>('/homework', data: {
          'grade_id': gradeId,
          'subject_id': ?subjectId,
          'title': title,
          'description': ?description,
          'due_date': ?_iso(dueDate),
        });
        return HomeworkDetail.fromJson(res.data!);
      });

  /// Teacher's own assigned homework.
  static Future<List<HomeworkListItem>> listForTeacher() => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/homework');
        return res.data!.map((h) => HomeworkListItem.fromJson(h as Map<String, dynamic>)).toList();
      });

  /// Student's own homework, with their done flag folded in.
  static Future<List<HomeworkStudentItem>> listForStudent() => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/homework/mine');
        return res.data!.map((h) => HomeworkStudentItem.fromJson(h as Map<String, dynamic>)).toList();
      });

  static Future<HomeworkStudentItem> setDone(String homeworkId, bool done) => apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>('/homework/$homeworkId/${done ? "done" : "undone"}');
        return HomeworkStudentItem.fromJson(res.data!);
      });

  static String? _iso(DateTime? d) =>
      d == null ? null : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
