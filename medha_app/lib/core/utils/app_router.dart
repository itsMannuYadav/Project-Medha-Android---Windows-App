import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/student_activate_screen.dart';
import '../../features/student/presentation/screens/student_shell.dart';
import '../../features/student/presentation/screens/learn_screen.dart';
import '../../features/student/presentation/screens/bihar_darpan_screen.dart';
import '../../features/student/presentation/screens/homework_screen.dart';
import '../../features/student/presentation/screens/timetable_screen.dart';
import '../../features/student/presentation/screens/report_card_screen.dart';
import '../../features/student/presentation/screens/fees_screen.dart';
import '../../features/student/presentation/screens/library_screen.dart';
import '../../features/student/presentation/screens/notes_screen.dart';
import '../../features/student/presentation/screens/practice_screen.dart';
import '../../features/student/presentation/screens/resources_screen.dart';
import '../../features/student/presentation/screens/simulations_screen.dart';
import '../../features/student/presentation/screens/english_screen.dart';
import '../../features/teacher/presentation/screens/teacher_shell.dart';
import '../../features/teacher/presentation/screens/teacher_dashboard_screen.dart';
import '../../features/teacher/presentation/screens/teacher_attendance_screen.dart';
import '../../features/teacher/presentation/screens/teacher_homework_screen.dart';
import '../../features/teacher/presentation/screens/teacher_timetable_screen.dart';
import '../../features/teacher/presentation/screens/teacher_report_card_screen.dart';
import '../../features/teacher/presentation/screens/teacher_students_screen.dart';
import '../../features/teacher/presentation/screens/teacher_notifications_screen.dart';
import '../../features/teacher/presentation/screens/teacher_ask_screen.dart';
import '../../features/teacher/presentation/screens/teacher_profile_screen.dart';
import '../../features/teacher/presentation/screens/teacher_onboarding_screen.dart';
import '../../features/principal/presentation/screens/principal_shell.dart';
import '../../features/principal/presentation/screens/principal_dashboard_screen.dart';
import '../../features/auth/data/auth_models.dart';

/// Bridges Riverpod's [authProvider] to GoRouter's [refreshListenable].
///
/// GoRouter re-runs `redirect` whenever this notifies — it does NOT rebuild
/// the router or any mounted screen. That distinction matters: `login()`
/// transitions through loading -> authenticated/unauthenticated, i.e. at
/// least two state changes per attempt. A provider that does
/// `ref.watch(authProvider)` and returns a *new* `GoRouter(...)` on every one
/// of those changes tears down and recreates the whole navigator tree each
/// time — which wipes local State on whatever screen is mounted (typed text,
/// selected tab) mid-login. Confirmed against the real backend: submitting
/// valid credentials reset the login form to its initial state and sent a
/// stale/empty password, because the router (and therefore the screen) was
/// rebuilt out from under the in-progress request.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final authState = auth.valueOrNull;
      final isLoading = auth.isLoading || authState?.isLoading == true;
      if (isLoading) return null;

      final isAuth = authState?.isAuthenticated ?? false;
      final onLoginPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/student/activate';
      final onOnboarding = state.matchedLocation == '/onboarding';

      if (!isAuth && !onLoginPage) return '/login';
      if (isAuth && onLoginPage) {
        final user = authState?.user;
        if (user == null) return '/login';
        return _homeFor(user);
      }

      // Mirrors shiksha_sathi's (protected)/(app)/layout.tsx: a teacher whose
      // onboarded_at is null is sent to /onboarding regardless of where they
      // were headed; an already-onboarded teacher landing on /onboarding
      // directly is bounced to the dashboard instead of redoing the wizard.
      if (isAuth) {
        final user = authState?.user;
        final needsOnboarding = user != null && user.isTeacher && user.onboardedAt == null;
        if (needsOnboarding && !onOnboarding) return '/onboarding';
        if (!needsOnboarding && onOnboarding) return user != null ? _homeFor(user) : '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (ctx, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (ctx, state) => RegisterScreen(initialRole: state.uri.queryParameters['role']),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (ctx, state) => const TeacherOnboardingScreen(),
      ),
      GoRoute(
        path: '/student/activate',
        builder: (ctx, state) => const StudentActivateScreen(),
      ),
      // ── Student shell ───────────────────────────────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => StudentShell(child: child),
        routes: [
          GoRoute(
              path: '/learn',
              builder: (ctx, s) => const LearnScreen()),
          GoRoute(
              path: '/bihar-darpan',
              builder: (ctx, s) => const BiharDarpanScreen()),
          GoRoute(
              path: '/english',
              builder: (ctx, s) => const EnglishScreen()),
          GoRoute(
              path: '/my-practice',
              builder: (ctx, s) => const PracticeScreen()),
          GoRoute(
              path: '/my-notes',
              builder: (ctx, s) => const NotesScreen()),
          GoRoute(
              path: '/library',
              builder: (ctx, s) => const LibraryScreen()),
          GoRoute(
              path: '/learn-lab',
              builder: (ctx, s) => const SimulationsScreen()),
          GoRoute(
              path: '/my-homework',
              builder: (ctx, s) => const HomeworkScreen()),
          GoRoute(
              path: '/my-timetable',
              builder: (ctx, s) => const TimetableScreen()),
          GoRoute(
              path: '/my-report-card',
              builder: (ctx, s) => const ReportCardScreen()),
          GoRoute(
              path: '/my-resources',
              builder: (ctx, s) => const ResourcesScreen()),
          GoRoute(
              path: '/fees',
              builder: (ctx, s) => const FeesScreen()),
        ],
      ),
      // ── Teacher shell ───────────────────────────────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => TeacherShell(child: child),
        routes: [
          GoRoute(
              path: '/dashboard',
              builder: (ctx, s) => const TeacherDashboardScreen()),
          GoRoute(
              path: '/ask',
              builder: (ctx, s) => const TeacherAskScreen()),
          GoRoute(
              path: '/attendance',
              builder: (ctx, s) => const TeacherAttendanceScreen()),
          GoRoute(
              path: '/homework',
              builder: (ctx, s) => const TeacherHomeworkScreen()),
          GoRoute(
              path: '/timetable',
              builder: (ctx, s) => const TeacherTimetableScreen()),
          GoRoute(
              path: '/report-card',
              builder: (ctx, s) => const TeacherReportCardScreen()),
          GoRoute(
              path: '/students',
              builder: (ctx, s) => const TeacherStudentsScreen()),
          GoRoute(
              path: '/notifications',
              builder: (ctx, s) => const TeacherNotificationsScreen()),
          GoRoute(
              path: '/profile',
              builder: (ctx, s) => const TeacherProfileScreen()),
        ],
      ),
      // ── Principal shell ─────────────────────────────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => PrincipalShell(child: child),
        routes: [
          GoRoute(
              path: '/principal',
              builder: (ctx, s) => const PrincipalDashboardScreen()),
        ],
      ),
    ],
  );
});

String _homeFor(User user) {
  switch (user.role) {
    case 'student':
      return '/learn';
    case 'teacher':
      return '/dashboard';
    case 'principal':
      return '/principal';
    default:
      return '/login';
  }
}
