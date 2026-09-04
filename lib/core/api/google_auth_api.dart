import 'package:google_sign_in/google_sign_in.dart';

import 'api_client.dart';
import 'api_error.dart';

enum _Outcome { cancelled, loggedIn, notRegistered }

/// Result of a Google sign-in attempt: either it logged the user straight in,
/// they cancelled, or the Google identity is new to Medha and the caller
/// should route to Register (prefilled with [email]/[fullName], carrying
/// [googleSub] along so the resulting registration is pre-linked).
class GoogleAuthResult {
  const GoogleAuthResult._({required this._outcome, this.googleSub, this.email, this.fullName});
  const GoogleAuthResult.cancelled() : this._(outcome: _Outcome.cancelled);
  const GoogleAuthResult.loggedIn() : this._(outcome: _Outcome.loggedIn);
  const GoogleAuthResult.notRegistered({
    required String googleSub,
    required String email,
    required String fullName,
  }) : this._(outcome: _Outcome.notRegistered, googleSub: googleSub, email: email, fullName: fullName);

  final _Outcome _outcome;
  final String? googleSub;
  final String? email;
  final String? fullName;

  bool get cancelled => _outcome == _Outcome.cancelled;
  bool get loggedIn => _outcome == _Outcome.loggedIn;
  bool get notRegistered => _outcome == _Outcome.notRegistered;
}

/// Wraps the Google Sign-In SDK + the backend's `/auth/google` exchange.
///
/// [serverClientId] must be the WEB client ID from Google Cloud Console
/// (matching `GOOGLE_CLIENT_ID` in the backend's `.env`) -- it's what makes
/// the ID token audienced for the backend rather than just the device. Fill
/// it in once that's created; until then `signIn()` throws.
///
/// Platform note: `google_sign_in` only ships Android/iOS/Web
/// implementations -- there's no Windows/desktop support, so this can only
/// be exercised on a real device or emulator, not the `flutter run -d
/// windows` build used for the rest of this app's manual testing.
class GoogleAuthApi {
  GoogleAuthApi._();

  // Web OAuth client ID from Google Cloud Console (project "my-medha-bihar-project")
  // — must match GOOGLE_CLIENT_ID in the backend's .env exactly.
  static const String serverClientId =
      '844027007623-arthf7fa0q0ligar8lfhu1kcmfqkf4oj.apps.googleusercontent.com';
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    );
    _initialized = true;
  }

  static Future<GoogleAuthResult> signIn() async {
    if (serverClientId.isEmpty) {
      throw ApiError(message: 'Google sign-in अभी सेट अप नहीं हुआ है (serverClientId खाली है)।');
    }
    await _ensureInitialized();

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const GoogleAuthResult.cancelled();
      }
      throw ApiError(message: 'Google साइन-इन विफल रहा (${e.code}).');
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw ApiError(message: 'Google से पहचान टोकन नहीं मिला।');
    }

    try {
      await apiCall(() async {
        final res = await ApiClient.instance.dio.post<Map<String, dynamic>>(
          '/auth/google',
          data: {'id_token': idToken},
        );
        ApiClient.instance.setAccessToken(res.data!['access_token'] as String);
      });
      return const GoogleAuthResult.loggedIn();
    } on ApiError catch (e) {
      if (e.isNotRegistered) {
        final detail = e.detailData!;
        return GoogleAuthResult.notRegistered(
          googleSub: detail['google_sub'] as String,
          email: detail['email'] as String? ?? '',
          fullName: detail['full_name'] as String? ?? '',
        );
      }
      rethrow;
    }
  }
}
