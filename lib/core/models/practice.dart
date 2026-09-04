class PracticeQuestion {
  PracticeQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    required this.answer,
  });

  final String id;
  final String question;
  final String type; // mcq | short | truefalse
  final List<String>? options;
  final String answer;

  factory PracticeQuestion.fromJson(Map<String, dynamic> j) => PracticeQuestion(
        id: j['id'] as String,
        question: j['question'] as String,
        type: j['type'] as String,
        options: (j['options'] as List?)?.map((e) => e as String).toList(),
        answer: j['answer'] as String,
      );
}
