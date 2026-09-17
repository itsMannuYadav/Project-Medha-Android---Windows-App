class AppConstants {
  // API base — change to your production URL for release builds
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  // Storage keys
  static const keyAccessToken = 'medha_access_token';
  static const keyUserJson = 'medha_user_json';
  static const keyLocale = 'medha_locale';
  static const keySidebarCollapsed = 'medha_sidebar_collapsed';

  // Roles
  static const roleStudent = 'student';
  static const roleTeacher = 'teacher';
  static const rolePrincipal = 'principal';
  static const roleAdmin = 'admin';
}
