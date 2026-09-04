/// The student doubt-chat feature (`/tutor/*`) -- a separate backend
/// package from the teacher's own `/chat/*`, so these are separate models
/// rather than reusing `ChatSession`/`ChatMessage` (a tutor session has no
/// `grade_id`; the student's own class is implicit).
class TutorMessage {
  TutorMessage({required this.id, required this.role, required this.content, required this.createdAt});
  final String id;
  final String role; // "student" | "assistant"
  final String content;
  final DateTime createdAt;

  factory TutorMessage.fromJson(Map<String, dynamic> j) => TutorMessage(
        id: j['id'] as String,
        role: j['role'] as String,
        content: j['content'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class TutorSession {
  TutorSession({required this.id, required this.subjectId, required this.chapterId, required this.title});
  final String id;
  final String subjectId;
  final String? chapterId;
  final String? title;

  factory TutorSession.fromJson(Map<String, dynamic> j) => TutorSession(
        id: j['id'] as String,
        subjectId: j['subject_id'] as String,
        chapterId: j['chapter_id'] as String?,
        title: j['title'] as String?,
      );
}

class TutorSessionDetail {
  TutorSessionDetail({required this.session, required this.messages});
  final TutorSession session;
  final List<TutorMessage> messages;

  factory TutorSessionDetail.fromJson(Map<String, dynamic> j) => TutorSessionDetail(
        session: TutorSession.fromJson(j),
        messages: (j['messages'] as List).map((m) => TutorMessage.fromJson(m as Map<String, dynamic>)).toList(),
      );
}
