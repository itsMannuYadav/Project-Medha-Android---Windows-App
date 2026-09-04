class LibraryItem {
  LibraryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.gradeLabel,
    required this.subjectName,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final String url;
  final String? gradeLabel;
  final String? subjectName;
  final DateTime createdAt;

  factory LibraryItem.fromJson(Map<String, dynamic> j) => LibraryItem(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        url: j['url'] as String,
        gradeLabel: j['grade_label'] as String?,
        subjectName: j['subject_name'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
