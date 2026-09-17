// Medha UI strings — mirrors lib/i18n/index.ts.
// Two locales: 'en', 'hi'. The 'hinglish' switch branches below are dead
// code — AppLocale.all no longer offers it as selectable, since the real
// product never had a third language option (see AppLocale's doc comment).
// Left in place rather than mechanically stripped from every branch; safe
// to remove wherever touched next.

class AppCopy {
  final String locale;
  const AppCopy(this.locale);

  // ── Brand ──────────────────────────────────────────────────────────────
  String get brand => 'Medha';

  // ── Auth ───────────────────────────────────────────────────────────────
  String get loginTitle => switch (locale) {
        'hi' => 'मेधा में आपका स्वागत है',
        'hinglish' => 'Medha mein Welcome',
        _ => 'Welcome to Medha',
      };
  String get loginSubtitle => switch (locale) {
        'hi' => 'अपने अकाउंट में साइन इन करें',
        'hinglish' => 'Apne account mein sign in karein',
        _ => 'Sign in to your Medha account',
      };
  String get loginEmail => switch (locale) {
        'hi' => 'ईमेल',
        _ => 'Email',
      };
  String get loginPassword => switch (locale) {
        'hi' => 'पासवर्ड',
        _ => 'Password',
      };
  String get loginSubmit => switch (locale) {
        'hi' => 'साइन इन करें',
        'hinglish' => 'Sign In karein',
        _ => 'Sign in',
      };
  String get loginSubmitting => switch (locale) {
        'hi' => 'साइन इन हो रहा है…',
        _ => 'Signing in…',
      };
  String get loginTabStudent => switch (locale) {
        'hi' => 'छात्र',
        _ => 'Student',
      };
  String get loginTabTeacher => switch (locale) {
        'hi' => 'शिक्षक',
        _ => 'Teacher',
      };
  String get loginTabPrincipal => switch (locale) {
        'hi' => 'प्रधानाचार्य',
        _ => 'Principal',
      };
  String get loginNewToMedha => switch (locale) {
        'hi' => 'मेधा पर नए हैं?',
        'hinglish' => 'Medha par naye hain?',
        _ => 'New to Medha?',
      };
  String get loginRegister => switch (locale) {
        'hi' => 'रजिस्टर करें',
        _ => 'Register',
      };
  String loginWelcomeBack(String name) => switch (locale) {
        'hi' => 'वापस स्वागत है, $name!',
        'hinglish' => 'Welcome back, $name!',
        _ => 'Welcome back, $name!',
      };

  // ── Sidebar quote ──────────────────────────────────────────────────────
  String get sidebarQuote =>
      'शिक्षा से समृद्ध बिहार, समृद्ध भारत';

  // ── Student nav ────────────────────────────────────────────────────────
  String get navAskMedha => switch (locale) {
        'hi' => 'मेधा से पूछो',
        'hinglish' => 'Ask Medha',
        _ => 'Ask Medha',
      };
  String get navBiharDarpan => 'Bihar Darpan';
  String get navEnglish => switch (locale) {
        'hi' => 'अंग्रेज़ी सीखें',
        'hinglish' => 'English Seekhein',
        _ => 'Learn English',
      };
  String get navPractice => switch (locale) {
        'hi' => 'अभ्यास',
        _ => 'Practice',
      };
  String get navNotes => switch (locale) {
        'hi' => 'नोट्स',
        _ => 'Notes',
      };
  String get navLibrary => switch (locale) {
        'hi' => 'पुस्तकालय',
        _ => 'Library',
      };
  String get navSimulations => switch (locale) {
        'hi' => 'सिमुलेशन',
        _ => 'Simulations',
      };
  String get navHomework => switch (locale) {
        'hi' => 'गृहकार्य',
        _ => 'Homework',
      };
  String get navTimetable => switch (locale) {
        'hi' => 'समय सारिणी',
        _ => 'Timetable',
      };
  String get navReportCard => switch (locale) {
        'hi' => 'रिपोर्ट कार्ड',
        _ => 'Report Card',
      };
  String get navResources => switch (locale) {
        'hi' => 'ई-लाइब्रेरी',
        _ => 'E-Library',
      };
  String get navFees => switch (locale) {
        'hi' => 'फीस',
        _ => 'Fees',
      };

