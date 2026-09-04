import 'package:dio/dio.dart';

import '../models/principal.dart';
import 'api_client.dart';

/// Principal/office endpoints (`/principal/*`), gated `require_principal`
/// server-side.
class PrincipalApi {
  PrincipalApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<PrincipalStats> stats() => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/principal/stats');
        return PrincipalStats.fromJson(res.data!);
      });

  static Future<List<PendingTeacher>> pendingTeachers() => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/principal/teachers/pending');
        return res.data!.map((t) => PendingTeacher.fromJson(t as Map<String, dynamic>)).toList();
      });

  static Future<List<TeacherRosterItem>> teachers() => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/principal/teachers');
        return res.data!.map((t) => TeacherRosterItem.fromJson(t as Map<String, dynamic>)).toList();
      });

  static Future<List<PrincipalStudentItem>> students() => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/principal/students');
        return res.data!.map((s) => PrincipalStudentItem.fromJson(s as Map<String, dynamic>)).toList();
      });

  static Future<void> approveTeacher(String id) =>
      apiCall(() async => _dio.post<void>('/principal/teachers/$id/approve'));

  static Future<void> rejectTeacher(String id, String reason) => apiCall(() async {
        await _dio.post<void>('/principal/teachers/$id/reject', data: {'reason': reason});
      });
}
