import 'package:dio/dio.dart';

/// A parsed backend error. The backend wraps every error as
/// `{error:{code,message,request_id}, detail}` -- but `error.message` is a
/// hardcoded "Request failed." whenever `detail` is structured (the
/// PENDING_APPROVAL / REGISTRATION_REJECTED / NOT_REGISTERED cases), so this
/// reads `detail` first, exactly like the web client does, rather than
/// trusting the generic top-level message.
class ApiError implements Exception {
  ApiError({
    this.statusCode,
    required this.message,
    this.detailCode,
    this.detailData,
    this.requestId,
  });

  final int? statusCode;
  final String message;
  final String? detailCode;
  final Map<String, dynamic>? detailData;
  final String? requestId;

  bool get isRateLimited => statusCode == 429;
  bool get isPendingApproval => detailCode == 'PENDING_APPROVAL';
  bool get isRejected => detailCode == 'REGISTRATION_REJECTED';
  bool get isNotRegistered => detailCode == 'NOT_REGISTERED';
  String? get rejectionReason => detailData?['reason'] as String?;

  factory ApiError.fromDioException(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final errorObj = data['error'];
      final requestId = errorObj is Map ? errorObj['request_id'] as String? : null;
      final detail = data['detail'];

      if (detail is Map<String, dynamic> && detail['code'] is String) {
        final code = detail['code'] as String;
        return ApiError(
          statusCode: status,
          message: (detail['reason'] as String?) ?? code,
          detailCode: code,
          detailData: detail,
          requestId: requestId,
        );
      }
      if (detail is String && detail.isNotEmpty) {
        return ApiError(statusCode: status, message: detail, requestId: requestId);
      }
      if (detail is List && detail.isNotEmpty && detail.first is Map) {
        final first = detail.first as Map;
        return ApiError(
          statusCode: status,
          message: (first['msg'] as String?) ?? 'Request failed.',
          requestId: requestId,
        );
      }
      final errMsg = errorObj is Map ? errorObj['message'] as String? : null;
      if (errMsg != null && errMsg.isNotEmpty) {
        return ApiError(statusCode: status, message: errMsg, requestId: requestId);
      }
    }

    return ApiError(
      statusCode: status,
      message: e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout
          ? 'सर्वर से जुड़ नहीं पाए। इंटरनेट जांचें।'
          : (e.message ?? 'कुछ गड़बड़ हो गई।'),
    );
  }
}
