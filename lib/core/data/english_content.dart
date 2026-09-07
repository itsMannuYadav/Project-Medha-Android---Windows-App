/// Learn English — curated lessons, vocabulary, speaking prompts (ported from
/// `shiksha_sathi/lib/english-content.ts`).

class EnglishLesson {
  const EnglishLesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.topics,
    required this.starterPrompt,
  });
  final String id;
  final String title;
  final String subtitle;
  final List<String> topics;
  final String starterPrompt;
}

class VocabWord {
  const VocabWord({
    required this.word,
    required this.meaning,
    required this.hindi,
    required this.example,
    required this.phonetic,
  });
  final String word;
  final String meaning;
  final String hindi;
  final String example;
  final String phonetic;
}

class VocabSet {
  const VocabSet({required this.id, required this.label, required this.words});
  final String id;
  final String label;
  final List<VocabWord> words;
}

class DailyWord {
  const DailyWord({
    required this.word,
    required this.meaning,
    required this.hindi,
    required this.example,
    required this.tip,
  });
  final String word;
  final String meaning;
  final String hindi;
  final String example;
  final String tip;
}

const englishLessons = <EnglishLesson>[
  EnglishLesson(
    id: 'greetings',
    title: 'Greetings & Introductions',
    subtitle: 'Say hello, introduce yourself, ask how someone is',
    topics: ['Hello / Hi', 'My name is…', 'How are you?', 'Nice to meet you'],
    starterPrompt: 'Teach me how to greet someone and introduce myself in English.',
  ),
  EnglishLesson(
    id: 'school',
    title: 'At School',
    subtitle: 'Classroom words, asking the teacher, talking to friends',
    topics: ["Teacher, please…", "I don't understand", 'Can you repeat?', 'Homework'],
    starterPrompt: 'Teach me useful English phrases for school and the classroom.',
  ),
  EnglishLesson(
    id: 'family',
    title: 'Family & Home',
    subtitle: 'Talk about your family, home, and daily routine',
    topics: ['Mother, father, brother, sister', 'I live in…', 'Every day I…', 'We eat together'],
    starterPrompt: 'Help me learn English words and sentences to describe my family and home.',
  ),
  EnglishLesson(
    id: 'market',
    title: 'At the Market',
    subtitle: 'Buy things, ask prices, count money',
    topics: ['How much?', 'I want…', 'Too expensive', 'Thank you'],
    starterPrompt: 'Teach me English for shopping at the market — asking prices and buying things.',
  ),
  EnglishLesson(
    id: 'tenses',
    title: 'Simple Tenses',
    subtitle: 'Present, past, and future — the building blocks',
    topics: ['I eat / I ate / I will eat', 'He goes / He went', 'Questions with do/did'],
    starterPrompt: 'Explain simple present, past, and future tense with easy examples.',
  ),
  EnglishLesson(
    id: 'conversation',
    title: 'Daily Conversation',
    subtitle: 'Small talk, weather, hobbies, festivals',
    topics: ["What's your hobby?", 'The weather is…', 'Happy Diwali!', 'See you tomorrow'],
    starterPrompt: "Let's practice a simple English conversation about hobbies and festivals.",
  ),
];

