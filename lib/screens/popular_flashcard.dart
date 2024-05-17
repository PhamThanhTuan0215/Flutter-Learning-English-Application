import 'dart:convert';
import 'package:application_learning_english/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../model/topics.dart';

class PopularFlashcard extends StatefulWidget {
  const PopularFlashcard({Key? key}) : super(key: key);

  @override
  State<PopularFlashcard> createState() => _PopularFlashcardState();
}

class _PopularFlashcardState extends State<PopularFlashcard> {
  final url_root = kIsWeb ? WEB_URL : ANDROID_URL;

  late Future<List<Topic>> futureTopics;

  @override
  void initState() {
    super.initState();
    futureTopics = fetchTopics();
  }

  Future<List<Topic>> fetchTopics() async {
    final response = await http.get(Uri.parse('$url_root/topics/public'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      final List<dynamic> topicsJson = responseBody['listTopic'];
      return topicsJson.map((json) => Topic.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load topics');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Popular topic'),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                // Handle adding new items
              },
            ),
          ],
        ),
        body: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.filter_list),
                          onPressed: () {
                            // Handle filter
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    FutureBuilder<List<Topic>>(
                      future: futureTopics,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text('No topics found'));
                        } else {
                          return Column(
                            children: snapshot.data!.map((topic) {
                              return GestureDetector(
                                onTap: () {
                                  // Handle card tap
                                  print('Tapped on: ${topic.topicName}');
                                },
                                child: Card(
                                  elevation: 3,
                                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                  child: Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          topic.topicName,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Icon(Icons.library_books, color: Colors.blue),
                                            SizedBox(width: 10),
                                            Text(
                                              '${topic.total} items',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Icon(Icons.person, color: Colors.red),
                                            SizedBox(width: 10),
                                            Text(
                                              '${topic.owner}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
