enum QuestionType { mcq, scale, fillIn, multiSelect }

class SurveyQuestion {
  final String id;
  final String category;
  final String question;
  final QuestionType type;
  final List<String>? options;
  final int? minScale;
  final int? maxScale;
  final String? placeholder;

  const SurveyQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.type,
    this.options,
    this.minScale,
    this.maxScale,
    this.placeholder,
  });
}

final List<SurveyQuestion> onboardingQuestions = [
  // Section 1: Clinical Triage
  const SurveyQuestion(
    id: 'depression_freq',
    category: 'Clinical Triage',
    question: 'Over the last two weeks, how often have you been bothered by feeling down, depressed, or hopeless?',
    type: QuestionType.mcq,
    options: ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
  ),
  const SurveyQuestion(
    id: 'stress_level',
    category: 'Clinical Triage',
    question: 'On a scale of 1 to 10, how would you rate your average stress level over the past 48 hours?',
    type: QuestionType.scale,
    minScale: 1,
    maxScale: 10,
  ),
  const SurveyQuestion(
    id: 'mood_word',
    category: 'Clinical Triage',
    question: 'The one word that best describes my mood today is...',
    type: QuestionType.fillIn,
    placeholder: 'e.g., Grateful, Tired, Calm',
  ),
  const SurveyQuestion(
    id: 'sleep_quality',
    category: 'Clinical Triage',
    question: 'How is your sleep quality lately?',
    type: QuestionType.mcq,
    options: [
      'I sleep like a baby',
      'I have trouble falling asleep',
      'I wake up frequently during the night',
      'I sleep too much / can\'t get out of bed'
    ],
  ),

  // Section 2: Personalization & Matching
  const SurveyQuestion(
    id: 'focus_areas',
    category: 'Personalization',
    question: 'What are the primary areas you’d like to focus on? (Select all that apply)',
    type: QuestionType.multiSelect,
    options: [
      'Career/Academic Stress',
      'Relationships & Family',
      'Self-Esteem & Confidence',
      'Loneliness',
      'Health & Body Image'
    ],
  ),
  const SurveyQuestion(
    id: 'support_type',
    category: 'Personalization',
    question: 'When you’re feeling overwhelmed, what kind of support do you prefer?',
    type: QuestionType.mcq,
    options: [
      'Practical advice and "action steps"',
      'Someone to just listen and validate my feelings',
      'Guided exercises (meditation, breathing)',
      'Scientific explanations of what I\'m feeling'
    ],
  ),
  const SurveyQuestion(
    id: 'support_phrase',
    category: 'Personalization',
    question: 'I feel most supported when people tell me...',
    type: QuestionType.fillIn,
    placeholder: 'e.g., "I\'m here for you"',
  ),
  const SurveyQuestion(
    id: 'comm_style',
    category: 'Personalization',
    question: 'What is your preferred communication style for this app?',
    type: QuestionType.mcq,
    options: [
      'Short, frequent check-ins',
      'Deep, long-form conversations',
      'Visual aids and mood tracking',
      'Minimal interaction; only when I reach out'
    ],
  ),

  // Section 3: Lifestyle & Environment
  const SurveyQuestion(
    id: 'environment',
    category: 'Lifestyle',
    question: 'Which of these best describes your daily environment?',
    type: QuestionType.mcq,
    options: [
      'High-pressure (Office/University)',
      'Isolated (Remote work/Stay-at-home)',
      'Physically demanding',
      'Balanced/Relaxed'
    ],
  ),
  const SurveyQuestion(
    id: 'work_life_balance',
    category: 'Lifestyle',
    question: 'How satisfied are you with your current work-life or study-life balance?',
    type: QuestionType.scale,
    minScale: 1,
    maxScale: 5,
  ),
  const SurveyQuestion(
    id: 'decompress_way',
    category: 'Lifestyle',
    question: 'My favorite way to decompress after a long day is...',
    type: QuestionType.fillIn,
    placeholder: 'e.g., Reading, Exercise, Music',
  ),

  // Section 4: App Engagement & Goals
  const SurveyQuestion(
    id: 'north_star',
    category: 'App Goals',
    question: 'What is your "North Star" goal for using this app?',
    type: QuestionType.mcq,
    options: [
      'To build a consistent daily habit',
      'To navigate a specific crisis or event',
      'To understand my emotions better through data',
      'To find a community of like-minded people'
    ],
  ),
  const SurveyQuestion(
    id: 'anxious_time',
    category: 'App Goals',
    question: 'At what time of day do you usually feel the most "in your head" or anxious?',
    type: QuestionType.mcq,
    options: [
      'Morning (Right after waking up)',
      'During the busy afternoon',
      'Late at night',
      'It\'s random'
    ],
  ),
  const SurveyQuestion(
    id: 'routine_change',
    category: 'App Goals',
    question: 'If I could change one thing about my daily routine, it would be...',
    type: QuestionType.fillIn,
    placeholder: 'e.g., Waking up earlier',
  ),
  const SurveyQuestion(
    id: 'reminder_tone',
    category: 'App Goals',
    question: 'How would you like the AI/App to remind you to check in?',
    type: QuestionType.mcq,
    options: [
      'Gentle and encouraging',
      'Direct and disciplined',
      'Playful and humorous',
      'No notifications; I\'ll come to you'
    ],
  ),
];
