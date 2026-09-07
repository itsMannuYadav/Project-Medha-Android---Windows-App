/// Static library book catalog — ported from web `student-content.ts`.

class LibraryBook {
  const LibraryBook({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.subject,
    required this.classLabel,
    required this.pages,
    required this.blurb,
  });
  final String id;
  final String title;
  final String author;
  final String category;
  final String subject;
  final String classLabel;
  final int pages;
  final String blurb;
}

const libraryBooks = <LibraryBook>[
  LibraryBook(
    id: 'sci-8-bseb',
    title: 'Science, Class 8',
    author: 'Bihar State Textbook Corporation',
    category: 'Textbook',
    subject: 'Science',
    classLabel: 'Class 8',
    pages: 214,
    blurb: 'The prescribed BSEB science textbook — crop production, microorganisms, friction, force and pressure, sound, light and more.',
  ),
  LibraryBook(
    id: 'math-8-bseb',
    title: 'Ganit (Mathematics), Class 8',
    author: 'Bihar State Textbook Corporation',
    category: 'Textbook',
    subject: 'Mathematics',
    classLabel: 'Class 8',
    pages: 268,
    blurb: 'Rational numbers, linear equations, quadrilaterals, mensuration and data handling with solved examples.',
  ),
  LibraryBook(
    id: 'sst-8-bseb',
    title: 'Samajik Vigyan (Social Science), Class 8',
    author: 'Bihar State Textbook Corporation',
    category: 'Textbook',
    subject: 'Social Science',
    classLabel: 'Class 8',
    pages: 240,
    blurb: 'History, geography and civics as prescribed for Class 8 in Bihar.',
  ),
  LibraryBook(
    id: 'hindi-8',
    title: 'Hindi Vyakaran & Sahitya',
    author: 'BSEB',
    category: 'Textbook',
    subject: 'Hindi',
    classLabel: 'Class 8',
    pages: 180,
    blurb: 'Grammar drills and selected prose/poetry for middle school Hindi.',
  ),
  LibraryBook(
    id: 'stories-panchatantra',
    title: 'Panchatantra Stories (Easy English)',
    author: 'Retold for schools',
    category: 'Stories',
    subject: 'English',
    classLabel: 'Class 6–8',
    pages: 96,
    blurb: 'Short moral stories for reading practice and classroom storytelling.',
  ),
  LibraryBook(
    id: 'comp-ntse',
    title: 'NTSE Foundation Primer',
    author: 'Medha Curated',
    category: 'Competitive',
    subject: 'General',
    classLabel: 'Class 8–10',
    pages: 120,
    blurb: 'Practice sets for aptitude and scholastic ability.',
  ),
];
