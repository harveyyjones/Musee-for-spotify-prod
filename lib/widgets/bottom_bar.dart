import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/main.dart';
import 'package:spotify_project/screens/find_near_listeners_map_screen.dart';
import 'package:spotify_project/screens/matches_screen.dart';
import 'package:spotify_project/screens/message_box.dart';
import 'package:spotify_project/screens/own_profile_screens_for_clients.dart';
import 'package:spotify_project/screens/likes_screen.dart';

class BottomBar extends StatefulWidget {
  final int selectedIndex;
  const BottomBar({Key? key, required this.selectedIndex}) : super(key: key);

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar>
    with SingleTickerProviderStateMixin {
  final FirestoreDatabaseService _firestoreDatabaseService =
      FirestoreDatabaseService();
  var _index = 0;

  final List _pagesToNavigateToForClients = [
    Home(),
    const MatchesScreen(),
    NearListenersMapScreen(),
    OwnProfileScreenForClients(),
    MessageScreen(),
    LikesScreen(),
  ];

  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: Colors.black,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          height: 121.h,
          child: FutureBuilder(
            future: _firestoreDatabaseService.getUserData(),
            builder: (context, snapshot) => Stack(
              children: [
                CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, 80.h),
                  painter: SpotlightPainter(
                    selectedIndex: widget.selectedIndex,
                    animation: _glowAnimation,
                  ),
                ),
                BottomNavigationBar(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  selectedItemColor: Colors.white,
                  unselectedItemColor: Colors.grey[600],
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  type: BottomNavigationBarType.fixed,
                  currentIndex: widget.selectedIndex,
                  onTap: (value) {
                    _animationController.reset();
                    _animationController.forward();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return _pagesToNavigateToForClients[value];
                      }),
                      (route) => false,
                    );
                  },
                  items: [
                    _buildNavigationBarItem(Icons.home_rounded),
                    _buildNavigationBarItem(Icons.headphones_rounded),
                    _buildNavigationBarItem(Icons.map_rounded),
                    _buildNavigationBarItem(Icons.person_rounded),
                    _buildNavigationBarItem(Icons.chat_bubble_rounded),
                    _buildNavigationBarItem(Icons.favorite),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavigationBarItem(IconData icon) {
    return BottomNavigationBarItem(
      activeIcon: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) => Icon(
          icon,
          size: 37.5.sp,
          color: Colors.white,
        ),
      ),
      icon: Icon(
        icon,
        size: 35.sp,
        color: Colors.grey[600],
      ),
      label: '',
    );
  }
}

class SpotlightPainter extends CustomPainter {
  final int selectedIndex;
  final Animation<double> animation;

  SpotlightPainter({
    required this.selectedIndex,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final itemWidth = size.width / 6;
    final centerX = (itemWidth * selectedIndex) + (itemWidth / 2);

    // Create wider spotlight cone starting from a wider top
    final path = Path()
      ..moveTo(centerX - 10.w, 0) // Start wider at top
      ..lineTo(centerX - 25.w, size.height - 20.h) // Wider at bottom
      ..lineTo(centerX + 25.w, size.height - 20.h) // Wider at bottom
      ..lineTo(centerX + 10.w, 0) // Back to wider top
      ..close();

    // More visible gradient for the cone with less visible end color
    final conePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.purple.withOpacity(0.5 * animation.value), // Increased opacity
          Colors.purple.withOpacity(0.3 * animation.value),
          Colors.purple
              .withOpacity(0.05 * animation.value), // Less visible end color
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw the wider cone
    canvas.drawPath(path, conePaint);

    // Draw a bold white divider at the top of the cone
    final dividerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0; // Bold line

    canvas.drawLine(
      Offset(centerX - 10.w, 0),
      Offset(centerX + 10.w, 0),
      dividerPaint,
    );

    // Larger, more visible glow at the icon position
    final spotlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.purple.withOpacity(0.4 * animation.value), // Increased opacity
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(centerX, size.height - 20.h),
          radius: 30.h, // Increased radius
        ),
      );

    // Draw larger glow
    canvas.drawCircle(
      Offset(centerX, size.height - 20.h),
      30.h, // Increased radius
      spotlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SpotlightPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.animation != animation;
  }
}
