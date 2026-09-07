import 'package:dio/dio.dart';

import '../models/teacher_students.dart';
import 'api_client.dart';

/// Teacher-facing student approvals (`/teacher/students/*`), gated
/// `require_teacher` server-side — mirrors the web Students page.
class TeacherStudentsApi {
  TeacherStudentsApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<TeacherStudentStats> stats() => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/teacher/students/stats');
        return TeacherStudentStats.fromJson(res.data!);
      });

  static Future<List<PendingStudent>> pending() => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/teacher/students/pending');
        return res.data!.map((s) => PendingStudent.fromJson(s as Map<String, dynamic>)).toList();
      });

  static Future<List<TeacherStudentItem>> roster() => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/teacher/students');
        return res.data!.map((s) => TeacherStudentItem.fromJson(s as Map<String, dynamic>)).toList();
      });

  static Future<void> approve(String id) =>
      apiCall(() async => _dio.post<void>('/teacher/students/$id/approve'));

  static Future<void> reject(String id, String reason) => apiCall(() async {
        await _dio.post<void>('/teacher/students/$id/reject', data: {'reason': reason});
      });
}
