import 'package:application_learning_english/screens/account_screen.dart';
import 'package:application_learning_english/screens/library_screen.dart';
import 'package:application_learning_english/user.dart';
import 'package:application_learning_english/utils/sessionUser.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bottom Navigation Bar Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _children = [
    Library(),
    Community(),
    Profile(),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class Library extends StatefulWidget {
  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  String? username;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void loadUser() async {
    User? user = await getUserData();
    setState(() {
      username = user?.username;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (username == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    // Chỉ hiển thị LibraryScreen khi username đã được cập nhật
    return LibraryScreen(username: username!);
  }
}

class Community extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Community Screen'),
    );
  }
}

class Profile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AccountScreen();
  }
}
