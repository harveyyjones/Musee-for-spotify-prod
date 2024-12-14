import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

bool isSubscriptionActive = false;

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> checkSubscriptionStatus() async {
    if (_userId == null) {
      isSubscriptionActive = false;
      return;
    }

    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('subscription')
          .doc('status')
          .get();

      if (!doc.exists) {
        isSubscriptionActive = false;
        return;
      }

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        isSubscriptionActive = false;
        return;
      }

      // Handle both Timestamp and String date formats
      DateTime? endDate;
      if (data['endDate'] is Timestamp) {
        endDate = (data['endDate'] as Timestamp).toDate();
      } else if (data['endDate'] is String) {
        endDate = DateTime.parse(data['endDate']);
      }

      final bool? active = data['isActive'] as bool?;

      if (endDate == null || active != true) {
        isSubscriptionActive = false;
        return;
      }

      // Set global variable based on whether the subscription is still valid
      isSubscriptionActive = DateTime.now().isBefore(endDate);

      print('Subscription Status Check:');
      print('End Date: $endDate');
      print('Current Date: ${DateTime.now()}');
      print('Is Active: $isSubscriptionActive');
    } catch (e) {
      print('Error checking subscription status: $e');
      isSubscriptionActive = false;
    }
  }

  Stream<bool> subscriptionStatusStream() {
    if (_userId == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('subscription')
        .doc('status')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      // Handle both Timestamp and String date formats
      DateTime? endDate;
      if (data['endDate'] is Timestamp) {
        endDate = (data['endDate'] as Timestamp).toDate();
      } else if (data['endDate'] is String) {
        endDate = DateTime.parse(data['endDate']);
      }

      final bool? active = data['isActive'] as bool?;

      if (endDate == null || active != true) return false;

      return DateTime.now().isBefore(endDate);
    });
  }

  Future<void> _updateSubscriptionStatus(bool status) async {
    if (_userId == null) return;

    try {
      final DateTime now = DateTime.now();
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('subscription')
          .doc('status')
          .set({
        'isActive': status,
        'endDate':
            status ? now.add(const Duration(days: 30)).toIso8601String() : null,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating subscription status: $e');
    }
  }

  Future<void> activateSubscription() async {
    await _updateSubscriptionStatus(true);
    await checkSubscriptionStatus(); // Recheck status after activation
  }
}
