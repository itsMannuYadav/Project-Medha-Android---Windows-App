import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_copy.dart';

final localeProvider = NotifierProvider<LocaleNotifier, String>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<String> {
  @override
  String build() {
    _loadFromPrefs();
    return AppLocale.en;
  }

  void _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.keyLocale);
    if (saved != null &&
        AppLocale.all.any((l) => l.code == saved)) {
      state = saved;
    }
  }

  Future<void> setLocale(String locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLocale, locale);
  }
}

final copyProvider = Provider<AppCopy>((ref) {
  final locale = ref.watch(localeProvider);
  return AppCopy(locale);
});
