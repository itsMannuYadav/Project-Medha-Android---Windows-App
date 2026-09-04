import 'dart:io' show Platform;

/// Where the Medha backend lives. Override at build/run time with
/// `--dart-define=API_BASE_URL=https://your-backend`.
///
/// The default assumes a locally-running backend (`uvicorn backend.app:app`)
/// reached from this same machine (Windows desktop) or, for Android, from the
/// emulator's host-loopback address -- a **real** Android device instead
/// needs your machine's LAN IP here, not 10.0.2.2.
class ApiConfig {
  ApiConfig._();

  static const _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (!Platform.isAndroid) return 'http://127.0.0.1:8000';
    // Android emulator's alias for the host machine's localhost.
    return 'http://10.0.2.2:8000';
  }
}
