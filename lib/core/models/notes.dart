class ChapterNote {
  ChapterNote({required this.summary, required this.keyPoints, required this.importantTerms});

  final String summary;
  final List<String> keyPoints;
  final List<String> importantTerms;

  factory ChapterNote.fromJson(Map<String, dynamic> j) => ChapterNote(
        summary: j['summary'] as String,
        keyPoints: (j['key_points'] as List).map((e) => e as String).toList(),
        importantTerms: (j['important_terms'] as List).map((e) => e as String).toList(),
      );
}
