import 'package:dio/dio.dart';

import '../models/attendance.dart';
import 'api_client.dart';

class AttendanceApi {
  AttendanceApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<AttendanceDay> get({required String gradeId, DateTime? date}) => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/attendance', queryParameters: {
          'grade_id': gradeId,
          if (date != null) 'date': _iso(date),
        });
        return AttendanceDay.fromJson(res.data!);
      });

  static Future<AttendanceDay> mark({
    required String gradeId,
    required DateTime date,
    required Map<String, String> statusByStudentId, // student_id -> "present"|"absent"
  }) =>
      apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>('/attendance', data: {
          'grade_id': gradeId,
          'date': _iso(date),
          'records': statusByStudentId.entries.map((e) => {'student_id': e.key, 'status': e.value}).toList(),
        });
        return AttendanceDay.fromJson(res.data!);
      });
}
