import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.apiBaseUrl,
              // Generous: a cold-started free-tier host can take ~60s to wake.
              connectTimeout: const Duration(seconds: 60),
              receiveTimeout: const Duration(seconds: 60),
              headers: {'Content-Type': 'application/json'},
            )) {
    // Only the production Dio gets cookie/refresh handling. A test that
    // injects its own Dio (test/helpers/test_harness.dart's FakeAdapter) gets
    // a plain client with just the auth header — CookieManager reading
    // headers off a hand-built fake ResponseBody previously hung the entire
    // suite instead of failing cleanly, which is a much worse failure mode
    // than just not exercising cookie logic in widget tests.
    final isProduction = dio == null;

    // dio_cookie_manager wraps dart:io's Cookie/CookieJar via `universal_io`
    // shims on platforms without real dart:io. On Flutter web those shims
    // threw an AssertionError on every single request, before dispatch —
    // confirmed directly: with CookieManager attached, zero requests to the
    // backend were ever observed on the network tab, only an uncaught
    // AssertionErrorImpl in the console, on every screen that hits the API.
    // Real target platforms (Android/iOS/Windows) use dio's actual dart:io
    // adapter, where this is the correct, necessary approach — the browser
    // case is also moot there since fetch/XHR manage cookies natively via
    // the adapter itself, which CookieManager would only duplicate.
    if (isProduction && !kIsWeb) {
      // The refresh token lives in an httpOnly cookie the backend sets on
      // /auth/login and /auth/refresh (backend/src/backend/auth/router.py's
      // _set_refresh_cookie). dio's dart:io adapter — used on every real
      // target platform (Android/iOS/Windows) — does not manage cookies on
      // its own, so without this jar /auth/refresh would never see the
      // cookie it needs.
      //
      // NOTE: this cannot be verified through the web build used for local
      // QA — browsers hide Set-Cookie from script/fetch entirely regardless
      // of CORS, by design. Verified only by compiling + the test suite
      // staying green; the refresh flow itself needs a native run to confirm.
      _dio.interceptors.add(CookieManager(CookieJar()));
    }

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token =
            await _storage.read(key: AppConstants.keyAccessToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));

    if (isProduction) {
      _dio.interceptors.add(_RefreshInterceptor(_dio, _storage));
    }
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters}) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> patch<T>(String path, {dynamic data}) {
    return _dio.patch<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }

  // SSE / streaming via raw http
  Stream<String> streamPost(String path, Map<String, dynamic> body,
      String? token) async* {
    // Use dio with stream response
    final response = await _dio.post(
      path,
      data: body,
      options: Options(responseType: ResponseType.stream),
    );
    final stream = response.data as ResponseBody;
    await for (final chunk in stream.stream) {
      final text = String.fromCharCodes(chunk);
      for (final line in text.split('\n')) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data.isNotEmpty && data != '[DONE]') {
            yield data;
          }
        }
      }
    }
  }
}

/// Access tokens expire in 15 minutes server-side (confirmed via the login
/// response's `expires_in: 900`). Without this, any screen left open past
/// that window — or simply a slow user — gets a raw "Invalid or expired
/// access token." error with no recovery path but a manual logout (observed
/// directly while testing the teacher-onboarding flow against the live
/// backend). This mirrors shiksha_sathi's reactive side: on a 401, try
/// POST /auth/refresh once and retry the original request; only give up and
/// let the 401 propagate if refresh itself fails.
///
/// [QueuedInterceptor] serializes interceptor callbacks across concurrent
/// requests, so two 401s arriving close together can't both kick off a
/// refresh — refresh tokens rotate single-use, and a second concurrent call
/// would revoke the first's result out from under it (the same race the web
/// app's `inFlightRefresh` ref exists to prevent). The second error to reach
/// this handler instead notices the stored token already changed and just
/// retries with that, without refreshing again.
class _RefreshInterceptor extends QueuedInterceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  _RefreshInterceptor(this._dio, this._storage);

  static const _noRefreshPaths = [
    '/auth/login',
    '/auth/refresh',
    '/auth/register',
    '/student/register',
    '/student/activate',
  ];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final alreadyRetried = err.requestOptions.extra['_retriedAfterRefresh'] == true;
    if (err.response?.statusCode != 401 ||
        _noRefreshPaths.any(path.contains) ||
        alreadyRetried) {
      return handler.next(err);
    }

    final failedAuthHeader = err.requestOptions.headers['Authorization'] as String?;
    final currentToken = await _storage.read(key: AppConstants.keyAccessToken);

    String? newToken;
    if (currentToken != null &&
        failedAuthHeader != null &&
        !failedAuthHeader.contains(currentToken)) {
      // A concurrent request's error already refreshed the token — reuse it.
      newToken = currentToken;
    } else {
      try {
        final res = await _dio.post('/auth/refresh');
        newToken = (res.data as Map)['access_token'] as String?;
        if (newToken != null) {
          await _storage.write(key: AppConstants.keyAccessToken, value: newToken);
        }
      } catch (_) {
        newToken = null;
      }
    }

    if (newToken == null) {
      // Refresh cookie missing/expired too — nothing left to do but clear
      // the stale session so the next navigation/restore correctly bounces
      // to /login instead of looping on 401s.
      await _storage.deleteAll();
      return handler.next(err);
    }

    try {
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newToken';
      opts.extra['_retriedAfterRefresh'] = true;
      final retryResponse = await _dio.fetch(opts);
      return handler.resolve(retryResponse);
    } catch (_) {
      return handler.next(err);
    }
  }
}

// ---------------------------------------------------------------------------
// Error extraction (mirrors extractErrorMessage in api.ts)
// ---------------------------------------------------------------------------

String extractApiError(dynamic error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      if (data['error']?['message'] is String) {
        return data['error']['message'] as String;
      }
      if (data['detail'] is String) return data['detail'] as String;
      if (data['message'] is String) return data['message'] as String;
    }
    return error.message ?? 'Something went wrong.';
  }
  return 'Something went wrong.';
}
