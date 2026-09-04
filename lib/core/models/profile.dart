class ProfileSchool {
  ProfileSchool({required this.id, required this.name, required this.districtName});
  final String id;
  final String name;
  final String districtName;

  factory ProfileSchool.fromJson(Map<String, dynamic> j) =>
      ProfileSchool(id: j['id'] as String, name: j['name'] as String, districtName: j['district_name'] as String);
}

class ProfileSubject {
  ProfileSubject({
    required this.subjectId,
    required this.subjectName,
    required this.gradeId,
    required this.gradeLabel,
    required this.numericLevel,
    required this.isPrimary,
  });
  final String subjectId;
  final String subjectName;
  final String gradeId;
  final String gradeLabel;
  final int numericLevel;
  final bool isPrimary;

  factory ProfileSubject.fromJson(Map<String, dynamic> j) => ProfileSubject(
        subjectId: j['subject_id'] as String,
        subjectName: j['subject_name'] as String,
        gradeId: j['grade_id'] as String,
        gradeLabel: j['grade_label'] as String,
        numericLevel: j['numeric_level'] as int,
        isPrimary: j['is_primary'] as bool,
      );
}

class Profile {
  Profile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.preferredLanguage,
    required this.onboardedAt,
    required this.school,
    required this.subjects,
  });
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String preferredLanguage;
  final DateTime? onboardedAt;
  final ProfileSchool? school;
  final List<ProfileSubject> subjects;

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        fullName: j['full_name'] as String,
        email: j['email'] as String,
        phoneNumber: j['phone_number'] as String?,
        preferredLanguage: j['preferred_language'] as String,
        onboardedAt: j['onboarded_at'] == null ? null : DateTime.parse(j['onboarded_at'] as String),
        school: j['school'] == null ? null : ProfileSchool.fromJson(j['school'] as Map<String, dynamic>),
        subjects: (j['subjects'] as List)
            .map((s) => ProfileSubject.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}
