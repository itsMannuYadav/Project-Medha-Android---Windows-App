class LibraryPresentationItem {
  LibraryPresentationItem({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.language,
    required this.gradeLabel,
    required this.subjectName,
    required this.chapterTitle,
    required this.slideCount,
    required this.updatedAt,
  });

  final String id;
  final String slug;
  final String title;
  final String? description;
  final String language;
  final String? gradeLabel;
  final String? subjectName;
  final String? chapterTitle;
  final int? slideCount;
  final DateTime updatedAt;

  factory LibraryPresentationItem.fromJson(Map<String, dynamic> j) => LibraryPresentationItem(
        id: j['id'] as String,
        slug: j['slug'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        language: j['language'] as String? ?? 'hi',
        gradeLabel: j['grade_label'] as String?,
        subjectName: j['subject_name'] as String?,
        chapterTitle: j['chapter_title'] as String?,
        slideCount: j['slide_count'] as int?,
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );
}

class LibraryPresentationDetail extends LibraryPresentationItem {
  LibraryPresentationDetail({
    required super.id,
    required super.slug,
    required super.title,
    required super.description,
    required super.language,
    required super.gradeLabel,
    required super.subjectName,
    required super.chapterTitle,
    required super.slideCount,
    required super.updatedAt,
    required this.tags,
    required this.spec,
  });

  final List<String>? tags;
  final Map<String, dynamic>? spec;

  factory LibraryPresentationDetail.fromJson(Map<String, dynamic> j) => LibraryPresentationDetail(
        id: j['id'] as String,
        slug: j['slug'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        language: j['language'] as String? ?? 'hi',
        gradeLabel: j['grade_label'] as String?,
        subjectName: j['subject_name'] as String?,
        chapterTitle: j['chapter_title'] as String?,
        slideCount: j['slide_count'] as int?,
        updatedAt: DateTime.parse(j['updated_at'] as String),
        tags: (j['tags'] as List?)?.map((t) => t as String).toList(),
        spec: j['spec'] as Map<String, dynamic>?,
      );
}
