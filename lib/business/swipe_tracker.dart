import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spotify_project/Business_Logic/Models/user_model.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/business/subscription_service.dart';

class SwipeTracker extends FirestoreDatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  // FIXME: let it stay below for debugging.
  static const int MAX_FREE_SWIPES = 105;

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

  Future<List<UserModel>> getFilteredUsersForSwipeCard({
    required String filterType,
  })
  // To use in quick matches.

  async {
    if (!isSubscriptionActive) {
      final canSwipe = await canUserSwipe();
      if (!canSwipe) {
        throw SwipeLimitException('Daily swipe limit reached');
      }
    }

    switch (filterType) {
      case "never see the unliked again":
        return _getFilteredUsersExcludingUnliked();
      case "show the swiped again later":
        return _getAllUsers();
      default:
        throw ArgumentError('Invalid filter type provided');
    }
  }

  Future<List<UserModel>> _getFilteredUsersExcludingUnliked() async {
    final QuerySnapshot querySnapshot =
        await _firestore.collection("users").get();

    final previousMatchesRef = await _firestore
        .collection("matches")
        .doc(_userId)
        .collection("quickMatchesList")
        .get();

    Set<String> excludedUserIds = {};
    for (var doc in previousMatchesRef.docs) {
      if (doc.data()["isLiked"] == false || doc.data()["isLiked"] == true) {
        excludedUserIds.add(doc.data()["uid"] as String);
      }
    }

    return querySnapshot.docs
        .where(
            (doc) => !excludedUserIds.contains(doc.id) && (doc.id.isNotEmpty))
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
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
