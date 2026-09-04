/// A teacher's own view of one assignment they set — completion counts, no
/// per-student roster (the backend doesn't expose one for this).
class HomeworkListItem {
  HomeworkListItem({
    required this.id,
    required this.title,
    required this.gradeLabel,
    required this.subjectName,
    required this.dueDate,
    required this.createdAt,
    required this.doneCount,
    required this.totalCount,
  });

  final String id;
  final String title;
  final String gradeLabel;
  final String? subjectName;
  final DateTime? dueDate;
  final DateTime createdAt;
  final int doneCount;
  final int totalCount;

  factory HomeworkListItem.fromJson(Map<String, dynamic> j) => HomeworkListItem(
        id: j['id'] as String,
        title: j['title'] as String,
        gradeLabel: j['grade_label'] as String,
        subjectName: j['subject_name'] as String?,
        dueDate: j['due_date'] == null ? null : DateTime.parse(j['due_date'] as String),
        createdAt: DateTime.parse(j['created_at'] as String),
        doneCount: j['done_count'] as int,
        totalCount: j['total_count'] as int,
      );
}

class HomeworkDetail {
  HomeworkDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.gradeLabel,
    required this.subjectName,
    required this.dueDate,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final String gradeLabel;
  final String? subjectName;
  final DateTime? dueDate;
  final DateTime createdAt;

  factory HomeworkDetail.fromJson(Map<String, dynamic> j) => HomeworkDetail(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        gradeLabel: j['grade_label'] as String,
        subjectName: j['subject_name'] as String?,
        dueDate: j['due_date'] == null ? null : DateTime.parse(j['due_date'] as String),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

/// A student's own view of one assignment, with their personal done flag.
class HomeworkStudentItem {
  HomeworkStudentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectName,
    required this.dueDate,
    required this.done,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? subjectName;
  final DateTime? dueDate;
  final bool done;
  final DateTime createdAt;

  factory HomeworkStudentItem.fromJson(Map<String, dynamic> j) => HomeworkStudentItem(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        subjectName: j['subject_name'] as String?,
        dueDate: j['due_date'] == null ? null : DateTime.parse(j['due_date'] as String),
        done: j['done'] as bool,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
