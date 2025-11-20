import 'package:flutter/material.dart';
import 'awareness_page.dart';
import 'reporting_page.dart';
import 'mentorship_page.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Track selected tab

  // Pages for each tab
  final List<Widget> _pages = [
    AwarenessPage(),
    ReportingPage(),
    MentorshipPage(),
  ];

  void _onTap(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Show selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: "Awareness",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: "Report",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "Mentorship",
          ),
        ],
      ),
    );
  }
}