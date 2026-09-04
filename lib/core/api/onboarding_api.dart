import 'package:dio/dio.dart';

import '../models/teacher.dart';
import 'api_client.dart';

class SubjectGradePair {
  const SubjectGradePair({required this.subjectId, required this.gradeId, this.isPrimary = false});
  final String subjectId;
  final String gradeId;
  final bool isPrimary;

  Map<String, dynamic> toJson() => {
        'subject_id': subjectId,
        'grade_id': gradeId,
        'is_primary': isPrimary,
      };
}

class OnboardingApi {
  OnboardingApi._();
  static Dio get _dio => ApiClient.instance.dio;

  /// Single combined submit -- there's no separate "profile step" /
  /// "subjects step" on the backend, just this one endpoint. Exactly one
  /// pair in [subjects] must be primary.
  static Future<TeacherMe> complete({
    required String fullName,
    required String schoolId,
    required List<SubjectGradePair> subjects,
  }) =>
      apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>('/onboarding/complete', data: {
          'full_name': fullName,
          'school_id': schoolId,
          'subjects': subjects.map((s) => s.toJson()).toList(),
        });
        return TeacherMe.fromJson(res.data!);
      });
}
