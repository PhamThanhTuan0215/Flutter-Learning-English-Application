import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:application_learning_english/models/word.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:application_learning_english/config.dart';

class Question {
  final String questionText;
  final String correctAnswer;
  String? userAnswer; // The answer inputted by the user
  final Word word; // Thêm biến word để lưu thông tin từ

  Question(this.questionText, this.correctAnswer, this.word);
}

List<Question> getQuestions(List<Word> words, bool isShuffle,
    bool englishToVietnamese, bool isStarCard) {
  if (isStarCard) {
    List<Map<String, dynamic>> wordPairs = words
        .where((word) => word.isStarred) // Lọc các từ có isStarred = true
        .map((word) {
      return {
        'english': englishToVietnamese ? word.english : word.vietnamese,
        'vietnamese': englishToVietnamese ? word.vietnamese : word.english,
        'word': word, // Thêm biến word vào map
      };
    }).toList();

    if (isShuffle) wordPairs.shuffle();

    return wordPairs.map((wordPair) {
      return Question(
          wordPair['english']!, wordPair['vietnamese']!, wordPair['word']);
    }).toList();
  } else {
    List<Map<String, dynamic>> wordPairs = words.map((word) {
      return {
        'english': englishToVietnamese ? word.english : word.vietnamese,
        'vietnamese': englishToVietnamese ? word.vietnamese : word.english,
        'word': word, // Thêm biến word vào map
      };
    }).toList();

    if (isShuffle) wordPairs.shuffle();

    return wordPairs.map((wordPair) {
      return Question(
          wordPair['english']!, wordPair['vietnamese']!, wordPair['word']);
    }).toList();
  }
}

class TypingScreen extends StatefulWidget {
  final List<Word> words;
  final bool isShuffle;
  final bool isEnglish;
  final bool autoPronounce;
  final bool starCard;

  const TypingScreen({
    Key? key,
    required this.words,
    required this.isShuffle,
    required this.autoPronounce,
    required this.isEnglish,
    required this.starCard,
  }) : super(key: key);

  @override
  State<TypingScreen> createState() => _TypingScreenState();
}

class _TypingScreenState extends State<TypingScreen> {
  final urlRoot = kIsWeb ? WEB_URL : ANDROID_URL;

  late List<Question> questionList;
  late FlutterTts flutterTts;
  List<Word> correctWords = [];

  TextEditingController answerController = TextEditingController();
  int currentQuestionIndex = 0;
  int score = 0;
  late Timer timer;
  int duration = 0; // Time in seconds

