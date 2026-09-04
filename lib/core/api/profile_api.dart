import 'package:dio/dio.dart';

import '../models/profile.dart';
import 'api_client.dart';
import 'onboarding_api.dart';

class ProfileApi {
  ProfileApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<Profile> get() => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/profile');
        return Profile.fromJson(res.data!);
      });

  /// All fields optional -- an omitted field is left unchanged. `subjects`,
  /// when given, REPLACES the teacher's whole subject/grade set (not a
  /// merge), matching the backend's `PATCH /profile` semantics.
  static Future<Profile> update({
    String? fullName,
    String? preferredLanguage, // "hi-BiharBoli" | "hi" | "en" | "hinglish"
    List<SubjectGradePair>? subjects,
  }) =>
      apiCall(() async {
        final res = await _dio.patch<Map<String, dynamic>>('/profile', data: {
          'full_name': ?fullName,
          'preferred_language': ?preferredLanguage,
          if (subjects != null) 'subjects': subjects.map((s) => s.toJson()).toList(),
        });
        return Profile.fromJson(res.data!);
      });
}
