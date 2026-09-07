class ChapterNote {
  ChapterNote({
    required this.id,
    required this.chapterId,
    required this.summary,
    required this.keyPoints,
    required this.importantTerms,
  });

  final String id;
  final String chapterId;
  final String summary;
  final List<String> keyPoints;
  final List<String> importantTerms;

  factory ChapterNote.fromJson(Map<String, dynamic> j) => ChapterNote(
        id: j['id'] as String? ?? '',
        chapterId: j['chapter_id'] as String? ?? '',
        summary: j['summary'] as String,
        keyPoints: (j['key_points'] as List? ?? []).map((e) => e as String).toList(),
        importantTerms: (j['important_terms'] as List? ?? []).map((e) => e as String).toList(),
      );
}
