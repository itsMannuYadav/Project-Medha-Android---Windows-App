import 'package:dio/dio.dart';

import '../models/notification.dart';
import 'api_client.dart';

class NotificationsApi {
  NotificationsApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<List<NotificationItem>> list() => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/notifications');
        return res.data!.map((n) => NotificationItem.fromJson(n as Map<String, dynamic>)).toList();
      });

  static Future<int> unreadCount() => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/notifications/unread-count');
        return res.data!['count'] as int;
      });

  static Future<void> markRead(String id) => apiCall(() async {
        await _dio.post<void>('/notifications/$id/read');
      });

  /// Principal: pass [audience] ("teachers"|"students"). Teacher: pass
  /// [gradeId]. Exactly one, matching the backend's validation.
  static Future<int> announce({required String title, required String body, String? audience, String? gradeId}) =>
      apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>('/notifications/announce', data: {
          'title': title,
          'body': body,
          'audience': ?audience,
          'grade_id': ?gradeId,
        });
        return res.data!['recipients'] as int;
      });

  static Future<void> registerDevice({required String token, required String platform}) => apiCall(() async {
        await _dio.post<void>('/notifications/devices', data: {'token': token, 'platform': platform});
      });

  static Future<void> unregisterDevice(String token) => apiCall(() async {
        await _dio.delete<void>('/notifications/devices/$token');
      });
}
