class ChatMessage {
  ChatMessage({required this.id, required this.role, required this.content, required this.createdAt});
  final String id;
  final String role; // "teacher" | "assistant"
  final String content;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        role: j['role'] as String,
        content: j['content'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class ChatSession {
  ChatSession({
    required this.id,
    required this.gradeId,
    required this.subjectId,
    required this.chapterId,
    required this.topicId,
    required this.title,
  });
  final String id;
  final String gradeId;
  final String subjectId;
  final String? chapterId;
  final String? topicId;
  final String? title;

  factory ChatSession.fromJson(Map<String, dynamic> j) => ChatSession(
        id: j['id'] as String,
        gradeId: j['grade_id'] as String,
        subjectId: j['subject_id'] as String,
        chapterId: j['chapter_id'] as String?,
        topicId: j['topic_id'] as String?,
        title: j['title'] as String?,
      );
}

class ChatSessionDetail {
  ChatSessionDetail({required this.session, required this.messages, required this.moduleId});
  final ChatSession session;
  final List<ChatMessage> messages;
  final String? moduleId;

  factory ChatSessionDetail.fromJson(Map<String, dynamic> j) => ChatSessionDetail(
        session: ChatSession.fromJson(j),
        messages: (j['messages'] as List).map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList(),
        moduleId: j['module_id'] as String?,
      );
}
