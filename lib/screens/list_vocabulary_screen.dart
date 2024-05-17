import 'dart:convert';

import 'package:application_learning_english/config.dart';
import 'package:application_learning_english/flashCard.dart';
import 'package:application_learning_english/models/topic.dart';
import 'package:application_learning_english/models/word.dart';
import 'package:application_learning_english/widgets/word_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';

class ListVocabularyScreen extends StatefulWidget {
  final List<Word> words;
  final Topic topic;
  final bool isEnableEdit;
  final String username;

  const ListVocabularyScreen({
    Key? key,
    required this.words,
    required this.topic,
    required this.isEnableEdit,
    required this.username,
  }) : super(key: key);

  @override
  State<ListVocabularyScreen> createState() => _ListVocabularyScreenState();
}

class _ListVocabularyScreenState extends State<ListVocabularyScreen> {
  final urlRoot = kIsWeb ? WEB_URL : ANDROID_URL;
  bool isUpdateAmount = false;

  void deleteWord(String wordId) {
    setState(() {
      widget.words.removeWhere((word) => word.id == wordId);
      isUpdateAmount = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Remove word successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void updateWord(Word word) {
    setState(() {
      int index = widget.words.indexWhere((w) => w.id == word.id);
      if (index != -1) {
        widget.words[index] = word;
      }
    });
  }

  void _addVocabularyDialog() {
    var _key = GlobalKey<FormState>();
    var _englishController = TextEditingController();
    var _vietnameseController = TextEditingController();
    var _descriptionController = TextEditingController();
    String english = '';
    String vietnamese = '';
    String description = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Vocabulary"),
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
                      labelText: 'Description (Can be empty)',
                      border: OutlineInputBorder()),
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

                  var listWord = [
                    {
                      'english': english,
                      'vietnamese': vietnamese,
                      'description': description,
                    }
                  ];

                  addWords(listWord);
                  Navigator.of(context).pop();
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> addWords(listWord) async {
    try {
      var response = await http.post(
          Uri.parse(
              '${urlRoot}/topics/${widget.topic.id}/add-words/${widget.username}'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'listWord': listWord,
          }));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 0) {
          setState(() {
            var newWords = data['newWords'];
            for (var newWord in newWords) {
              widget.words.add(Word.fromJson(newWord));
            }
            isUpdateAmount = true;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'].toString()),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add word'),
            duration: Duration(seconds: 2),
          ),
        );
        throw Exception('Failed to add word');
      }
    } catch (err) {
      print(err);
    }
  }

  void _importFile() async {
    try {
      // Chọn tệp CSV
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.bytes != null) {
        // Đọc dữ liệu từ tệp CSV
        String fileContent = utf8.decode(result.files.single.bytes!);

        // Phân tích cú pháp tệp CSV
        List<List<dynamic>> csvData = CsvToListConverter().convert(fileContent);

        // Tạo danh sách listWord từ dữ liệu CSV
        List<Map<String, String>> listWord = [];
        for (var i = 1; i < csvData.length; i++) {
          listWord.add({
            'english': csvData[i][0],
            'vietnamese': csvData[i][1],
          });
        }

        print(listWord);
      } else {
        print("No file selected or file is empty.");
      }
    } catch (e) {
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Can not import file from web platform'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      print("Error picking or reading file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context, isUpdateAmount);
          },
        ),
        title: Center(child: Text('Vocabulary List')),
        actions: [
          if (widget.isEnableEdit)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  onPressed: () {
                    _addVocabularyDialog();
                  },
                  icon: Icon(
                    Icons.add_circle_outline,
                    size: 30,
                    color: Color.fromARGB(255, 33, 44, 204),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        color: Colors.blueGrey[100],
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text('Import file'),
              IconButton(
                  onPressed: _importFile, icon: Icon(Icons.document_scanner)),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.words.length,
                  itemBuilder: (context, index) {
                    return WordItem(
                        word: widget.words[index],
                        onDelete: deleteWord,
                        onUpdate: updateWord,
                        isEnableEdit: widget.isEnableEdit);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FlashCard(),
            ),
          );
        },
        child: Icon(Icons.school),
      ),
    );
  }
}
