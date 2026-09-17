import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medha_app/core/network/api_client.dart';
import 'package:medha_app/core/theme/app_theme.dart';

/// Phone viewports we guarantee the UI works at.
/// Smallest first — 320x568 is the iPhone SE / low-end Android floor and is
/// where horizontal overflow shows up.
class Phone {
  final String name;
  final Size size;
  const Phone(this.name, this.size);

  static const iphoneSe = Phone('iPhone SE (320x568)', Size(320, 568));
  static const androidSmall = Phone('Android small (360x640)', Size(360, 640));
  static const iphone13 = Phone('iPhone 13 (390x844)', Size(390, 844));

  static const all = [iphoneSe, androidSmall, iphone13];
}

/// Serves canned JSON so screens render their *populated* state — that's where
/// layout breaks, not the empty state. Deliberately uses long realistic Hindi
/// and English strings, since short lorem text hides overflow bugs.
class FakeAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture) async {
    final path = options.path;
    final body = _routes.entries
        .firstWhere((e) => path.contains(e.key),
            orElse: () => const MapEntry('', <dynamic>[]))
        .value;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  static final Map<String, dynamic> _routes = {
    '/student/homework': [
      {
        'id': '1',
        'title': 'प्रकाश का अपवर्तन — अध्याय 10 के सभी प्रश्न हल करें',
        'description': 'NCERT पाठ्यपुस्तक के पृष्ठ 168 से 172 तक',
        'subject_name': 'विज्ञान (Science)',
        'due_date': '2026-09-25',
        'done': false,
      },
      {
        'id': '2',
        'title': 'Trigonometric Identities Practice Set',
        'subject_name': 'Mathematics',
        'due_date': '2026-09-20',
        'done': true,
      },
    ],
    '/student/timetable': [
      {
        'id': '1',
        'day_of_week': 'Monday',
        'start_time': '09:00',
        'end_time': '09:45',
        'subject_name': 'सामाजिक विज्ञान (Social Science)',
        'teacher_name': 'श्रीमती सुनीता कुमारी देवी',
        'room': 'Room 204-B',
      },
    ],
    '/student/fees': [
      {
        'id': '1',
        'label': 'Annual Tuition Fee — Academic Year 2026-27',
        'amount': 24500.50,
        'status': 'pending',
        'due_date': '2026-10-01',
      },
      {'id': '2', 'label': 'Examination Fee', 'amount': 1200.0, 'status': 'paid', 'paid_date': '2026-08-01'},
    ],
    '/student/report-card': [
      {
        'subject_name': 'सामाजिक विज्ञान (Social Science)',
        'marks_obtained': 78,
        'total_marks': 100,
        'grade': 'B+',
        'remarks': 'Consistent improvement shown throughout the term',
      },
      {'subject_name': 'Mathematics', 'marks_obtained': 45, 'total_marks': 100, 'grade': 'D'},
    ],
    '/student/subjects': [
      {'id': 's1', 'name': 'विज्ञान (Science)'},
      {'id': 's2', 'name': 'Mathematics'},
    ],
    '/student/notifications': [
      {
        'id': '1',
        'title': 'विद्यालय की वार्षिक परीक्षा की तिथि घोषित',
        'body': 'सभी छात्रों को सूचित किया जाता है कि वार्षिक परीक्षा 15 अक्टूबर से प्रारंभ होगी।',
        'created_at': '2026-09-15T10:00:00Z',
        'read': false,
      },
    ],
    '/library': [
      {
        'id': '1',
        'title': 'NCERT Class 10 Science Textbook — Complete Edition (Hindi Medium)',
        'type': 'pdf',
        'url': 'https://example.org/a.pdf',
        'subject_name': 'विज्ञान (Science)',
      },
    ],
    '/resources': [
      {'id': '1', 'title': 'Photosynthesis Explained — Video Lecture Series Part 1', 'type': 'video', 'subject_name': 'Science'},
    ],
    '/chapters': [
      {'id': 'c1', 'title': 'प्रकाश — परावर्तन तथा अपवर्तन', 'chapter_number': 10},
    ],
    '/teacher/dashboard': {
      'total_students': 142,
      'present_today': 128,
      'pending_homework': 17,
      'unread_notifications': 5,
    },
    '/teacher/students': [
      {'id': '1', 'full_name': 'आर्यन कुमार सिंह चौधरी', 'roll_number': '2026-10-A-042', 'status': 'approved'},
      {'id': '2', 'full_name': 'Priyanka Devi', 'roll_number': '2026-10-A-043', 'status': 'pending'},
    ],
    '/principal/analytics': {
      'total_students': 1284,
      'total_teachers': 47,
      'attendance_pct': 91,
      'pending_approvals': 12,
    },
    '/principal/teachers': [
      {'id': '1', 'full_name': 'श्रीमती सुनीता कुमारी देवी', 'email': 'sunita.kumari.devi@medha.education.gov.in'},
    ],
    '/principal/pending': [
      {'id': '1', 'full_name': 'राजेश कुमार यादव', 'role': 'teacher', 'email': 'rajesh.kumar.yadav@medha.education.gov.in'},
    ],
    '/reference/grades': [
      {'id': 'g1', 'label': 'Class 10', 'numeric_level': 10},
    ],
    '/reference/subjects': [
      {'id': 's1', 'name': 'Mathematics', 'board': 'BSEB'},
      {'id': 's2', 'name': 'सामाजिक विज्ञान (Social Science)', 'board': 'BSEB'},
    ],
  };
}

ProviderScope harness(Widget child, {double textScale = 1.0}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
    ..httpClientAdapter = FakeAdapter();
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(ApiClient(dio: dio))],
    child: MaterialApp(
      theme: AppTheme.light,
      builder: (ctx, widget) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(textScale)),
        child: widget!,
      ),
      home: Scaffold(body: child),
    ),
  );
}

/// Pumps [child] at [phone] and returns any layout error that occurred.
///
/// Deliberately avoids `pumpAndSettle`: these screens hold indefinitely
/// repeating animations (CircularProgressIndicator, RefreshIndicator), so
/// settling never terminates. Discrete pumps let the mocked futures resolve
/// and the populated state lay out, which is what we actually want to check.
Future<FlutterErrorDetails?> pumpAtPhone(
    WidgetTester tester, Widget child, Phone phone,
    {double textScale = 1.0}) async {
  tester.view.physicalSize = phone.size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  FlutterErrorDetails? captured;
  final prev = FlutterError.onError;
  FlutterError.onError = (details) {
    captured ??= details;
  };
  addTearDown(() => FlutterError.onError = prev);

  await tester.pumpWidget(harness(child, textScale: textScale));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  return captured;
}

/// True when the error is a RenderFlex/RenderBox overflow (the thing that
/// ships a striped band to a real phone), as opposed to unrelated noise.
bool isOverflow(FlutterErrorDetails d) {
  final s = d.exception.toString();
  return s.contains('overflowed by') || s.contains('A RenderFlex overflowed');
}
