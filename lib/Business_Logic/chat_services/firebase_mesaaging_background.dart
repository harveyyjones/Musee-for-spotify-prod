// lib/services/notification_service.dart

import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();
  await NotificationService.backgroundMessageHandler(message);
}

class NotificationService with WidgetsBindingObserver {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _shouldHandleMessages = false; // Flag to control message handling

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Update the flag based on app lifecycle state
    _shouldHandleMessages = state != AppLifecycleState.resumed;
  }

  Future<void> initialize() async {
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission for iOS devices
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    // Set presentation options for iOS to not show alerts by default
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );

    // Configure local notifications
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentSound: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
    );
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);

    // Enable the onMessage listener to handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Get and save FCM token
    final token = await _fcm.getAPNSToken();
    if (token != null) {
      await _saveFcmToken(token);
    }

    // Listen for token refreshes
    _fcm.onTokenRefresh.listen(_saveFcmToken);
  }

  // Method to enable or disable message handling
  void setShouldHandleMessages(bool shouldHandle) {
    _shouldHandleMessages = shouldHandle;
  }

  Future<void> _saveFcmToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print("Received foreground message: ${message.messageId}");

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription: 'Notifications for new chat messages',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.active,
      ),
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Message',
      message.notification?.body,
      notificationDetails,
      payload: message.data['senderId'],
    );
  }

  Future<String?> getRecipientFcmToken(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['fcmToken'];
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> sendTestNotification() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Create the notification document in Firestore
      final notificationRef =
          _firestore.collection('message_notifications').doc();
      await notificationRef.set({
        'title': 'Test Message Notification',
        'body': 'This is a test message notification',
        'senderUid': currentUser.uid,
        'receiverUid': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'test_message'
      });
      await Future.delayed(const Duration(seconds: 1));

      // Show local notification
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_messages',
          'Chat Messages',
          channelDescription: 'Notifications for new chat messages',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
      );

      print('Showing local notification...');
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.hashCode,
        'Buraya bak lan orospu evladi!',
        'Seni bekleyen 21 eslesmen var! ',
        notificationDetails,
      );
      print('Local notification shown');

      // Add delay and cleanup
      await Future.delayed(const Duration(seconds: 2));
      await notificationRef.delete();
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  static Future<void> backgroundMessageHandler(RemoteMessage message) async {}
}
