import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/main.dart';
import 'package:spotify_project/screens/matches_screen.dart';
import 'package:spotify_project/screens/message_box.dart';
import 'package:spotify_project/screens/own_profile_screens_for_clients.dart';
import 'package:spotify_project/screens/likes_screen.dart'; // Add this import

class BottomBar extends StatefulWidget {
  int selectedIndex;

  BottomBar({super.key, required this.selectedIndex});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  final FirestoreDatabaseService _firestoreDatabaseService =
      FirestoreDatabaseService();
  var _index = 0;

  final List _pagesToNavigateToForClients = [
    Home(),
    const MatchesScreen(),
    OwnProfileScreenForClients(),
    MessageScreen(),
    LikesScreen(), // Add this new screen
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black, // Dark theme background
        boxShadow: [
          BoxShadow(
            color:
                Colors.white.withOpacity(0.1), // Subtle shadow for dark theme
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      height: screenSize.height * 0.1, // Increased height for larger buttons
      child: FutureBuilder(
        future: _firestoreDatabaseService.getUserData(),
        builder: (context, snapshot) => BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.black,
            selectedItemColor:
                Colors.blueAccent, // Bright color for selected item
            unselectedItemColor:
                Colors.grey[600], // Darker grey for unselected items
            showSelectedLabels: false,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            currentIndex: widget.selectedIndex,
            onTap: (value) {
              _index = value;
              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (context) {
                return _pagesToNavigateToForClients[value];
              }), (route) => false);
              setState(() {});
            },
            items: [
              _buildNavigationBarItem(Icons.home_rounded, ""),
              _buildNavigationBarItem(Icons.headphones_rounded, ""),
              _buildNavigationBarItem(Icons.person_rounded, ""),
              _buildNavigationBarItem(Icons.chat_bubble_rounded, ""),
              _buildNavigationBarItem(Icons.favorite, ""),
            ]),
      ),
    );
  }

  BottomNavigationBarItem _buildNavigationBarItem(IconData icon, String label,
      {IconData? outlinedIcon}) {
    return BottomNavigationBarItem(
      activeIcon: Icon(
        icon,
        size: 30.sp, // Increased icon size
      ),
      label: label,
      icon: Icon(
        outlinedIcon ?? icon,
        size: 28.sp, // Increased icon size
      ),
    );
  }
}
