class ModuleListItem {
  ModuleListItem({
    required this.id,
    required this.title,
    required this.gradeLabel,
    required this.subjectName,
    required this.artifactTypes,
    required this.updatedAt,
  });
  final String id;
  final String title;
  final String gradeLabel;
  final String subjectName;
  final List<String> artifactTypes; // "explanation" | "quiz" | "activity"
  final DateTime updatedAt;

  factory ModuleListItem.fromJson(Map<String, dynamic> j) => ModuleListItem(
        id: j['id'] as String,
        title: j['title'] as String,
        gradeLabel: j['grade_label'] as String,
        subjectName: j['subject_name'] as String,
        artifactTypes: (j['artifact_types'] as List).cast<String>(),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );
}

class ModuleArtifact {
  ModuleArtifact({required this.id, required this.artifactType, required this.contentJson, required this.createdAt});
  final String id;
  final String artifactType;
  final Map<String, dynamic>? contentJson;
  final DateTime createdAt;

  factory ModuleArtifact.fromJson(Map<String, dynamic> j) => ModuleArtifact(
        id: j['id'] as String,
        artifactType: j['artifact_type'] as String,
        contentJson: j['content_json'] as Map<String, dynamic>?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class ModuleFeedback {
  ModuleFeedback({required this.rating, required this.comment});
  final int? rating; // 1 | -1
  final String? comment;

  factory ModuleFeedback.fromJson(Map<String, dynamic> j) =>
      ModuleFeedback(rating: j['rating'] as int?, comment: j['comment'] as String?);
}

class ModuleDetail {
  ModuleDetail({
    required this.id,
    required this.title,
    required this.gradeLabel,
    required this.subjectName,
    required this.topicTitle,
    required this.artifacts,
    required this.feedback,
  });
  final String id;
  final String title;
  final String gradeLabel;
  final String subjectName;
  final String? topicTitle;
  final List<ModuleArtifact> artifacts;
  final ModuleFeedback? feedback;

  factory ModuleDetail.fromJson(Map<String, dynamic> j) => ModuleDetail(
        id: j['id'] as String,
        title: j['title'] as String,
        gradeLabel: j['grade_label'] as String,
        subjectName: j['subject_name'] as String,
        topicTitle: j['topic_title'] as String?,
        artifacts: (j['artifacts'] as List).map((a) => ModuleArtifact.fromJson(a as Map<String, dynamic>)).toList(),
        feedback: j['feedback'] == null ? null : ModuleFeedback.fromJson(j['feedback'] as Map<String, dynamic>),
      );
}