  // ── Teacher nav ────────────────────────────────────────────────────────
  String get navHome => switch (locale) {
        'hi' => 'होम',
        _ => 'Home',
      };
  String get navDashboard => switch (locale) {
        'hi' => 'डैशबोर्ड',
        _ => 'Dashboard',
      };
  String get navAttendance => switch (locale) {
        'hi' => 'उपस्थिति',
        _ => 'Attendance',
      };
  String get navStudents => switch (locale) {
        'hi' => 'छात्र',
        _ => 'Students',
      };
  String get navNotifications => switch (locale) {
        'hi' => 'सूचनाएं',
        _ => 'Notifications',
      };
  String get navTools => switch (locale) {
        'hi' => 'टूल्स',
        _ => 'Tools',
      };

  // ── Student learn screen ───────────────────────────────────────────────
  String get askTitle => switch (locale) {
        'hi' => 'मेधा से पूछो',
        'hinglish' => 'Ask Medha',
        _ => 'Ask Medha',
      };
  String get askSub => switch (locale) {
        'hi' => 'अपना सवाल पूछें — हिंदी या अंग्रेज़ी में',
        'hinglish' => 'Apna sawal poochein',
        _ => 'Ask any doubt — in Hindi or English',
      };
  String askHeading(String name) => switch (locale) {
        'hi' => name.isEmpty ? 'नमस्ते! क्या पूछना है?' : 'नमस्ते $name!',
        'hinglish' =>
          name.isEmpty ? 'Hello! Kya poochna hai?' : 'Hello $name!',
        _ => name.isEmpty ? 'Hi there! What would you like to know?' : 'Hi $name!',
      };
  String get askPlaceholder => switch (locale) {
        'hi' => 'अपना सवाल यहाँ लिखें…',
        'hinglish' => 'Apna sawaal yahan likhein…',
        _ => 'Type your question here…',
      };
  String get pickSubjectFirst => switch (locale) {
        'hi' => 'पहले विषय और अध्याय चुनें',
        'hinglish' => 'Pehle subject aur chapter chunein',
        _ => 'Please pick a subject and chapter first',
      };

  // ── Common ─────────────────────────────────────────────────────────────
  String get logout => switch (locale) {
        'hi' => 'लॉग आउट',
        _ => 'Log out',
      };
  String get loading => switch (locale) {
        'hi' => 'लोड हो रहा है…',
        _ => 'Loading…',
      };
  String get noData => switch (locale) {
        'hi' => 'कोई डेटा नहीं',
        _ => 'No data',
      };
  String get retry => switch (locale) {
        'hi' => 'पुनः प्रयास करें',
        _ => 'Retry',
      };
  String get done => switch (locale) {
        'hi' => 'हो गया',
        _ => 'Done',
      };
  String get submit => switch (locale) {
        'hi' => 'जमा करें',
        _ => 'Submit',
      };
  String get cancel => switch (locale) {
        'hi' => 'रद्द करें',
        _ => 'Cancel',
      };

  // ── Homework ───────────────────────────────────────────────────────────
  String get homeworkTitle => switch (locale) {
        'hi' => 'मेरा गृहकार्य',
        _ => 'My Homework',
      };
  String get homeworkEmpty => switch (locale) {
        'hi' => 'अभी कोई गृहकार्य नहीं है',
        _ => 'No homework assigned yet',
      };

  // ── Timetable ──────────────────────────────────────────────────────────
  String get timetableTitle => switch (locale) {
        'hi' => 'समय सारिणी',
        _ => 'My Timetable',
      };
  String get timetableEmpty => switch (locale) {
        'hi' => 'अभी समय सारिणी नहीं है',
        _ => 'No timetable available',
      };

  // ── Fees ───────────────────────────────────────────────────────────────
  String get feesTitle => switch (locale) {
        'hi' => 'फीस विवरण',
        _ => 'Fees',
      };
  String get feesEmpty => switch (locale) {
        'hi' => 'कोई फीस रिकॉर्ड नहीं',
        _ => 'No fees records',
      };
}

/// Matches shiksha_sathi/lib/i18n/index.ts's LOCALES exactly — the real
/// product only ever had English and Hindi. A third "Hinglish" option was
/// built into this app at some point but never existed in the actual
/// product; removed 2026-09-17 once compared directly against the live site.
class AppLocale {
  static const en = 'en';
  static const hi = 'hi';

  static const all = [
    (code: en, label: 'English', shortLabel: 'EN'),
    (code: hi, label: 'हिंदी', shortLabel: 'हिं'),
  ];
}
