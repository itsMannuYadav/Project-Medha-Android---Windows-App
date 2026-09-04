import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'api_config.dart';
import 'api_error.dart';

/// One Dio instance for the whole app: base URL, a persistent cookie jar
/// (the refresh token is an httpOnly cookie scoped `path=/auth` -- the jar
/// replicates a browser's `credentials: "include"` behaviour so it just
/// works, exactly like the Next.js client), and an interceptor that attaches
/// the access token and transparently refreshes it on a 401.
///
/// Call [init] once at app startup, before the first request.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio dio;
  String? _accessToken;
  Future<bool>? _refreshing;

  String? get accessToken => _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    final cookieJar = PersistCookieJar(storage: FileStorage('${dir.path}/.medha_cookies/'));

    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    dio.interceptors.add(CookieManager(cookieJar));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null && !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isAuthEndpoint = error.requestOptions.path.startsWith('/auth/');
          final canRetry = error.response?.statusCode == 401 && !isAuthEndpoint && _accessToken != null;
          if (!canRetry) return handler.next(error);

          final refreshed = await _refreshOnce();
          if (!refreshed) return handler.next(error);

          try {
            final retryOptions = error.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $_accessToken';
            final response = await dio.fetch(retryOptions);
            handler.resolve(response);
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );
  }

  /// Attempts `/auth/refresh` using the refresh cookie. De-duplicated: the
  /// refresh token rotates (single-use) on every call, so two overlapping
  /// refreshes would spuriously log the loser out.
  Future<bool> refreshSession() => _refreshOnce();

  Future<bool> _refreshOnce() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    try {
      final response = await dio.post<Map<String, dynamic>>('/auth/refresh');
      _accessToken = response.data?['access_token'] as String?;
      return _accessToken != null;
    } on DioException {
      _accessToken = null;
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await dio.post('/auth/logout');
    } on DioException {
      // best-effort -- clear local state regardless
    }
    _accessToken = null;
  }
}

/// Runs [body], mapping any [DioException] to a parsed [ApiError].
Future<T> apiCall<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on DioException catch (e) {
    throw ApiError.fromDioException(e);
  }
}
