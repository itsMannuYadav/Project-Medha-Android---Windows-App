import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_models.dart';
import '../../data/auth_repository.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    required this.status,
    this.user,
    this.error,
  });

  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);
  AuthState.authenticated(User u)
      : this(status: AuthStatus.authenticated, user: u);
  AuthState.error(String msg)
      : this(status: AuthStatus.unauthenticated, error: msg);

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repo = ref.read(authRepositoryProvider);
    final user = await repo.restoreSession();
    if (user != null) return AuthState.authenticated(user);
    return const AuthState.unauthenticated();
  }

  Future<void> login(String email, String password, String role) async {
    state = const AsyncData(AuthState.loading());
    final repo = ref.read(authRepositoryProvider);
    try {
      final user = await repo.login(
          LoginRequest(email: email, password: password, role: role));
      state = AsyncData(AuthState.authenticated(user));
    } catch (e) {
      state = const AsyncData(AuthState.unauthenticated());
      rethrow;
    }
  }

  /// Re-fetches /auth/me and updates state without going through the full
  /// loading transition — used after onboarding completes, since that
  /// changes `onboarded_at` server-side and the router's redirect gate needs
  /// the fresh value to stop sending the teacher back to /onboarding.
  Future<void> refreshUser() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      final user = await repo.getMe();
      state = AsyncData(AuthState.authenticated(user));
    } catch (_) {}
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncData(AuthState.unauthenticated());
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
