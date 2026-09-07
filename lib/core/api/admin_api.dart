import 'package:dio/dio.dart';

import '../models/admin.dart';
import 'api_client.dart';

class AdminApi {
  AdminApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<AdminStats> stats() => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/admin/stats');
        return AdminStats.fromJson(res.data!);
      });

  static Future<List<PendingPrincipal>> pendingPrincipals() => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/admin/principals/pending');
        return res.data!.map((p) => PendingPrincipal.fromJson(p as Map<String, dynamic>)).toList();
      });

  static Future<List<SchoolPrincipalStatus>> schools() => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/admin/schools');
        return res.data!.map((s) => SchoolPrincipalStatus.fromJson(s as Map<String, dynamic>)).toList();
      });

  static Future<void> approvePrincipal(String id) =>
      apiCall(() async => _dio.post<void>('/admin/principals/$id/approve'));

  static Future<void> rejectPrincipal(String id, String reason) => apiCall(() async {
        await _dio.post<void>('/admin/principals/$id/reject', data: {'reason': reason});
      });
}
