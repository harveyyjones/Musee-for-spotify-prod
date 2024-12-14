import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/Business_Logic/Models/user_model.dart';
import 'package:spotify_project/business/subscription_service.dart';
import 'package:spotify_project/screens/premium_subscription_screen.dart';
import 'package:spotify_project/screens/profile_screen.dart';
import 'package:spotify_project/widgets/bottom_bar.dart';

class LikesScreen extends StatefulWidget {
  @override
  _LikesScreenState createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  final FirestoreDatabaseService _databaseService = FirestoreDatabaseService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  late Future<List<UserModel>> _peopleWhoLikedMeFuture;

  @override
  void initState() {
    super.initState();
    _peopleWhoLikedMeFuture = _databaseService.getPeopleWhoLikedMe();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
        stream: _subscriptionService.subscriptionStatusStream(),
        builder: (context, subscriptionSnapshot) {
          isSubscriptionActive = subscriptionSnapshot.data ?? false;

          return Scaffold(
            backgroundColor: const Color(0xFF121212),
            appBar: AppBar(
              backgroundColor: const Color(0xFF121212),
              elevation: 0,
              title: Text(
                'People Who Liked You',
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: FutureBuilder<List<UserModel>>(
              future: _peopleWhoLikedMeFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF1DB954)));
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No one has liked you yet.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    UserModel user = snapshot.data![index];
                    return _buildUserItem(user);
                  },
                );
              },
            ),
            bottomNavigationBar: BottomBar(selectedIndex: 4),
          );
        });
  }

  Widget _buildUserItem(UserModel user) {
    return GestureDetector(
      onTap: () {
        if (isSubscriptionActive) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ProfileScreen(uid: user.userId ?? '')),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const SubscribePremiumScreen()),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: isSubscriptionActive
                      ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                      : ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Image.network(
                    user.profilePhotos.isNotEmpty
                        ? user.profilePhotos.first
                        : 'https://example.com/default_profile_image.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent
                      ],
                    ),
                  ),
                  child: Text(
                    user.name ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (!isSubscriptionActive)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: Colors.white,
                            size: 30,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Premium Only',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
