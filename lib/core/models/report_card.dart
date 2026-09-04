class ReportCardMark {
  ReportCardMark({
    required this.subjectId,
    required this.subjectName,
    required this.term,
    required this.marksObtained,
    required this.maxMarks,
    required this.remarks,
    required this.updatedAt,
  });

  final String subjectId;
  final String subjectName;
  final String term;
  final double marksObtained;
  final double maxMarks;
  final String? remarks;
  final DateTime updatedAt;

  factory ReportCardMark.fromJson(Map<String, dynamic> j) => ReportCardMark(
        subjectId: j['subject_id'] as String,
        subjectName: j['subject_name'] as String,
        term: j['term'] as String,
        marksObtained: (j['marks_obtained'] as num).toDouble(),
        maxMarks: (j['max_marks'] as num).toDouble(),
        remarks: j['remarks'] as String?,
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );
}

class ReportCard {
  ReportCard({required this.studentId, required this.studentName, required this.marks});

  final String studentId;
  final String studentName;
  final List<ReportCardMark> marks;

  factory ReportCard.fromJson(Map<String, dynamic> j) => ReportCard(
        studentId: j['student_id'] as String,
        studentName: j['student_name'] as String,
        marks: (j['marks'] as List).map((m) => ReportCardMark.fromJson(m as Map<String, dynamic>)).toList(),
      );
}
