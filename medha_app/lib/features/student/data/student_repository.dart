import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'student_models.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(ref.read(apiClientProvider));
});

class StudentRepository {
  final ApiClient _api;
  StudentRepository(this._api);

  // ── Homework ────────────────────────────────────────────────────────────
  Future<List<HomeworkItem>> getMyHomework() async {
    final res = await _api.get('/student/homework');
    final list = res.data as List;
    return list.map((e) => HomeworkItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<HomeworkItem> markHomeworkDone(String id) async {
    final res = await _api.post('/student/homework/$id/done');
    return HomeworkItem.fromJson(res.data as Map<String, dynamic>);
  }

  Future<HomeworkItem> markHomeworkUndone(String id) async {
    final res = await _api.post('/student/homework/$id/undone');
    return HomeworkItem.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Timetable ───────────────────────────────────────────────────────────
  Future<List<TimetableSlot>> getMyTimetable() async {
    final res = await _api.get('/student/timetable');
    final list = res.data as List;
    return list.map((e) => TimetableSlot.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Fees ────────────────────────────────────────────────────────────────
  Future<List<FeeRecord>> getMyFees() async {
    final res = await _api.get('/student/fees');
    final list = res.data as List;
    return list.map((e) => FeeRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Report Card ─────────────────────────────────────────────────────────
  Future<List<ReportCardEntry>> getMyReportCard() async {
    final res = await _api.get('/student/report-card');
    final list = res.data as List;
    return list.map((e) => ReportCardEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Library ─────────────────────────────────────────────────────────────
  Future<List<LibraryResource>> getLibrary() async {
    final res = await _api.get('/library');
    final list = res.data as List;
    return list.map((e) => LibraryResource.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Resources (E-Library) ───────────────────────────────────────────────
  Future<List<LibraryResource>> getResources() async {
    final res = await _api.get('/resources');
    final list = res.data as List;
    return list.map((e) => LibraryResource.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Notifications ───────────────────────────────────────────────────────
  Future<List<NotificationItem>> getMyNotifications() async {
    final res = await _api.get('/student/notifications');
    final list = res.data as List;
    return list.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Subjects + Chapters ─────────────────────────────────────────────────
  Future<List<SubjectItem>> getMySubjects() async {
    final res = await _api.get('/student/subjects');
    final list = res.data as List;
    return list.map((e) => SubjectItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ChapterItem>> getChapters(String subjectId) async {
    final res = await _api.get('/subjects/$subjectId/chapters');
    final list = res.data as List;
    return list.map((e) => ChapterItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Tutor session ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createTutorSession(
      String subjectId, String chapterId) async {
    final res = await _api.post('/tutor/sessions', data: {
      'subject_id': subjectId,
      'chapter_id': chapterId,
    });
    return res.data as Map<String, dynamic>;
  }
}
