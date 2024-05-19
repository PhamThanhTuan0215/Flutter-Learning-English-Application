import 'package:flutter/material.dart';
import 'data.dart';
import 'package:application_learning_english/models/word.dart';
import 'package:flutter_tts/flutter_tts.dart';

class QuizScreen extends StatefulWidget {
  final List<Word> words;
  final bool isShuffle;
  final bool isEnglish;
  final bool autoPronounce;

  const QuizScreen({
    Key? key,
    required this.words,
    required this.isShuffle,
    required this.autoPronounce,
    required this.isEnglish,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Question> questionList;
  int? selectedIndex; // Trạng thái index của đáp án đã được chọn

  late FlutterTts flutterTts; // Đối tượng FlutterTts

  @override
  void initState() {
    super.initState();
    questionList =
        getQuestions(widget.words, widget.isShuffle, widget.isEnglish);
    flutterTts = FlutterTts(); // Khởi tạo FlutterTts trong initState

    if (widget.autoPronounce) {
      _speak(questionList[currentQuestionIndex].questionText);
    }
  }

  int currentQuestionIndex = 0;
  int score = 0;

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
            // _buildNavigationButtons(),
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
            color: Colors.white,
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
      // Hiển thị cảnh báo nếu người dùng không chọn câu trả lời
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an answer.'),
        ),
      );
      return; // Dừng hàm và không thực hiện tiếp các thao tác khác
    }

    setState(() {
      selectedIndex = null; // Reset trạng thái khi chuyển câu hỏi
      currentQuestionIndex++;
      if (widget.autoPronounce) {
        _speak(questionList[currentQuestionIndex].questionText);
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
      Answer selectedAnswer = question.answersList[
          question.selectedAnswerIndex!]; // Lấy câu trả lời được chọn
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
              ElevatedButton(
                child: const Text("Restart"),
                onPressed: _restartQuiz,
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
}
