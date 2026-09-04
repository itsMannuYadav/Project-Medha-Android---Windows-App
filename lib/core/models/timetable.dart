class TimetableSlot {
  TimetableSlot({
    required this.dayOfWeek,
    required this.periodNumber,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
  });

  final int dayOfWeek; // 0=Monday
  final int periodNumber;
  final String? subjectId;
  final String? subjectName;
  final String? teacherId;
  final String? teacherName;

  factory TimetableSlot.fromJson(Map<String, dynamic> j) => TimetableSlot(
        dayOfWeek: j['day_of_week'] as int,
        periodNumber: j['period_number'] as int,
        subjectId: j['subject_id'] as String?,
        subjectName: j['subject_name'] as String?,
        teacherId: j['teacher_id'] as String?,
        teacherName: j['teacher_name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'period_number': periodNumber,
        'subject_id': ?subjectId,
        'teacher_id': ?teacherId,
      };
}

class Timetable {
  Timetable({required this.gradeId, required this.gradeLabel, required this.slots});

  final String gradeId;
  final String gradeLabel;
  final List<TimetableSlot> slots;

  factory Timetable.fromJson(Map<String, dynamic> j) => Timetable(
        gradeId: j['grade_id'] as String,
        gradeLabel: j['grade_label'] as String,
        slots: (j['slots'] as List).map((s) => TimetableSlot.fromJson(s as Map<String, dynamic>)).toList(),
      );
}
