import 'dart:convert';
import 'package:application_learning_english/config.dart';
import 'package:application_learning_english/models/topic.dart';
import 'package:application_learning_english/user.dart';
import 'package:application_learning_english/widgets/topic_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LibraryScreen extends StatefulWidget {
  String username;
  LibraryScreen({super.key, required this.username});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  final urlRoot = kIsWeb ? WEB_URL : ANDROID_URL;
  List<Topic> topics = [];
  List<Topic> searchTopics = [];
  String selectedFilter = 'During 7 days';
  late TabController _tabController;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchTopics();
  }

  Future<void> fetchTopics() async {
    try {
      var response = await http
          .get(Uri.parse('${urlRoot}/topics/library/${widget.username}'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          topics = (data['topics'] as List)
              .map((json) => Topic.fromJson(json))
              .toList();
        });
      } else {
        throw Exception('Failed to load topics');
      }
    } catch (err) {
      print(err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Library')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'My Sets'),
            Tab(text: 'Folders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MySets(),
          Folders(),
        ],
      ),
    );
  }

  Widget MySets() {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search topic name',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    isSearching = value.isNotEmpty;
                    searchTopics = topics
                        .where((topic) => topic.topicName
                            .toLowerCase()
                            .contains(value.toLowerCase()))
                        .toList();
                  });
                },
              ),
              SizedBox(height: 20),
              DropdownButton<String>(
                value: selectedFilter,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedFilter = newValue!;
                  });
                },
                items: <String>[
                  'Today',
                  'Yesterday',
                  'During 7 days',
                  'This Month',
                  'This Year',
                  'All'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              Stack(
                children: [
                  Opacity(
                      opacity: isSearching ? 0.0 : 1.0,
                      child: buildTopicSections(
                          topics, selectedFilter, widget.username)),
                  Opacity(
                    opacity: isSearching ? 1.0 : 0.0,
                    child: buildSearchTopics(searchTopics, widget.username),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add),
      ),
    );
  }

  Widget Folders() {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Text('Folders content here'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add),
      ),
    );
  }
}

Widget buildSearchTopics(topics, username) {
  return buildSection('Result search', topics, username);
}

Widget buildTopicSections(topics, selectedFilter, username) {
  Map<String, List<Topic>> categorizedTopics = {
    'Today': [],
    'Yesterday': [],
    'During 7 days': [],
    'This Month': [],
    'This Year': [],
    'More This Year': [],
  };

  for (var topic in topics) {
    String section = getSectionsFromCreateAt(topic.createAt);
    categorizedTopics[section]?.add(topic);

    if (section != 'This Year' && section != 'More This Year') {
      categorizedTopics['This Year']?.add(topic);
    }

    if (section != 'This Month' &&
        section != 'This Year' &&
        section != 'More This Year') {
      categorizedTopics['This Month']?.add(topic);
    }

    if (section != 'During 7 days' &&
        section != 'This Month' &&
        section != 'This Year' &&
        section != 'More This Year') {
      categorizedTopics['During 7 days']?.add(topic);
    }
  }

  return ListView(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    children: [
      if (categorizedTopics['Today']!.length > 0 &&
          (selectedFilter == 'Today' || selectedFilter == 'All'))
        buildSection('Today', categorizedTopics['Today']!, username),
      if (categorizedTopics['Yesterday']!.length > 0 &&
          (selectedFilter == 'Yesterday' || selectedFilter == 'All'))
        buildSection('Yesterday', categorizedTopics['Yesterday']!, username),
      if (categorizedTopics['During 7 days']!.length > 0 &&
          (selectedFilter == 'During 7 days' || selectedFilter == 'All'))
        buildSection(
            'During 7 days', categorizedTopics['During 7 days']!, username),
      if (categorizedTopics['This Month']!.length > 0 &&
          (selectedFilter == 'This Month' || selectedFilter == 'All'))
        buildSection('This Month', categorizedTopics['This Month']!, username),
      if (categorizedTopics['This Year']!.length > 0 &&
          (selectedFilter == 'This Year' || selectedFilter == 'All'))
        buildSection('This Year', categorizedTopics['This Year']!, username),
      if (categorizedTopics['More This Year']!.length > 0 &&
          selectedFilter == 'All')
        buildSection(
            'More This Year', categorizedTopics['More This Year']!, username),
    ],
  );
}

Widget buildSection(String title, List<Topic> topics, String username) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Text(
          title,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
        ),
      ),
      ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: topics.length,
        itemBuilder: (context, index) {
          return TopicItem(
            topic: topics[index],
            username: username,
          );
        },
      ),
    ],
  );
}

String getSectionsFromCreateAt(createAt) {
  String yy_mm_dddd = createAt.split('T')[0];
  int year = int.parse(yy_mm_dddd.split('-')[0]);
  int month = int.parse(yy_mm_dddd.split('-')[1]);
  int day = int.parse(yy_mm_dddd.split('-')[2]);

  DateTime now = DateTime.now();

  if (year == now.year && month == now.month && day == now.day) {
    return 'Today';
  } else if (year == now.year && month == now.month && day == now.day - 1) {
    return 'Yesterday';
  } else if (year == now.year && month == now.month && day > now.day - 7) {
    return 'During 7 days';
  } else if (year == now.year && month == now.month) {
    return 'This Month';
  } else if (year == now.year) {
    return 'This Year';
  } else {
    return 'More This Year';
  }
}
