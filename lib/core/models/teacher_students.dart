class TeacherStudentStats {
  TeacherStudentStats({required this.students, required this.pendingStudents});
  final int students;
  final int pendingStudents;

  factory TeacherStudentStats.fromJson(Map<String, dynamic> j) => TeacherStudentStats(
        students: j['students'] as int,
        pendingStudents: j['pending_students'] as int,
      );
}

class PendingStudent {
  PendingStudent({
    required this.id,
    required this.fullName,
    required this.gradeId,
    required this.gradeLabel,
    required this.rollNumber,
    required this.appliedAt,
  });
  final String id;
  final String fullName;
  final String gradeId;
  final String gradeLabel;
  final String? rollNumber;
  final DateTime appliedAt;

  factory PendingStudent.fromJson(Map<String, dynamic> j) => PendingStudent(
        id: j['id'] as String,
        fullName: j['full_name'] as String,
        gradeId: j['grade_id'] as String,
        gradeLabel: j['grade_label'] as String,
        rollNumber: j['roll_number'] as String?,
        appliedAt: DateTime.parse(j['applied_at'] as String),
      );
}

class TeacherStudentItem {
  TeacherStudentItem({
    required this.id,
    required this.fullName,
    required this.gradeId,
    required this.gradeLabel,
    required this.rollNumber,
    required this.email,
    required this.activated,
    required this.approvedAt,
  });
  final String id;
  final String fullName;
  final String gradeId;
  final String gradeLabel;
  final String? rollNumber;
  final String? email;
  final bool activated;
  final DateTime? approvedAt;

  factory TeacherStudentItem.fromJson(Map<String, dynamic> j) => TeacherStudentItem(
        id: j['id'] as String,
        fullName: j['full_name'] as String,
        gradeId: j['grade_id'] as String,
        gradeLabel: j['grade_label'] as String,
        rollNumber: j['roll_number'] as String?,
        email: j['email'] as String?,
        activated: j['activated'] as bool,
        approvedAt: j['approved_at'] == null ? null : DateTime.parse(j['approved_at'] as String),
      );
}
