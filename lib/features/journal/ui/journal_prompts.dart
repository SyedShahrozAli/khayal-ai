class JournalPrompt {
  final String id;
  final String category;
  final String titleEn;
  final String titleUr;
  final String templateEn;
  final String templateUr;
  final String tag;

  const JournalPrompt({
    required this.id,
    required this.category,
    required this.titleEn,
    required this.titleUr,
    required this.templateEn,
    required this.templateUr,
    required this.tag,
  });
}

class JournalPrompts {
  JournalPrompts._();

  static const List<JournalPrompt> prompts = [
    JournalPrompt(
      id: 'gratitude_1',
      category: 'Gratitude',
      titleEn: 'Small Joy',
      titleUr: 'چھوٹی خوشی',
      templateEn: 'What is one small thing that brought a smile or relief to your day?',
      templateUr: 'آج کس چھوٹی سی بات نے آپ کے چہرے پر مسکراہٹ یا دل کو سکون دیا؟',
      tag: 'gratitude',
    ),
    JournalPrompt(
      id: 'cbt_1',
      category: 'CBT Reframing',
      titleEn: 'Thought Reframe',
      titleUr: 'خیال کی درستگی',
      templateEn: 'What negative thought bothered you today? What is a kinder, more balanced way to view it?',
      templateUr: 'آج کس منفی خیال نے آپ کو پریشان کیا؟ اس کا حقیقت پسندانہ اور ہمدردانہ متبادل کیا ہے؟',
      tag: 'cbt',
    ),
    JournalPrompt(
      id: 'decompression_1',
      category: 'Decompression',
      titleEn: 'Heavy Weight',
      titleUr: 'دل کا بوجھ',
      templateEn: 'What felt overwhelming today? Write down all the things on your mind and let them rest here.',
      templateUr: 'آج کیا بات بہت بوجھل لگی؟ جو کچھ دل پر ہے بلا جھجھک لکھ کر بوجھ ہلکا کریں۔',
      tag: 'release',
    ),
    JournalPrompt(
      id: 'daily_win_1',
      category: 'Daily Wins',
      titleEn: 'Personal Win',
      titleUr: 'آج کی کامیابی',
      templateEn: 'What is one challenge, however tiny, that you showed up for and handled today?',
      templateUr: 'آج کا کوئی ایسا کام یا چیلنج جسے آپ نے نبھایا اور خود پر فخر محسوس ہوا؟',
      tag: 'win',
    ),
    JournalPrompt(
      id: 'mindfulness_1',
      category: 'Mindfulness',
      titleEn: 'Present Moment',
      titleUr: 'حال کا احساس',
      templateEn: 'Take a slow breath. How does your body feel right now, and what do you need most in this moment?',
      templateUr: 'ایک گہرا سانس لیں۔ اس وقت آپ کا جسم کیا محسوس کر رہا ہے اور آپ کو کس چیز کی سب سے زیادہ ضرورت ہے؟',
      tag: 'calm',
    ),
  ];
}
