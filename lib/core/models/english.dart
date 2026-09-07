class EnglishSession {
  EnglishSession({
    required this.id,
    required this.lessonTopic,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? lessonTopic;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory EnglishSession.fromJson(Map<String, dynamic> j) => EnglishSession(
        id: j['id'] as String,
        lessonTopic: j['lesson_topic'] as String?,
        title: j['title'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );
}

class EnglishMessage {
  EnglishMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String role;
  final String content;
  final DateTime createdAt;

  factory EnglishMessage.fromJson(Map<String, dynamic> j) => EnglishMessage(
        id: j['id'] as String,
        role: j['role'] as String,
        content: j['content'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class EnglishSessionDetail extends EnglishSession {
  EnglishSessionDetail({
    required super.id,
    required super.lessonTopic,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    required this.messages,
  });

  final List<EnglishMessage> messages;

  factory EnglishSessionDetail.fromJson(Map<String, dynamic> j) => EnglishSessionDetail(
        id: j['id'] as String,
        lessonTopic: j['lesson_topic'] as String?,
        title: j['title'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
        messages: (j['messages'] as List? ?? [])
            .map((m) => EnglishMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}
