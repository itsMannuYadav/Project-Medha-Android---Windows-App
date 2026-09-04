import 'package:dio/dio.dart';

import '../models/fee_payment.dart';
import 'api_client.dart';

class FeesApi {
  FeesApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<FeePayment> log({
    required String studentId,
    required double amount,
    required String feeType,
    required DateTime paymentDate,
    String? note,
  }) =>
      apiCall(() async {
        final d = paymentDate;
        final iso = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        final res = await _dio.post<Map<String, dynamic>>('/fees', data: {
          'student_id': studentId,
          'amount': amount,
          'fee_type': feeType,
          'payment_date': iso,
          'note': ?note,
        });
        return FeePayment.fromJson(res.data!);
      });

  static Future<List<FeePayment>> listFor(String studentId) => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/fees/$studentId');
        return res.data!.map((f) => FeePayment.fromJson(f as Map<String, dynamic>)).toList();
      });
}
