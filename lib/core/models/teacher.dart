class TeacherMe {
  TeacherMe({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.approvalStatus,
    required this.schoolId,
    required this.onboardedAt,
  });

  final String id;
  final String? email;
  final String fullName;
  final String role;
  final String approvalStatus;
  final String? schoolId;
  final DateTime? onboardedAt;

  bool get needsOnboarding => onboardedAt == null;

  factory TeacherMe.fromJson(Map<String, dynamic> j) => TeacherMe(
        id: j['id'] as String,
        email: j['email'] as String?,
        fullName: j['full_name'] as String,
        role: j['role'] as String,
        approvalStatus: j['approval_status'] as String,
        schoolId: j['school_id'] as String?,
        onboardedAt: j['onboarded_at'] == null ? null : DateTime.parse(j['onboarded_at'] as String),
      );
}
