import '../models/attendance.dart';
import 'attendance_api.dart';

/// A light "which students are in this grade" lookup, reused wherever a
/// screen needs to pick a student (report card entry, fee logging) but
/// isn't actually about attendance. There's no separate roster endpoint on
/// the backend -- `/attendance`'s roster join already returns exactly this
/// (student_id, full_name, roll_number), so this just calls that and drops
/// the attendance-specific `status` field.
class RosterApi {
  RosterApi._();

  static Future<List<AttendanceStudent>> forGrade(String gradeId) async {
    final day = await AttendanceApi.get(gradeId: gradeId);
    return day.students;
  }
}
