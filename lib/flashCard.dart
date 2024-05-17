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
                borderRadius: BorderRadius.circular(20))),
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
              SizedBox(
                  width: 300,
                  height: 300,
                  child: FlipCard(
                      direction: FlipDirection.VERTICAL,
                      front: ReusableCard(
                          text: quesAnsList[_currentIndexNumber].question),
                      back: ReusableCard(
                          text: quesAnsList[_currentIndexNumber].answer))),
              Text("Tab to see Answer", style: otherTextStyle),
              SizedBox(height: 20),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    ElevatedButton.icon(
                        onPressed: _currentIndexNumber == 0
                            ? null
                            : () {
                                showPreviousCard();
                                updateToPrev();
                              },
                        icon: Icon(FontAwesomeIcons.arrowLeft, size: 30),
                        label: Text(""),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: EdgeInsets.only(
                                right: 20, left: 25, top: 15, bottom: 15))),
                    ElevatedButton.icon(
                        onPressed: _currentIndexNumber == quesAnsList.length - 1
                            ? null
                            : () {
                                showNextCard();
                                updateToNext();
                              },
                        icon: Icon(FontAwesomeIcons.arrowRight, size: 30),
                        label: Text(""),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: EdgeInsets.only(
                                right: 20, left: 25, top: 15, bottom: 15)))
                  ])
            ])));
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
