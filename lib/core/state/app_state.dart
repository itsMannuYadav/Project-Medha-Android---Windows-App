import 'package:flutter/widgets.dart';

import '../models/teacher.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// The three UI-language options teachers can choose between — see
/// memory/medha-flutter-design-decisions: comfort varies enough across
/// Bihar's teachers that a binary EN/HI switch leaves people out, so
/// Hinglish is a first-class third option, not an afterthought.
enum AppLanguage {
  english('English', 'EN'),
  hindi('हिन्दी', 'हिं'),
  hinglish('Hinglish', 'Hg');

  const AppLanguage(this.label, this.shortLabel);

  final String label;
  final String shortLabel;
}

/// App-wide state that more than one screen needs to read or change.
/// Deliberately small — this is a UI-fidelity build, not yet wired to the
/// backend, so it only tracks what the mockups themselves need (the
/// language choice, and the signed-in teacher's display name/school for
/// screens that show them).
class AppState extends ChangeNotifier {
  AppLanguage _language = AppLanguage.hindi;
  AppLanguage get language => _language;

  set language(AppLanguage value) {
    if (value == _language) return;
    _language = value;
    notifyListeners();
  }

  AuthStatus _authStatus = AuthStatus.unknown;
  AuthStatus get authStatus => _authStatus;

  TeacherMe? _teacher;
  TeacherMe? get teacher => _teacher;

  void setSignedIn(TeacherMe teacher) {
    _teacher = teacher;
    _authStatus = AuthStatus.signedIn;
    notifyListeners();
  }

  void setSignedOut() {
    _teacher = null;
    _authStatus = AuthStatus.signedOut;
    notifyListeners();
  }
}

/// Makes an [AppState] available to the whole widget tree below it.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context, {bool listen = true}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<AppScope>()
        : context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope.of() called with no AppScope in the tree');
    return scope!.notifier!;
  }
}
