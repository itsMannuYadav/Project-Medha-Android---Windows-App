import 'package:dio/dio.dart';

import '../models/teacher.dart';
import 'api_client.dart';

class AuthApi {
  AuthApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<void> login(String email, String password) => apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: {'email': email, 'password': password},
        );
        ApiClient.instance.setAccessToken(res.data!['access_token'] as String);
      });

  /// role: "teacher" | "principal". Student registration is a separate,
  /// unauthenticated `/student/register` endpoint with a different shape --
  /// out of scope here (Teacher flow only, see plan).
  static Future<void> register({
    required String role,
    required String fullName,
    required String email,
    required String password,
    required String mobileNumber,
    required String schoolId,
    String? employeeCode,
    int? yearsOfExperience,
    String? qualification,
    String? googleSub,
  }) =>
      apiCall(() async {
        await _dio.post<void>('/auth/register', data: {
          'role': role,
          'full_name': fullName,
          'email': email,
          'password': password,
          'mobile_number': mobileNumber,
          'school_id': schoolId,
          'employee_code': ?employeeCode,
          'years_of_experience': ?yearsOfExperience,
          'qualification': ?qualification,
          'google_sub': ?googleSub,
        });
      });

  static Future<TeacherMe> me() => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/auth/me');
        return TeacherMe.fromJson(res.data!);
      });

  /// Phase 1 of student sign-up: no credential yet, just a claim against the
  /// class register -- a teacher at the school approves it before phase 2
  /// (`activateStudent`) can set a password. Unauthenticated endpoint.
  static Future<void> registerStudent({
    required String fullName,
    required String schoolId,
    required String gradeId,
    required String rollNumber,
  }) =>
      apiCall(() async {
        await _dio.post<void>('/student/register', data: {
          'full_name': fullName,
          'school_id': schoolId,
          'grade_id': gradeId,
          'roll_number': rollNumber,
        });
      });

  /// Phase 2: re-proves identity against the now-approved row, then sets
  /// email + password for the first time. Unauthenticated endpoint -- the
  /// caller still needs to log in afterwards.
  static Future<void> activateStudent({
    required String schoolId,
    required String gradeId,
    required String rollNumber,
    required String fullName,
    required String email,
    required String password,
  }) =>
      apiCall(() async {
        await _dio.post<void>('/student/activate', data: {
          'school_id': schoolId,
          'grade_id': gradeId,
          'roll_number': rollNumber,
          'full_name': fullName,
          'email': email,
          'password': password,
        });
      });

  static Future<void> logout() => ApiClient.instance.logout();

  /// Attempts a silent session restore via the refresh cookie -- call once
  /// at app start, before deciding whether to show Login or the signed-in
  /// shell, mirroring the web client exactly.
  static Future<bool> trySilentRefresh() => ApiClient.instance.refreshSession();
}
