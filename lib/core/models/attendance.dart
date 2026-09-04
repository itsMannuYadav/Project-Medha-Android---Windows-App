class AttendanceStudent {
  AttendanceStudent({required this.studentId, required this.fullName, required this.rollNumber, required this.status});
  final String studentId;
  final String fullName;
  final String? rollNumber;
  final String? status; // "present" | "absent" | null (unmarked)

  AttendanceStudent copyWith({String? status}) => AttendanceStudent(
        studentId: studentId,
        fullName: fullName,
        rollNumber: rollNumber,
        status: status,
      );

  factory AttendanceStudent.fromJson(Map<String, dynamic> j) => AttendanceStudent(
        studentId: j['student_id'] as String,
        fullName: j['full_name'] as String,
        rollNumber: j['roll_number'] as String?,
        status: j['status'] as String?,
      );
}

class AttendanceDay {
  AttendanceDay({required this.gradeId, required this.gradeLabel, required this.date, required this.students});
  final String gradeId;
  final String gradeLabel;
  final DateTime date;
  final List<AttendanceStudent> students;

  factory AttendanceDay.fromJson(Map<String, dynamic> j) => AttendanceDay(
        gradeId: j['grade_id'] as String,
        gradeLabel: j['grade_label'] as String,
        date: DateTime.parse(j['date'] as String),
        students: (j['students'] as List).map((s) => AttendanceStudent.fromJson(s as Map<String, dynamic>)).toList(),
      );
}
