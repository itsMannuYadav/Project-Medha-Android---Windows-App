class GradeRef {
  GradeRef({required this.id, required this.label, required this.numericLevel});
  final String id;
  final String label;
  final int numericLevel;

  factory GradeRef.fromJson(Map<String, dynamic> j) =>
      GradeRef(id: j['id'] as String, label: j['label'] as String, numericLevel: j['numeric_level'] as int);
}

class SubjectRef {
  SubjectRef({required this.id, required this.name, required this.board});
  final String id;
  final String name;
  final String board;

  factory SubjectRef.fromJson(Map<String, dynamic> j) =>
      SubjectRef(id: j['id'] as String, name: j['name'] as String, board: j['board'] as String);
}

class SchoolSearchResult {
  SchoolSearchResult({required this.id, required this.name, required this.districtName});
  final String id;
  final String name;
  final String districtName;

  factory SchoolSearchResult.fromJson(Map<String, dynamic> j) => SchoolSearchResult(
        id: j['id'] as String,
        name: j['name'] as String,
        districtName: j['district_name'] as String,
      );
}

class ChapterRef {
  ChapterRef({required this.id, required this.chapterNumber, required this.title});
  final String id;
  final int chapterNumber;
  final String title;

  factory ChapterRef.fromJson(Map<String, dynamic> j) => ChapterRef(
        id: j['id'] as String,
        chapterNumber: j['chapter_number'] as int,
        title: j['title'] as String,
      );
}

class TopicRef {
  TopicRef({required this.id, required this.title});
  final String id;
  final String title;

  factory TopicRef.fromJson(Map<String, dynamic> j) => TopicRef(id: j['id'] as String, title: j['title'] as String);
}
