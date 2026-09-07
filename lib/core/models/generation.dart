/// Content-generation domain (Medha v2) — mirrors web `generation-types.ts`
/// and backend `/generate/{type}` + `/generations/*`.
library;

const kGenerationTypes = ['lesson_plan', 'presentation', 'question_paper', 'notes', 'quiz'];

String generationTypeLabel(String type) => switch (type) {
      'lesson_plan' => 'पाठ योजना',
      'presentation' => 'प्रस्तुति',
      'question_paper' => 'प्रश्न-पत्र',
      'notes' => 'नोट्स',
      'quiz' => 'क्विज़',
      _ => type,
    };

Map<String, dynamic> defaultParamsFor(String type) => switch (type) {
      'quiz' => {
          'question_count': 10,
          'difficulty': 'medium',
          'time_limit_min': 20,
          'focus': '',
          'types': ['mcq'],
        },
      'notes' => {'depth': 'standard', 'include_key_terms': true},
      'lesson_plan' => {'periods': 3, 'focus': ''},
      'question_paper' => {
          'difficulty': 'mixed',
          'focus': '',
          'mcq_count': 5,
          'mcq_marks': 1,
          'very_short_count': 0,
          'very_short_marks': 2,
          'short_count': 3,
          'short_marks': 3,
          'long_count': 2,
          'long_marks': 5,
          'case_study_count': 0,
          'case_study_marks': 4,
        },
      'presentation' => {'slide_count': 8, 'detail': 'simple', 'include_notes': true},
      _ => <String, dynamic>{},
    };

class GenerationListItem {
  GenerationListItem({
    required this.id,
    required this.type,
    required this.title,
    required this.status,
    required this.source,
    required this.isFavorite,
    required this.gradeLabel,
    required this.subjectName,
    required this.chapterTitle,
    required this.createdAt,
    required this.legacy,
    required this.moduleId,
  });

  final String id;
  final String type;
  final String title;
  final String status;
  final String source;
  final bool isFavorite;
  final String? gradeLabel;
  final String? subjectName;
  final String? chapterTitle;
  final DateTime createdAt;
  final bool legacy;
  final String? moduleId;

  factory GenerationListItem.fromJson(Map<String, dynamic> j) => GenerationListItem(
        id: j['id'] as String,
        type: j['type'] as String,
        title: j['title'] as String,
        status: j['status'] as String,
        source: j['source'] as String? ?? '',
        isFavorite: j['is_favorite'] as bool? ?? false,
        gradeLabel: j['grade_label'] as String?,
        subjectName: j['subject_name'] as String?,
        chapterTitle: j['chapter_title'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        legacy: j['legacy'] as bool? ?? false,
        moduleId: j['module_id'] as String?,
      );
}

class GenerationDetail {
  GenerationDetail({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.language,
    required this.status,
    required this.source,
    required this.isFavorite,
    required this.gradeId,
    required this.subjectId,
    required this.chapterId,
    required this.topicId,
    required this.gradeLabel,
    required this.subjectName,
    required this.chapterTitle,
    required this.inputParams,
    required this.contentJson,
    required this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final String title;
  final String? description;
  final String language;
  final String status;
  final String source;
  final bool isFavorite;
  final String? gradeId;
  final String? subjectId;
  final String? chapterId;
  final String? topicId;
  final String? gradeLabel;
  final String? subjectName;
  final String? chapterTitle;
  final Map<String, dynamic>? inputParams;
  final Map<String, dynamic>? contentJson;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory GenerationDetail.fromJson(Map<String, dynamic> j) => GenerationDetail(
        id: j['id'] as String,
        type: j['type'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        language: j['language'] as String? ?? 'hi',
        status: j['status'] as String,
        source: j['source'] as String? ?? '',
        isFavorite: j['is_favorite'] as bool? ?? false,
        gradeId: j['grade_id'] as String?,
        subjectId: j['subject_id'] as String?,
        chapterId: j['chapter_id'] as String?,
        topicId: j['topic_id'] as String?,
        gradeLabel: j['grade_label'] as String?,
        subjectName: j['subject_name'] as String?,
        chapterTitle: j['chapter_title'] as String?,
        inputParams: j['input_params'] as Map<String, dynamic>?,
        contentJson: j['content_json'] as Map<String, dynamic>?,
        errorMessage: j['error_message'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );
}
