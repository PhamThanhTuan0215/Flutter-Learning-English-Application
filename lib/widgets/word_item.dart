import 'dart:convert';

import 'package:application_learning_english/config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:application_learning_english/models/word.dart';
import 'package:http/http.dart' as http;

class WordItem extends StatefulWidget {
  Word word;
  final Function(String) onDelete;
  final bool isEnableEdit;

  WordItem(
      {Key? key,
      required this.word,
      required this.onDelete,
      required this.isEnableEdit})
      : super(key: key);

  @override
  State<WordItem> createState() => _WordItemState();
}

class _WordItemState extends State<WordItem> {
  final urlRoot = kIsWeb ? WEB_URL : ANDROID_URL;

  Future<void> toggleMarkWord() async {
    try {
      var response = await http.patch(
          Uri.parse('${urlRoot}/topics/toggle-mark-word/${widget.word.id}'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          widget.word = Word.fromJson(data['newWord']);
        });
      } else {
        throw Exception('Failed to load topics');
      }
    } catch (err) {
      print(err);
    }
  }

  Future<void> adjustWord(english, vietnamese, description) async {
    try {
      var response = await http.patch(
        Uri.parse('${urlRoot}/topics/adjust-word/${widget.word.id}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'english': english,
          'vietnamese': vietnamese,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          widget.word = Word.fromJson(data['word']);
        });
      } else {
        throw Exception('Failed to load topics');
      }
    } catch (err) {
      print(err);
    }
  }

  Future<void> removeWord() async {
    try {
      var response = await http.delete(
        Uri.parse('${urlRoot}/topics/remove-word/${widget.word.id}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 0) {
          widget.onDelete(widget.word.id);
        }
      } else {
        throw Exception('Failed to remove word');
      }
    } catch (err) {
      print(err);
    }
  }

  void _adjustVocabularyDialog() {
    var _key = GlobalKey<FormState>();
    var _englishController = TextEditingController();
    var _vietnameseController = TextEditingController();
    var _descriptionController = TextEditingController();
    String english = '';
    String vietnamese = '';
    String description = '';

    _englishController.text = widget.word.english;
    _vietnameseController.text = widget.word.vietnamese;
    _descriptionController.text = widget.word.description;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Adjust Vocabulary"),
          content: Form(
            key: _key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _englishController,
                  decoration: InputDecoration(
                      labelText: 'English meaning',
                      border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter English meaning';
                    }
                  },
                  onSaved: (value) {
                    english = value ?? '';
                  },
                ),
                SizedBox(
                  height: 16,
                ),
                TextFormField(
                  controller: _vietnameseController,
                  decoration: InputDecoration(
                      labelText: 'Vietname meaning',
                      border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Vietname meaning';
                    }
                  },
                  onSaved: (value) {
                    vietnamese = value ?? '';
                  },
                ),
                SizedBox(
                  height: 16,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                      labelText: 'Description', border: OutlineInputBorder()),
                  onSaved: (value) {
                    description = value ?? '';
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (_key.currentState?.validate() ?? false) {
                  _key.currentState?.save();

                  adjustWord(english, vietnamese, description);
                  Navigator.of(context).pop();
                }
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void confirmRemove() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete this word?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                removeWord();
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.isEnableEdit ? _adjustVocabularyDialog : null,
      child: Card(
        elevation: 4.0,
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 32.0),
          title: Text(
            widget.word.english,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 38, 166, 199),
              fontSize: 20.0,
            ),
          ),
          subtitle: Text(
            widget.word.vietnamese,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18.0,
            ),
          ),
          trailing: widget.isEnableEdit
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        widget.word.isStarred ? Icons.star : Icons.star_border,
                        color: widget.word.isStarred
                            ? Colors.yellow[700]
                            : Colors.grey,
                      ),
                      onPressed: () {
                        toggleMarkWord();
                      },
                    ),
                    SizedBox(
                      width: 40.0,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        confirmRemove();
                      },
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}