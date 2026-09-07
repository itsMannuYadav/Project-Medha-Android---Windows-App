class AdminStats {
  AdminStats({
    required this.schools,
    required this.principals,
    required this.teachers,
    required this.pendingPrincipals,
  });
  final int schools;
  final int principals;
  final int teachers;
  final int pendingPrincipals;

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        schools: j['schools'] as int,
        principals: j['principals'] as int,
        teachers: j['teachers'] as int,
        pendingPrincipals: j['pending_principals'] as int,
      );
}

class PendingPrincipal {
  PendingPrincipal({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobileNumber,
    required this.qualification,
    required this.schoolId,
    required this.schoolName,
    required this.districtName,
    required this.appliedAt,
  });
  final String id;
  final String fullName;
  final String email;
  final String? mobileNumber;
  final String? qualification;
  final String schoolId;
  final String schoolName;
  final String districtName;
  final DateTime appliedAt;

  factory PendingPrincipal.fromJson(Map<String, dynamic> j) => PendingPrincipal(
        id: j['id'] as String,
        fullName: j['full_name'] as String,
        email: j['email'] as String,
        mobileNumber: j['mobile_number'] as String?,
        qualification: j['qualification'] as String?,
        schoolId: j['school_id'] as String,
        schoolName: j['school_name'] as String,
        districtName: j['district_name'] as String,
        appliedAt: DateTime.parse(j['applied_at'] as String),
      );
}

class SchoolPrincipalStatus {
  SchoolPrincipalStatus({
    required this.schoolId,
    required this.schoolName,
    required this.districtName,
    required this.principalName,
    required this.principalEmail,
    required this.principalStatus,
  });
  final String schoolId;
  final String schoolName;
  final String districtName;
  final String? principalName;
  final String? principalEmail;
  final String? principalStatus;

  factory SchoolPrincipalStatus.fromJson(Map<String, dynamic> j) => SchoolPrincipalStatus(
        schoolId: j['school_id'] as String,
        schoolName: j['school_name'] as String,
        districtName: j['district_name'] as String,
        principalName: j['principal_name'] as String?,
        principalEmail: j['principal_email'] as String?,
        principalStatus: j['principal_status'] as String?,
      );
}
