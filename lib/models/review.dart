/// A short recap card shown at the top of the Review mode.
class SummaryCard {
  const SummaryCard({required this.title, required this.body});

  final String title;
  final String body;
}

/// A term the learner should be able to define from memory.
class KeyConcept {
  const KeyConcept({required this.term, required this.definition});

  final String term;
  final String definition;
}

/// A common error paired with what to do instead.
class Mistake {
  const Mistake({required this.mistake, required this.correction});

  final String mistake;
  final String correction;
}

/// An interview-style question with a model answer.
class InterviewQuestion {
  const InterviewQuestion({required this.question, required this.answer});

  final String question;
  final String answer;
}

/// The "Review" payload of a lesson.
class ReviewContent {
  const ReviewContent({
    required this.summaryCards,
    required this.keyConcepts,
    required this.mistakes,
    required this.interviewQuestions,
  });

  final List<SummaryCard> summaryCards;
  final List<KeyConcept> keyConcepts;
  final List<Mistake> mistakes;
  final List<InterviewQuestion> interviewQuestions;

  /// True when every one of the four lists is empty, i.e. Review mode would
  /// render nothing for this lesson.
  bool get isEmpty =>
      summaryCards.isEmpty &&
      keyConcepts.isEmpty &&
      mistakes.isEmpty &&
      interviewQuestions.isEmpty;

  bool get isNotEmpty => !isEmpty;
}
