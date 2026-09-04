class TeacherMe {
  TeacherMe({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.approvalStatus,
    required this.schoolId,
    required this.gradeId,
    required this.rollNumber,
    required this.onboardedAt,
  });

  final String id;
  final String? email;
  final String fullName;
  final String role;
  final String approvalStatus;
  final String? schoolId;
  // Only set for role == "student": their own class and roll number.
  final String? gradeId;
  final String? rollNumber;
  final DateTime? onboardedAt;

  bool get needsOnboarding => onboardedAt == null;

  factory TeacherMe.fromJson(Map<String, dynamic> j) => TeacherMe(
        id: j['id'] as String,
        email: j['email'] as String?,
        fullName: j['full_name'] as String,
        role: j['role'] as String,
        approvalStatus: j['approval_status'] as String,
        schoolId: j['school_id'] as String?,
        gradeId: j['grade_id'] as String?,
        rollNumber: j['roll_number'] as String?,
        onboardedAt: j['onboarded_at'] == null ? null : DateTime.parse(j['onboarded_at'] as String),
      );
}