const vocabSets = <VocabSet>[
  VocabSet(
    id: 'basics',
    label: 'Everyday Words',
    words: [
      VocabWord(word: 'Book', meaning: 'Something you read', hindi: 'किताब', example: 'I read my book.', phonetic: 'book'),
      VocabWord(word: 'Water', meaning: 'What we drink', hindi: 'पानी', example: 'Can I have some water?', phonetic: 'WAW-ter'),
      VocabWord(word: 'Friend', meaning: 'Someone you like', hindi: 'दोस्त', example: 'She is my best friend.', phonetic: 'frend'),
      VocabWord(word: 'Happy', meaning: 'Feeling good', hindi: 'खुश', example: 'I am happy today.', phonetic: 'HAP-ee'),
      VocabWord(word: 'Learn', meaning: 'To gain knowledge', hindi: 'सीखना', example: 'I want to learn English.', phonetic: 'lurn'),
      VocabWord(word: 'Help', meaning: 'To assist someone', hindi: 'मदद', example: 'Can you help me?', phonetic: 'help'),
    ],
  ),
  VocabSet(
    id: 'school',
    label: 'School Words',
    words: [
      VocabWord(word: 'Teacher', meaning: 'Person who teaches', hindi: 'शिक्षक', example: 'My teacher is kind.', phonetic: 'TEE-cher'),
      VocabWord(word: 'Homework', meaning: 'Work to do at home', hindi: 'गृहकार्य', example: 'I finished my homework.', phonetic: 'HOME-wurk'),
      VocabWord(word: 'Exam', meaning: 'A test', hindi: 'परीक्षा', example: 'The exam is next week.', phonetic: 'ig-ZAM'),
      VocabWord(word: 'Answer', meaning: 'A reply to a question', hindi: 'उत्तर', example: 'What is the answer?', phonetic: 'AN-ser'),
      VocabWord(word: 'Question', meaning: 'Something you ask', hindi: 'प्रश्न', example: 'I have a question.', phonetic: 'KWES-chun'),
      VocabWord(word: 'Class', meaning: 'A group of students', hindi: 'कक्षा', example: 'Our class starts at 9.', phonetic: 'klas'),
    ],
  ),
  VocabSet(
    id: 'verbs',
    label: 'Common Verbs',
    words: [
      VocabWord(word: 'Go', meaning: 'To move from one place', hindi: 'जाना', example: 'I go to school.', phonetic: 'goh'),
      VocabWord(word: 'Eat', meaning: 'To have food', hindi: 'खाना', example: 'We eat lunch at 1 pm.', phonetic: 'eet'),
      VocabWord(word: 'Read', meaning: 'To look at and understand words', hindi: 'पढ़ना', example: 'I read every day.', phonetic: 'reed'),
      VocabWord(word: 'Write', meaning: 'To make words on paper', hindi: 'लिखना', example: 'Please write your name.', phonetic: 'ryt'),
      VocabWord(word: 'Speak', meaning: 'To say words', hindi: 'बोलना', example: 'Speak slowly, please.', phonetic: 'speek'),
      VocabWord(word: 'Listen', meaning: 'To hear carefully', hindi: 'सुनना', example: 'Listen to the teacher.', phonetic: 'LIS-un'),
    ],
  ),
];

const speakingPrompts = <String>[
  'Hello, my name is ___. Nice to meet you.',
  'I am a student at ___ school.',
  'My favourite subject is ___.',
  'Every morning I wake up at ___ o\'clock.',
  'I want to learn English because ___.',
  'Can you please help me with this?',
  'Thank you very much for your help.',
];

DailyWord dailyWord([DateTime? date]) {
  const pool = <DailyWord>[
    DailyWord(word: 'Curious', meaning: 'Wanting to know or learn', hindi: 'जिज्ञासु', example: 'Be curious — ask questions!', tip: 'Say: KYOOR-ee-us'),
    DailyWord(word: 'Practice', meaning: 'Doing something again to improve', hindi: 'अभ्यास', example: 'Practice makes perfect.', tip: 'Say: PRAK-tis'),
    DailyWord(word: 'Together', meaning: 'With each other', hindi: 'साथ में', example: "Let's study together.", tip: 'Say: tuh-GETH-er'),
    DailyWord(word: 'Improve', meaning: 'To get better', hindi: 'सुधारना', example: 'I improve every day.', tip: 'Say: im-PROOV'),
    DailyWord(word: 'Confidence', meaning: 'Believing in yourself', hindi: 'आत्मविश्वास', example: 'Speak with confidence.', tip: 'Say: KON-fi-dens'),
    DailyWord(word: 'Patient', meaning: 'Waiting calmly', hindi: 'धैर्यवान', example: 'Be patient while learning.', tip: 'Say: PAY-shent'),
    DailyWord(word: 'Celebrate', meaning: 'To enjoy a special day', hindi: 'जश्न मनाना', example: 'We celebrate Holi.', tip: 'Say: SEL-uh-brayt'),
  ];
  final d = date ?? DateTime.now();
  final day = d.millisecondsSinceEpoch ~/ 86400000;
  return pool[day % pool.length];
}
