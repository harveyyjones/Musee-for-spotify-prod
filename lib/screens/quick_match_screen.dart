import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spotify_project/Business_Logic/Models/user_model.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/business/subscription_service.dart';
import 'package:spotify_project/business/swipe_tracker.dart';
import 'package:spotify_project/screens/premium_subscription_screen.dart';
import 'package:spotify_project/widgets/swipe_cards_for_quick_match.dart';

class QuickMatchesScreen extends StatefulWidget {
  const QuickMatchesScreen({Key? key}) : super(key: key);

  @override
  State<QuickMatchesScreen> createState() => _QuickMatchesScreenState();
}

class _QuickMatchesScreenState extends State<QuickMatchesScreen> {
  final SwipeTracker _swipeTracker = SwipeTracker();
  Future<List<UserModel>>? _dataFuture;
  late String _showSwipedAgainLater;
  late String _neverSeeIfUnliked;
  final FirestoreDatabaseService firestoreDatabaseService =
      FirestoreDatabaseService();

  @override
  void initState() {
    super.initState();
    _showSwipedAgainLater = "show the swiped again later";
    _neverSeeIfUnliked = "never see the unliked again";
    _loadInitialData();
    firestoreDatabaseService.updateActiveStatus();
  }

  void _loadInitialData() {
    _dataFuture = _loadData(_neverSeeIfUnliked);
  }

  Future<List<UserModel>> _loadData(String filterType) async {
    try {
      // Try to get filtered users
      List<UserModel> users = await _swipeTracker.getFilteredUsersForSwipeCard(
        filterType: filterType,
      );
      return users;
    } on SwipeLimitException {
      // Handle swipe limit reached
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const SubscribePremiumScreen()),
        );
      });
      return [];
    } catch (e) {
      print('Error in _loadData: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: StreamBuilder<int>(
          stream: _swipeTracker.getRemainingSwipes(),
          builder: (context, snapshot) {
            if (!isSubscriptionActive && snapshot.hasData) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${snapshot.data} likes left',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1DB954)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load matches',
                style: TextStyle(color: Colors.white70, fontSize: 16.sp),
              ),
            );
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Text(
                'No matches available',
                style: TextStyle(color: Colors.white70, fontSize: 16.sp),
              ),
            );
          }

          return SwipeCardWidgetForQuickMatch(
            snapshotData: users,
            onSwipe: (bool isLike) async {
              await _swipeTracker.trackSwipe(isLike: isLike);

              // Reload data if needed
              if (!isSubscriptionActive) {
                final canSwipe = await _swipeTracker.canUserSwipe();
                if (!canSwipe) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscribePremiumScreen(),
                    ),
                  );
                }
              }
            },
          );
        },
      ),
    );
  }
}
