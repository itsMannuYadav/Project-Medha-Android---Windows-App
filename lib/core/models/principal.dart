class PrincipalStats {
  PrincipalStats({
    required this.teachers,
    required this.pendingTeachers,
    required this.students,
    required this.pendingStudents,
  });
  final int teachers;
  final int pendingTeachers;
  final int students;
  final int pendingStudents;

  factory PrincipalStats.fromJson(Map<String, dynamic> j) => PrincipalStats(
        teachers: j['teachers'] as int,
        pendingTeachers: j['pending_teachers'] as int,
        students: j['students'] as int,
        pendingStudents: j['pending_students'] as int,
      );
}

class PendingTeacher {
  PendingTeacher({
    required this.id,
    required this.fullName,
    required this.email,
    required this.employeeCode,
    required this.yearsOfExperience,
    required this.appliedAt,
  });
  final String id;
  final String fullName;
  final String email;
  final String? employeeCode;
  final int? yearsOfExperience;
  final DateTime appliedAt;

  factory PendingTeacher.fromJson(Map<String, dynamic> j) => PendingTeacher(
        id: j['id'] as String,
        fullName: j['full_name'] as String,
        email: j['email'] as String,
        employeeCode: j['employee_code'] as String?,
        yearsOfExperience: j['years_of_experience'] as int?,
        appliedAt: DateTime.parse(j['applied_at'] as String),
      );
}

class TeacherRosterItem {
  TeacherRosterItem({
    required this.id,
    required this.fullName,
    required this.email,
    required this.employeeCode,
    required this.yearsOfExperience,
  });
  final String id;
  final String fullName;
  final String email;
  final String? employeeCode;
  final int? yearsOfExperience;

  factory TeacherRosterItem.fromJson(Map<String, dynamic> j) => TeacherRosterItem(
        id: j['id'] as String,
        fullName: j['full_name'] as String,
        email: j['email'] as String,
        employeeCode: j['employee_code'] as String?,
        yearsOfExperience: j['years_of_experience'] as int?,
      );
}

class PrincipalStudentItem {
  PrincipalStudentItem({
    required this.id,
    required this.fullName,
    required this.gradeLabel,
    required this.rollNumber,
    required this.activated,
  });
  final String id;
  final String fullName;
  final String gradeLabel;
  final String? rollNumber;
  final bool activated;

  factory PrincipalStudentItem.fromJson(Map<String, dynamic> j) => PrincipalStudentItem(
        id: j['id'] as String,
        fullName: j['full_name'] as String,
        gradeLabel: j['grade_label'] as String,
        rollNumber: j['roll_number'] as String?,
        activated: j['activated'] as bool,
      );
}
