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
  String selectedFilter = 'This Month';
  late TabController _tabController;
  bool isSearching = false;

  void deleteTopic(String topicId) {
    setState(() {
      topics.removeWhere((topic) => topic.id == topicId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Remove word successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void updateWord(Topic topic) {
    setState(() {
      int index = topics.indexWhere((t) => t.id == topic.id);
      if (index != -1) {
        topics[index] = topic;
      }
    });
  }

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

  Future<void> addTopic(topicName, isPublic) async {
    try {
      var response = await http.post(Uri.parse('${urlRoot}/topics/add'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'topicName': topicName,
            'isPublic': isPublic,
            'owner': widget.username
          }));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 0) {
          setState(() {
            var newTopic = Topic.fromJson(data['topic']);
            topics.insert(0, newTopic);
            selectedFilter = 'Today';
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

  void _addTopicDialog() {
    var _key = GlobalKey<FormState>();

    String topicName = '';
    bool isPublic = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text("Add New Topic"),
            content: Form(
              key: _key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: 'Topic Name', border: OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter topic name';
                      }
                    },
                    onSaved: (value) {
                      topicName = value ?? '';
                    },
                  ),
                  Row(
                    children: [
                      Text("Public"),
                      Checkbox(
                        value: isPublic,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            isPublic = value ?? false;
                          });
                        },
                      ),
                    ],
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

                    addTopic(topicName, isPublic);
                    Navigator.of(context).pop();
                  }
                },
                child: Text("Save"),
              ),
            ],
          ),
        );
      },
    );
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
                      child: buildTopicSections(topics, selectedFilter,
                          widget.username, deleteTopic, updateWord)),
                  Opacity(
                    opacity: isSearching ? 1.0 : 0.0,
                    child: buildSearchTopics(
                        searchTopics, widget.username, deleteTopic, updateWord),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTopicDialog,
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

Widget buildSearchTopics(topics, username, deleteTopic, updateWord) {
  return buildSection(
      'Result search', topics, username, deleteTopic, updateWord);
}

Widget buildTopicSections(
    topics, selectedFilter, username, deleteTopic, updateWord) {
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

    // if (section != 'This Year' && section != 'More This Year') {
    //   categorizedTopics['This Year']?.add(topic);
    // }

    // if (section != 'This Month' &&
    //     section != 'This Year' &&
    //     section != 'More This Year') {
    //   categorizedTopics['This Month']?.add(topic);
    // }

    // if (section != 'During 7 days' &&
    //     section != 'This Month' &&
    //     section != 'This Year' &&
    //     section != 'More This Year') {
    //   categorizedTopics['During 7 days']?.add(topic);
    // }
  }

  return ListView(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    children: [
      if (categorizedTopics['Today']!.length > 0 &&
          (selectedFilter == 'Today' ||
              selectedFilter == 'During 7 days' ||
              selectedFilter == 'This Month' ||
              selectedFilter == 'This Year' ||
              selectedFilter == 'All'))
        buildSection('Today', categorizedTopics['Today']!, username,
            deleteTopic, updateWord),
      if (categorizedTopics['Yesterday']!.length > 0 &&
          (selectedFilter == 'Yesterday' ||
              selectedFilter == 'During 7 days' ||
              selectedFilter == 'This Month' ||
              selectedFilter == 'This Year' ||
              selectedFilter == 'All'))
        buildSection('Yesterday', categorizedTopics['Yesterday']!, username,
            deleteTopic, updateWord),
      if (categorizedTopics['During 7 days']!.length > 0 &&
          (selectedFilter == 'During 7 days' ||
              selectedFilter == 'This Month' ||
              selectedFilter == 'This Year' ||
              selectedFilter == 'All'))
        buildSection('During 7 days', categorizedTopics['During 7 days']!,
            username, deleteTopic, updateWord),
      if (categorizedTopics['This Month']!.length > 0 &&
          (selectedFilter == 'This Month' ||
              selectedFilter == 'This Year' ||
              selectedFilter == 'All'))
        buildSection('This Month', categorizedTopics['This Month']!, username,
            deleteTopic, updateWord),
      if (categorizedTopics['This Year']!.length > 0 &&
          (selectedFilter == 'This Year' || selectedFilter == 'All'))
        buildSection('This Year', categorizedTopics['This Year']!, username,
            deleteTopic, updateWord),
      if (categorizedTopics['More This Year']!.length > 0 &&
          selectedFilter == 'All')
        buildSection('More This Year', categorizedTopics['More This Year']!,
            username, deleteTopic, updateWord),
    ],
  );
}

Widget buildSection(String title, List<Topic> topics, String username,
    deleteTopic, updateWord) {
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
              onDelete: deleteTopic,
              onUpdate: updateWord);
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
