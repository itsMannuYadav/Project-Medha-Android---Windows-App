import 'package:dio/dio.dart';

import '../models/report_card.dart';
import 'api_client.dart';

class ReportCardApi {
  ReportCardApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<ReportCardMark> upsertMark({
    required String studentId,
    required String subjectId,
    required String term,
    required double marksObtained,
    double maxMarks = 100,
    String? remarks,
  }) =>
      apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>('/report-card/marks', data: {
          'student_id': studentId,
          'subject_id': subjectId,
          'term': term,
          'marks_obtained': marksObtained,
          'max_marks': maxMarks,
          'remarks': ?remarks,
        });
        return ReportCardMark.fromJson(res.data!);
      });

  static Future<ReportCard> get(String studentId) => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/report-card/$studentId');
        return ReportCard.fromJson(res.data!);
      });
}
