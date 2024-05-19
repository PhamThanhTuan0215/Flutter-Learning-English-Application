import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'data.dart';
import 'package:application_learning_english/models/word.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:application_learning_english/config.dart';
import 'package:application_learning_english/user.dart';
import 'package:application_learning_english/utils/sessionUser.dart';

class QuizScreen extends StatefulWidget {
  final List<Word> words;
  final bool isShuffle;
  final bool isEnglish;
  final bool autoPronounce;
  final bool starCard;

  const QuizScreen({
    Key? key,
    required this.words,
    required this.isShuffle,
    required this.autoPronounce,
    required this.isEnglish,
    required this.starCard,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final urlRoot = kIsWeb ? WEB_URL : ANDROID_URL;
  User? user;

  late List<Question> questionList;
  int? selectedIndex; // Trạng thái index của đáp án đã được chọn

  late FlutterTts flutterTts;
  List<Word> correctWords = [];

  @override
  void initState() {
    super.initState();
    questionList = getQuestions(
        widget.words, widget.isShuffle, widget.isEnglish, widget.starCard);
    flutterTts = FlutterTts(); // Khởi tạo FlutterTts trong initState

    if (widget.autoPronounce) {
      _speak(questionList[currentQuestionIndex].questionText);
    }
    loadUser();

    startTimer();
  }

  loadUser() async {
    user = await getUserData();
    setState(() {});
  }

  int currentQuestionIndex = 0;
  int score = 0;
  late Timer timer;
  int duration = 0;

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
            _buildAnswerList(),
            _buildNavigationButtons()
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      "Simple Quiz App",
      style: TextStyle(
        color: Colors.white,
        fontSize: 24,
      ),
    );
  }

  void _previousQuestion() {
    setState(() {
      if (currentQuestionIndex > 0) {
        currentQuestionIndex--;
        selectedIndex = questionList[currentQuestionIndex].selectedAnswerIndex;
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
              Text(
                questionList[currentQuestionIndex].questionText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
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

  Widget _buildAnswerList() {
    return Column(
      children: questionList[currentQuestionIndex]
          .answersList
          .asMap()
          .entries
          .map((entry) => _buildAnswerButton(entry.key, entry.value))
          .toList(),
    );
  }

  Widget _buildAnswerButton(int index, Answer answer) {
    bool isSelected = index == selectedIndex;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 48,
      child: ElevatedButton(
        child: Text(answer.answerText),
        style: ButtonStyle(
          shape: MaterialStateProperty.all(const StadiumBorder()),
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.pressed) || isSelected) {
              return Colors.orangeAccent;
            }
            return Colors.white;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.pressed) || isSelected) {
              return Colors.white;
            }
            return Colors.black;
          }),
        ),
        onPressed: () {
          _selectAnswer(index);
        },
      ),
    );
  }

  void _selectAnswer(int index) {
    setState(() {
      if (selectedIndex == index) {
        // Nếu người dùng chọn lại câu trả lời đã chọn trước đó,
        // selectedIndex sẽ trở thành null để hủy chọn câu trả lời.
        selectedIndex = null;
      } else {
        // Ngược lại, cập nhật selectedIndex với câu trả lời mới được chọn.
        selectedIndex = index;
        questionList[currentQuestionIndex].selectedAnswerIndex = index;
        if (questionList[currentQuestionIndex].answersList[index].isCorrect) {
          // Nếu câu trả lời được chọn là đúng, tăng điểm
          score++;
          // Add the correct word to the list of correct words
          correctWords.add(widget.words[currentQuestionIndex]);
        }
      }
    });
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
            onPressed: isLastQuestion ? _showScoreDialog : _nextQuestion,
          ),
        ),
      ],
    );
  }

  void _nextQuestion() {
    if (selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an answer.'),
        ),
      );
      return;
    }

    setState(() {
      selectedIndex = null;
      currentQuestionIndex++;
      if (widget.autoPronounce) {
        _speak(questionList[currentQuestionIndex].questionText);
      }
    });
  }

  void _showScoreDialog() async {
    stopTimer();
    bool isPassed = score >= questionList.length * 0.6;
    String title = isPassed ? "Passed" : "Failed";

    List<Widget> resultWidgets = [];

    for (int i = 0; i < questionList.length; i++) {
      Question question = questionList[i];
      Answer selectedAnswer =
          question.answersList[question.selectedAnswerIndex!];
      bool isCorrect = selectedAnswer.isCorrect;

      resultWidgets.add(
        ListTile(
          title: Text("Question ${i + 1}: ${question.questionText}"),
          subtitle: Text(
            "Your answer: ${selectedAnswer.answerText}\n"
            "Correct answer: ${question.answersList.firstWhere((answer) => answer.isCorrect).answerText}",
            style: TextStyle(color: isCorrect ? Colors.green : Colors.red),
          ),
        ),
      );
    }

    await _sendQuizResults(); // Send quiz results before showing the dialog
    await _sendCorrectWords();

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
              ...resultWidgets,
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
      selectedIndex = null; // Reset trạng thái khi restart quiz
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
        'duration': duration // Replace with actual duration
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
