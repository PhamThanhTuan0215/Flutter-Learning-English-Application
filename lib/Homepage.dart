import 'package:flutter/material.dart';
import 'package:websafe_svg/websafe_svg.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    LibraryScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _children[_currentIndex],
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Stack(
              children: [
                WebsafeSvg.asset(
                  'assets/icons/bg.svg', // Đường dẫn đến file SVG của bạn
                  fit: BoxFit.cover,
                  height: kBottomNavigationBarHeight,
                ),
                BottomNavigationBar(
                  backgroundColor: Colors.transparent, // Làm cho nền trong suốt
                  onTap: onTabTapped,
                  currentIndex: _currentIndex,
                  selectedItemColor: Colors.white, // Màu chữ khi được chọn
                  unselectedItemColor: Colors.grey, // Màu chữ khi không được chọn
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LibraryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: WebsafeSvg.asset(
              'assets/icons/bg.svg', // Đường dẫn đến file SVG của bạn
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Text(
              'Library Screen',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class CommunityScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: WebsafeSvg.asset(
              'assets/icons/bg.svg', // Đường dẫn đến file SVG của bạn
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Text(
              'Community Screen',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: WebsafeSvg.asset(
              'assets/icons/bg.svg', // Đường dẫn đến file SVG của bạn
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Text(
              'Profile Screen',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