  @override
  void initState() {
    super.initState();
    questionList = getQuestions(
        widget.words, widget.isShuffle, widget.isEnglish, widget.starCard);
    flutterTts = FlutterTts();

    if (widget.autoPronounce) {
      _speak(questionList[currentQuestionIndex].questionText);
    }

    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      if (mounted) {
        setState(() {
          duration++;
        });
      }
    });
  }

  void stopTimer() {
    timer.cancel();
  }

  String getFormattedTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                getFormattedTime(duration),
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildHeader(),
            _buildQuestionWidget(),
            _buildAnswerInput(),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      "Typing Quiz App",
      style: TextStyle(
        color: Colors.black,
        fontSize: 24,
      ),
    );
  }

  void _previousQuestion() {
    setState(() {
      if (currentQuestionIndex > 0) {
        currentQuestionIndex--;
        answerController.text =
            questionList[currentQuestionIndex].userAnswer ?? '';
        if (widget.autoPronounce) {
          _speak(questionList[currentQuestionIndex].questionText);
        }
      }
    });
  }

  Widget _buildQuestionWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Question ${currentQuestionIndex + 1}/${questionList.length}",
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          alignment: Alignment.center,
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.orangeAccent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  questionList[currentQuestionIndex].questionText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.volume_up),
                onPressed: () =>
                    _speak(questionList[currentQuestionIndex].questionText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerInput() {
    return TextField(
      controller: answerController,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Type your answer here',
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isFirstQuestion = currentQuestionIndex == 0;
    final isLastQuestion = currentQuestionIndex == questionList.length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.4,
          height: 48,
          child: ElevatedButton(
            child: Text("Previous"),
            style: ButtonStyle(
              shape: MaterialStateProperty.all(const StadiumBorder()),
              backgroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.pressed)) {
                  return Colors.blue.shade900;
                }
                return isFirstQuestion ? Colors.grey : Colors.blueAccent;
              }),
              foregroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                return Colors.white;
              }),
            ),
            onPressed: isFirstQuestion ? null : _previousQuestion,
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.4,
          height: 48,
          child: ElevatedButton(
            child: Text(isLastQuestion ? "Submit" : "Next"),
            style: ButtonStyle(
              shape: MaterialStateProperty.all(const StadiumBorder()),
              backgroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.pressed)) {
                  return Colors.blue.shade900;
                }
                return Colors.blueAccent;
              }),
              foregroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                return Colors.white;
              }),
            ),
            onPressed: () {
              if (isLastQuestion) {
                if (answerController.text.isNotEmpty) {
                  questionList[currentQuestionIndex].userAnswer =
                      answerController.text;
                  if (questionList[currentQuestionIndex]
                          .userAnswer!
                          .trim()
                          .toLowerCase() ==
                      questionList[currentQuestionIndex]
                          .correctAnswer
                          .trim()
                          .toLowerCase()) {
                    score++;
                    correctWords.add(questionList[currentQuestionIndex].word);
                  }
                }
                stopTimer(); // Stop the timer when the quiz is submitted
                _showScoreDialog();
              } else {
                _nextQuestion();
              }
            },
          ),
        ),
      ],
    );
  }

  void _nextQuestion() {
    if (answerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please type an answer.'),
        ),
      );
      return;
    }

    setState(() {
      questionList[currentQuestionIndex].userAnswer = answerController.text;
      if (questionList[currentQuestionIndex].userAnswer!.trim().toLowerCase() ==
          questionList[currentQuestionIndex]
              .correctAnswer
              .trim()
              .toLowerCase()) {
        score++;
        correctWords.add(questionList[currentQuestionIndex].word);
      }

      if (currentQuestionIndex < questionList.length - 1) {
        currentQuestionIndex++;
        answerController.clear(); // Clear the text field
        if (widget.autoPronounce) {
          _speak(questionList[currentQuestionIndex].questionText);
        }
      } else {
        stopTimer(); // Stop the timer when the quiz is finished
        _showScoreDialog();
      }
    });
  }

  void _showScoreDialog() {
    bool isPassed = score >= questionList.length * 0.6;
    String title = isPassed ? "Passed" : "Failed";

    List<Widget> resultWidgets =
        []; // Danh sách widget để hiển thị kết quả từng câu hỏi

    for (int i = 0; i < questionList.length; i++) {
      Question question = questionList[i];
      bool isCorrect = question.userAnswer?.trim().toLowerCase() ==
          question.correctAnswer.trim().toLowerCase();

      resultWidgets.add(
        ListTile(
          title: Text("Question ${i + 1}: ${question.questionText}"),
          subtitle: Text(
            "Your answer: ${question.userAnswer ?? 'No answer'}\n"
            "Correct answer: ${question.correctAnswer}",
            style: TextStyle(color: isCorrect ? Colors.green : Colors.red),
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "$title | Score: $score",
          style: TextStyle(color: isPassed ? Colors.green : Colors.redAccent),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...resultWidgets, // Thêm danh sách kết quả từng câu hỏi vào dialog
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    child: const Text("Restart"),
                    onPressed: _restartQuiz,
                  ),
                  ElevatedButton(
                    child: const Text("End quiz"),
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                      Navigator.pop(context); // Go back to the previous screen
                      _sendQuizResults(); // Gửi kết quả bài kiểm tra
                      _sendCorrectWords(); // Gửi danh sách từ đúng
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _restartQuiz() {
    Navigator.pop(context);
    setState(() {
      currentQuestionIndex = 0;
      score = 0;
      correctWords.clear();
      answerController.clear();
      duration = 0; // Reset the duration
      startTimer(); // Restart the timer
      for (var question in questionList) {
        question.userAnswer = null;
      }
    });
  }

  // Hàm phát âm từ
  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US"); // Đặt ngôn ngữ tiếng Anh
    await flutterTts.setPitch(1); // Đặt pitch (âm vực)
    await flutterTts.setSpeechRate(0.5); // Đặt tốc độ phát âm
    await flutterTts.setVolume(1); // Đặt âm lượng
    await flutterTts.speak(text); // Phát âm từ
  }

  Future<void> _sendQuizResults() async {
    final url = Uri.parse(urlRoot + '/achievements/save-history');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'username': widget.words[1].username, // Replace with actual username
        'topicId': widget.words[1].topicId, // Replace with actual topic ID
        'mode': 'quiz', // You can change this based on your app logic
        'total': questionList.length,
        'correct': score,
        'duration': duration.toString(), // Replace with actual duration
      }),
    );

    if (response.statusCode == 200) {
      print('Quiz results sent successfully.');
    } else {
      print('Failed to send quiz results.');
    }
  }

  Future<void> _sendCorrectWords() async {
    // Convert Word objects to maps
    List<Map<String, dynamic>> wordMaps = correctWords.map((word) {
      return {
        '_id': word.id,
        'numberCorrect': word.numberCorrect + 1,
        // Add other fields as needed
      };
    }).toList();
    print(wordMaps);
    final url = Uri.parse(urlRoot + '/topics/update-progress-words/');
    final response = await http.patch(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'listWord': wordMaps, // Send the list of maps
      }),
    );

    if (response.statusCode == 200) {
      print('Correct words sent successfully.');
    } else {
      print('Failed to send correct words.');
    }
  }
}
