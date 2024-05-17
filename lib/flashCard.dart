import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  Timer? flipTimer;
  Timer? changeCardTimer;
  final GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();

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
    String value = (_initial * 10).toStringAsFixed(0);
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
            Text("Question $value of 10 Completed", style: otherTextStyle),
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
                final RenderBox box = context.findRenderObject() as RenderBox;
                final Offset localOffset =
                    box.globalToLocal(details.globalPosition);

                // Kiểm tra xem vị trí bắt đầu có nằm trong phạm vi của thẻ không
                final bool isInsideCard =
                    localOffset.dx >= 0 && localOffset.dx <= box.size.width;

                // Nếu vị trí bắt đầu nằm trong thẻ, không thực hiện chuyển thẻ tự động
                if (isInsideCard) {
                  stopAutoFlip();
                }
              },
              onHorizontalDragUpdate: (details) {
                // Xác định vị trí cập nhật của sự kiện lướt ngang
                final RenderBox box = context.findRenderObject() as RenderBox;
                final Offset localOffset =
                    box.globalToLocal(details.globalPosition);

                // Kiểm tra xem vị trí cập nhật có nằm trong phạm vi của thẻ không
                final bool isInsideCard =
                    localOffset.dx >= 0 && localOffset.dx <= box.size.width;

                // Nếu vị trí cập nhật nằm trong thẻ, không thực hiện chuyển thẻ tự động
                if (isInsideCard) {
                  stopAutoFlip();
                }
              },
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity!;
                if (velocity > 0) {
                  showPreviousCard();
                } else if (velocity < 0) {
                  showNextCard();
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
                    child: ReusableCard(
                      text: quesAnsList[_currentIndexNumber].question,
                    ),
                  ),
                  back: GestureDetector(
                    onTap: () {
                      cardKey.currentState?.toggleCard();
                      setState(() {
                        isFlipped = !isFlipped;
                      });
                    },
                    child: ReusableCard(
                      text: quesAnsList[_currentIndexNumber].answer,
                    ),
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
      _initial = _initial + 0.1;
      if (_initial > 1.0) {
        _initial = 0.1;
      }
    });
  }

  void updateToPrev() {
    setState(() {
      _initial = _initial - 0.1;
      if (_initial < 0.1) {
        _initial = 1.0;
      }
    });
  }

  void showNextCard() {
    setState(() {
      _currentIndexNumber = (_currentIndexNumber + 1 < quesAnsList.length)
          ? _currentIndexNumber + 1
          : 0;
    });
  }

  void showPreviousCard() {
    setState(() {
      _currentIndexNumber = (_currentIndexNumber - 1 >= 0)
          ? _currentIndexNumber - 1
          : quesAnsList.length - 1;
    });
  }
}
