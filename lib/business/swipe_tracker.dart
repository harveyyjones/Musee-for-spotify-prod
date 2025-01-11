import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spotify_project/Business_Logic/Models/user_model.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/business/subscription_service.dart';

class SwipeTracker extends FirestoreDatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  // TODO: let it stay below for debugging.
  static const int MAX_FREE_SWIPES = 100;

  Future<void> trackSwipe({required bool isLike}) async {
    if (_userId == null) return;

    final today = _getTodayDate();
    final swipeRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('swipeData')
        .doc(today);

    try {
      await _firestore.runTransaction((transaction) async {
        final swipeDoc = await transaction.get(swipeRef);

        if (!swipeDoc.exists) {
          transaction.set(swipeRef, {
            'likeCount': isLike ? 1 : 0,
            'dislikeCount': isLike ? 0 : 1,
            'date': today,
          });
        } else {
          final currentLikes = swipeDoc.data()?['likeCount'] ?? 0;
          final currentDislikes = swipeDoc.data()?['dislikeCount'] ?? 0;

          transaction.update(swipeRef, {
            'likeCount': isLike ? currentLikes + 1 : currentLikes,
            'dislikeCount': isLike ? currentDislikes : currentDislikes + 1,
          });
        }
      });
    } catch (e) {
      print('Error tracking swipe: $e');
    }
  }

  Stream<int> getRemainingSwipes() {
    if (_userId == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('swipeData')
        .doc(_getTodayDate())
        .snapshots()
        .map((doc) {
      if (!doc.exists) return MAX_FREE_SWIPES;
      final likeCount = (doc.data()?['likeCount'] ?? 0) as int;
      return MAX_FREE_SWIPES - likeCount;
    });
  }

  Future<bool> canUserSwipe() async {
    if (isSubscriptionActive) return true;

    try {
      final swipeDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('swipeData')
          .doc(_getTodayDate())
          .get();

      final currentLikes =
          swipeDoc.exists ? (swipeDoc.data()?['likeCount'] ?? 0) : 0;
      return currentLikes < MAX_FREE_SWIPES;
    } catch (e) {
      print('Error checking swipe availability: $e');
      return false;
    }
  }

  Future<List<UserWithCommonSongs>> getFilteredUsersForSwipeCard({
    required String filterType,
  }) async {
    if (!isSubscriptionActive) {
      final canSwipe = await canUserSwipe();
      if (!canSwipe) {
        throw SwipeLimitException("Swipe limit reached");
      }
    }
    return await _getFilteredUsersWithCommonSongs();
  }

  Future<List<UserWithCommonSongs>> _getFilteredUsersWithCommonSongs() async {
    // Get current user's saved tracks first
    final currentUserTracks = await _firestore
        .collection("users")
        .doc(_userId)
        .collection("spotify")
        .doc("savedTracks")
        .get();

    // Get all users excluding previously seen ones
    final QuerySnapshot querySnapshot =
        await _firestore.collection("users").get();
    final previousMatchesRef = await _firestore
        .collection("matches")
        .doc(_userId)
        .collection("quickMatchesList")
        .get();

    // Create excluded users set
    Set<String> excludedUserIds = {};
    for (var doc in previousMatchesRef.docs) {
      if (doc.data()["isLiked"] == false || doc.data()["isLiked"] == true) {
        excludedUserIds.add(doc.data()["uid"] as String);
      }
    }

    // Process each user
    List<UserWithCommonSongs> usersWithCommonSongs = [];

    for (var doc in querySnapshot.docs) {
      // Skip if user is in excluded list or is current user
      if (excludedUserIds.contains(doc.id) || doc.id.isEmpty) {
        continue;
      }

      // Create user model
      UserModel user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      List<Map<String, dynamic>> commonSongs = [];
      int commonSongsCount = 0;

      // Fetch hobbies
      List<String> hobbies = [];
      final hobbiesDoc = await _firestore
          .collection("users")
          .doc(doc.id)
          .collection("interests")
          .doc("hobbies")
          .get();

      if (hobbiesDoc.exists && hobbiesDoc.data()?['hobbies'] != null) {
        hobbies = List<String>.from(hobbiesDoc.data()?['hobbies']);
      }

      // Check for common songs if current user has saved tracks
      if (currentUserTracks.exists &&
          currentUserTracks.data()?['tracks'] != null) {
        // Get other user's tracks
        final otherUserTracks = await _firestore
            .collection("users")
            .doc(doc.id)
            .collection("spotify")
            .doc("savedTracks")
            .get();

        if (otherUserTracks.exists &&
            otherUserTracks.data()?['tracks'] != null) {
          // Get tracks lists
          final tracks1 =
              (currentUserTracks.data()?['tracks'] as List<dynamic>);
          final tracks2 = (otherUserTracks.data()?['tracks'] as List<dynamic>);

          // Find common songs
          final uris1 = tracks1.map((t) => t['uri'] as String).toSet();
          final uris2 = tracks2.map((t) => t['uri'] as String).toSet();
          final commonUris = uris1.intersection(uris2);

          commonSongsCount = commonUris.length;
          if (commonSongsCount > 0) {
            // Get just 2 common songs for display
            commonSongs = tracks1
                .where((track) => commonUris.contains(track['uri']))
                .take(2)
                .toList()
                .cast<Map<String, dynamic>>();
          }
        }
      }

      usersWithCommonSongs.add(UserWithCommonSongs(
        user: user,
        commonSongs: commonSongs,
        commonSongsCount: commonSongsCount,
        hobbies: hobbies,
      ));
    }

    // Sort users: those with common songs first, then by number of common songs
    usersWithCommonSongs
        .sort((a, b) => b.commonSongsCount.compareTo(a.commonSongsCount));

    return usersWithCommonSongs;
  }

  Future<List<UserModel>> _getAllUsers() async {
    final QuerySnapshot querySnapshot =
        await _firestore.collection("users").get();

    return querySnapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

class SwipeLimitException implements Exception {
  final String message;
  SwipeLimitException(this.message);

  @override
  String toString() => message;
}
