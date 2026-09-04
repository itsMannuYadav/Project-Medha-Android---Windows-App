import 'package:dio/dio.dart';

import '../models/timetable.dart';
import 'api_client.dart';

class TimetableApi {
  TimetableApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<Timetable> get(String gradeId) => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/timetable', queryParameters: {'grade_id': gradeId});
        return Timetable.fromJson(res.data!);
      });

  /// Replaces the whole grid for [gradeId] in one call.
  static Future<Timetable> save(String gradeId, List<TimetableSlot> slots) => apiCall(() async {
        final res = await _dio.put<Map<String, dynamic>>('/timetable', data: {
          'grade_id': gradeId,
          'slots': slots.map((s) => s.toJson()).toList(),
        });
        return Timetable.fromJson(res.data!);
      });
}
