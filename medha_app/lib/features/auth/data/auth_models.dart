import 'dart:convert';

class User {
  final String id;
  final String fullName;
  final String? email;
  final String role;
  final String approvalStatus;
  final String? schoolId;
  final String? gradeId;
  final String? rollNumber;
  final String? onboardedAt;

  const User({
    required this.id,
    required this.fullName,
    this.email,
    required this.role,
    required this.approvalStatus,
    this.schoolId,
    this.gradeId,
    this.rollNumber,
    this.onboardedAt,
  });

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  String initials() {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final a = parts[0].isNotEmpty ? parts[0][0] : '';
    final b = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (a + b).toUpperCase();
  }

  bool get isStudent => role == 'student';
  bool get isTeacher => role == 'teacher';
  bool get isPrincipal => role == 'principal';
  bool get isAdmin => role == 'admin';
  bool get isApproved => approvalStatus == 'approved';
  bool get isPending => approvalStatus == 'pending';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?) ?? '',
      email: json['email'] as String?,
      role: json['role'] as String,
      approvalStatus: (json['approval_status'] as String?) ?? 'pending',
      schoolId: json['school_id'] as String?,
      gradeId: json['grade_id'] as String?,
      rollNumber: json['roll_number'] as String?,
      onboardedAt: json['onboarded_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'role': role,
        'approval_status': approvalStatus,
        'school_id': schoolId,
        'grade_id': gradeId,
        'roll_number': rollNumber,
        'onboarded_at': onboardedAt,
      };

  String toJsonString() => jsonEncode(toJson());

  static User? fromJsonString(String? s) {
    if (s == null) return null;
    try {
      return User.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

class AuthException implements Exception {
  final String code;
  final String message;
  final String? reason;
  final String? actualRole;

  const AuthException({
    required this.code,
    required this.message,
    this.reason,
    this.actualRole,
  });

  @override
  String toString() => 'AuthException($code): $message';
}

class LoginRequest {
  final String email;
  final String password;
  final String role;

  const LoginRequest({
    required this.email,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'role': role,
      };
}
