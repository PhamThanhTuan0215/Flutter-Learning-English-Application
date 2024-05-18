import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_tts/flutter_tts.dart';

import './flashCard/all_constants.dart';
import './flashCard/ques_ans_file.dart';
import './flashCard/reusable_card.dart';

class FlashCard extends StatefulWidget {
  const FlashCard({super.key});

  @override
  State<FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard> {
  int _currentIndexNumber = 0;
  double _initial = 0.1;
  bool isFlipped = false;
  bool autoFlippedEnable = false;
  double _startX = 0;
  double _endX = 0;
  Timer? flipTimer;
  Timer? changeCardTimer;
  final GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    if (autoFlippedEnable) {
      startAutoFlip();
    }
  }

  @override
  void dispose() {
    flipTimer?.cancel();
    changeCardTimer?.cancel();
    super.dispose();
  }

  void startAutoFlip() {
    flipTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      cardKey.currentState?.toggleCard();
      setState(() {
        isFlipped = !isFlipped;
      });

      if (isFlipped) {
        changeCardTimer = Timer(Duration(seconds: 5), () {
          cardKey.currentState?.toggleCard();
          setState(() {
            isFlipped = false;
            showNextCard();
            updateToNext();
          });
        });
      }
    });
  }

  void stopAutoFlip() {
    flipTimer?.cancel();
    changeCardTimer?.cancel();
  }

  void toggleAutoFlip() {
    setState(() {
      autoFlippedEnable = !autoFlippedEnable;
      if (autoFlippedEnable) {
        startAutoFlip();
      } else {
        stopAutoFlip();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String value = "${_currentIndexNumber + 1} of ${quesAnsList.length}";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        centerTitle: true,
        title: Text("Flashcards App", style: TextStyle(fontSize: 30)),
        backgroundColor: mainColor,
        toolbarHeight: 80,
        elevation: 5,
        shadowColor: mainColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          Row(
            children: [
              Text("Auto Flip", style: TextStyle(fontSize: 16)),
              Switch(
                value: autoFlippedEnable,
                onChanged: (value) {
                  toggleAutoFlip();
                },
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Question $value Completed", style: otherTextStyle),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation(mainColor),
                minHeight: 5,
                value: _initial,
              ),
            ),
            SizedBox(height: 25),
            GestureDetector(
              onHorizontalDragStart: (details) {
                // Xác định vị trí bắt đầu của sự kiện lướt ngang
                _startX = details.globalPosition.dx;
                stopAutoFlip();
              },
              onHorizontalDragUpdate: (details) {
                // Cập nhật vị trí khi lướt ngang
                _endX = details.globalPosition.dx;
              },
              onHorizontalDragEnd: (details) {
                // Tính toán tốc độ
                final double velocity =
                    (_endX - _startX).abs() / details.primaryVelocity!;

                // Xác định hướng và chỉ thực hiện chuyển thẻ khi tốc độ đủ lớn
                if (velocity > 1000) {
                  final double delta = _endX - _startX;
                  if (delta > 0) {
                    if (_currentIndexNumber > 0) {
                      showPreviousCard();
                    }
                  } else {
                    if (_currentIndexNumber < quesAnsList.length - 1) {
                      showNextCard();
                    }
                  }
                }
              },
              child: SizedBox(
                width: 300,
                height: 300,
                child: FlipCard(
                  key: cardKey,
                  direction: FlipDirection.HORIZONTAL,
                  flipOnTouch: false,
                  front: GestureDetector(
                    onTap: () {
                      cardKey.currentState?.toggleCard();
                      setState(() {
                        isFlipped = !isFlipped;
                      });
                    },
                    child: Stack(children: [
                      ReusableCard(
                        text: quesAnsList[_currentIndexNumber].question,
                      ),
                      Positioned(
                          top: 10, // Điều chỉnh vị trí từ top
                          right: 10,
                          child: IconButton(
                            icon: Icon(Icons.volume_up),
                            onPressed: () {
                              flutterTts.speak(
                                  quesAnsList[_currentIndexNumber].question!);
                            },
                          ))
                    ]),
                  ),
                  back: GestureDetector(
                    onTap: () {
                      cardKey.currentState?.toggleCard();
                      setState(() {
                        isFlipped = !isFlipped;
                      });
                    },
                    child: Stack(children: [
                      ReusableCard(
                        text: quesAnsList[_currentIndexNumber].answer,
                      ),
                      Positioned(
                          top: 10, // Điều chỉnh vị trí từ top
                          right: 10,
                          child: IconButton(
                            icon: Icon(Icons.volume_up),
                            onPressed: () {
                              flutterTts.speak(
                                  quesAnsList[_currentIndexNumber].answer!);
                            },
                          ))
                    ]),
                  ),
                ),
              ),
            ),
            Text("Tap to see Answer", style: otherTextStyle),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void updateToNext() {
    setState(() {
      _currentIndexNumber = (_currentIndexNumber + 1) % quesAnsList.length;
      _initial = (_currentIndexNumber + 1) / quesAnsList.length;
    });
  }

  void updateToPrev() {
    setState(() {
      _currentIndexNumber = (_currentIndexNumber - 1 >= 0)
          ? _currentIndexNumber - 1
          : quesAnsList.length - 1;
      _initial = (_currentIndexNumber + 1) / quesAnsList.length;
    });
  }

  void showNextCard() {
    setState(() {
      _currentIndexNumber = (_currentIndexNumber + 1) % quesAnsList.length;
      _initial = (_currentIndexNumber + 1) / quesAnsList.length;
    });
  }

  void showPreviousCard() {
    setState(() {
      _currentIndexNumber = (_currentIndexNumber - 1 >= 0)
          ? _currentIndexNumber - 1
          : quesAnsList.length - 1;
      _initial = (_currentIndexNumber + 1) / quesAnsList.length;
    });
  }
}
