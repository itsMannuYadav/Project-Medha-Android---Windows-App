import 'package:dio/dio.dart';

import 'api_client.dart';

class ToolsApi {
  ToolsApi._();
  static Dio get _dio => ApiClient.instance.dio;

  /// mode: "translate" | "simplify". targetLanguage: "hi" | "hi-BiharBoli" |
  /// "en" | "hinglish". readingLevel: "class-6" | "class-8" | "class-10".
  static Future<String> translate({
    required String text,
    required String mode,
    required String targetLanguage,
    required String readingLevel,
  }) =>
      apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>('/tools/translate', data: {
          'text': text,
          'mode': mode,
          'target_language': targetLanguage,
          'reading_level': readingLevel,
        });
        return res.data!['result'] as String;
      });
}
