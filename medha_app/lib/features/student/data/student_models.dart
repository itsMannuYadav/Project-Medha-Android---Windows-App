class HomeworkItem {
  final String id;
  final String title;
  final String? description;
  final String? subjectName;
  final String? dueDate;
  final bool done;

  const HomeworkItem({
    required this.id,
    required this.title,
    this.description,
    this.subjectName,
    this.dueDate,
    required this.done,
  });

  factory HomeworkItem.fromJson(Map<String, dynamic> j) => HomeworkItem(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        subjectName: j['subject_name'] as String?,
        dueDate: j['due_date'] as String?,
        done: (j['done'] as bool?) ?? false,
      );

  HomeworkItem copyWith({bool? done}) =>
      HomeworkItem(
        id: id,
        title: title,
        description: description,
        subjectName: subjectName,
        dueDate: dueDate,
        done: done ?? this.done,
      );
}

class TimetableSlot {
  final String id;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String subjectName;
  final String? teacherName;
  final String? room;

  const TimetableSlot({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subjectName,
    this.teacherName,
    this.room,
  });

  factory TimetableSlot.fromJson(Map<String, dynamic> j) => TimetableSlot(
        id: j['id'] as String,
        dayOfWeek: j['day_of_week'] as String,
        startTime: j['start_time'] as String,
        endTime: j['end_time'] as String,
        subjectName: j['subject_name'] as String? ?? j['subject']?['name'] as String? ?? '',
        teacherName: j['teacher_name'] as String? ?? j['teacher']?['full_name'] as String?,
        room: j['room'] as String?,
      );
}

class FeeRecord {
  final String id;
  final String label;
  final double amount;
  final String status;
  final String? dueDate;
  final String? paidDate;

  const FeeRecord({
    required this.id,
    required this.label,
    required this.amount,
    required this.status,
    this.dueDate,
    this.paidDate,
  });

  bool get isPaid => status == 'paid';
  bool get isOverdue => status == 'overdue';

  factory FeeRecord.fromJson(Map<String, dynamic> j) => FeeRecord(
        id: j['id'] as String,
        label: j['label'] as String? ?? j['fee_type'] as String? ?? '',
        amount: (j['amount'] as num).toDouble(),
        status: j['status'] as String? ?? 'pending',
        dueDate: j['due_date'] as String?,
        paidDate: j['paid_date'] as String?,
      );
}

class SubjectItem {
  final String id;
  final String name;

  const SubjectItem({required this.id, required this.name});
  factory SubjectItem.fromJson(Map<String, dynamic> j) =>
      SubjectItem(id: j['id'] as String, name: j['name'] as String);
}

class ChapterItem {
  final String id;
  final String title;
  final int chapterNumber;

  const ChapterItem({
    required this.id,
    required this.title,
    required this.chapterNumber,
  });

  factory ChapterItem.fromJson(Map<String, dynamic> j) => ChapterItem(
        id: j['id'] as String,
        title: j['title'] as String,
        chapterNumber: j['chapter_number'] as int? ?? 0,
      );
}

class LibraryResource {
  final String id;
  final String title;
  final String? type;
  final String? url;
  final String? subjectName;

  const LibraryResource({
    required this.id,
    required this.title,
    this.type,
    this.url,
    this.subjectName,
  });

  factory LibraryResource.fromJson(Map<String, dynamic> j) =>
      LibraryResource(
        id: j['id'] as String,
        title: j['title'] as String,
        type: j['type'] as String?,
        url: j['url'] as String? ?? j['file_url'] as String?,
        subjectName: j['subject_name'] as String?,
      );
}

class NotificationItem {
  final String id;
  final String title;
  final String? body;
  final String? audience;
  final String createdAt;
  final bool read;

  const NotificationItem({
    required this.id,
    required this.title,
    this.body,
    this.audience,
    required this.createdAt,
    this.read = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> j) =>
      NotificationItem(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String? ?? j['message'] as String?,
        audience: j['audience'] as String?,
        createdAt: j['created_at'] as String,
        read: (j['read'] as bool?) ?? false,
      );
}

class ReportCardEntry {
  final String subjectName;
  final int? marksObtained;
  final int? totalMarks;
  final String? grade;
  final String? remarks;

  const ReportCardEntry({
    required this.subjectName,
    this.marksObtained,
    this.totalMarks,
    this.grade,
    this.remarks,
  });

  factory ReportCardEntry.fromJson(Map<String, dynamic> j) => ReportCardEntry(
        subjectName: j['subject_name'] as String? ?? '',
        marksObtained: j['marks_obtained'] as int?,
        totalMarks: j['total_marks'] as int?,
        grade: j['grade'] as String?,
        remarks: j['remarks'] as String?,
      );
}
