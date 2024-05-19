import 'package:application_learning_english/screens/Vocab_learning/card_learning/card_setting.dart';
import 'package:application_learning_english/screens/Vocab_learning/quiz_learning/quizSetting.dart';
import 'package:application_learning_english/models/word.dart';
import 'package:application_learning_english/screens/Vocab_learning/typing_learning/typingSetting.dart';
import 'package:flutter/material.dart';

class MainMenu extends StatefulWidget {
  final List<Word> words;

  const MainMenu({Key? key, required this.words}) : super(key: key);

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  late List<Word> notLearnedWords;
  late List<Word> currentlyLearningWords;
  late List<Word> masteredWords;

  @override
  void initState() {
    super.initState();
    categorizeWords();
  }

  void categorizeWords() {
    notLearnedWords =
        widget.words.where((word) => word.status == 'not learned').toList();
    currentlyLearningWords = widget.words
        .where((word) => word.status == 'currently learning')
        .toList();
    masteredWords =
        widget.words.where((word) => word.status == 'mastered').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Learning App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildMenuButton(
                'FlashCard learning', CardSettingsScreen(words: widget.words)),
            _buildMenuButton(
                'Quiz Feature', QuizSettingsScreen(words: widget.words)),
            _buildMenuButton('Typing Practice Feature',
                TypingSettingScreen(words: widget.words)),
            SizedBox(height: 20),
            _buildWordStatusList('Not Learned Words:', notLearnedWords),
            _buildWordStatusList(
                'Currently Learning Words:', currentlyLearningWords),
            _buildWordStatusList('Mastered Words:', masteredWords),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(String text, Widget screen) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => screen,
            ),
          );
        },
        child: Text(text),
      ),
    );
  }

  Widget _buildWordStatusList(String title, List<Word> words) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: words.length,
              itemBuilder: (context, index) {
                Word word = words[index];
                return ListTile(
                  title: Text(word.english),
                  subtitle: Text(word.vietnamese),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
