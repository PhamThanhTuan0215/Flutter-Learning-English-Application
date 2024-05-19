import 'package:application_learning_english/models/word.dart';

class Question {
  final String questionText;
  final List<Answer> answersList;
  int? selectedAnswerIndex; // Chỉ số của câu trả lời được chọn

  Question(this.questionText, this.answersList);
}

class Answer {
  final String answerText;
  final bool isCorrect;

  Answer(this.answerText, this.isCorrect);
}

List<Question> getQuestions(
    List<Word> words, bool isShuffle, bool englishToVietnamese) {
  List<Map<String, String>> wordPairs = words.map((word) {
    return {
      'english': englishToVietnamese ? word.english : word.vietnamese,
      'vietnamese': englishToVietnamese ? word.vietnamese : word.english,
    };
  }).toList();

  if (isShuffle) wordPairs.shuffle();

  List<Question> list = [];

  for (var wordPair in wordPairs) {
    String correctAnswer = wordPair['vietnamese']!;

    // Get unique incorrect answers
    Set<String> incorrectTranslations =
        Set.from(wordPairs.map((wp) => wp['vietnamese']!))
          ..remove(correctAnswer);
    List<String> incorrectAnswers = incorrectTranslations.toList();

    // Duplicate incorrect answers if there are not enough unique ones
    while (incorrectAnswers.length < 3) {
      incorrectAnswers.addAll(incorrectTranslations);
    }

    // Shuffle the incorrect answers
    incorrectAnswers.shuffle();

    List<Answer> answers = [
      Answer(correctAnswer, true),
      Answer(incorrectAnswers[0], false),
      Answer(incorrectAnswers[1], false),
      Answer(incorrectAnswers[2], false),
    ];

    answers.shuffle();

    list.add(Question(wordPair['english']!, answers));
  }

  return list;
}
