import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/business/Spotify_Logic/constants.dart';
import 'package:spotify_project/business/business_logic.dart';
import 'package:spotify_project/business/subscription_service.dart';
import 'package:spotify_project/business/payment_service/payment_service.dart';
import 'package:spotify_project/screens/chat_screen.dart';
import 'package:spotify_project/screens/landing_screen.dart';
import 'package:spotify_project/screens/message_box.dart';
import 'package:spotify_project/screens/test_screens/test_screen_for_search.dart';
import 'package:spotify_project/widgets/bottom_bar.dart';
import 'package:spotify_project/widgets/build_current_track_widget.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'screens/quick_match_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     switch (task) {
//       case 'getUserDatasToMatch':
//         final firestoreService = FirestoreDatabaseService();
//         // You'll need to implement a way to get the current song name

//         String? currentSongName =
//             await firestoreService.returnCurrentlyListeningMusicName();
//         // await firestoreService.getUserDatasToMatch(currentSongName, true);
//         firestoreService.updateActiveStatus();
//         break;
//     }
//     return Future.value(true);
//   });
// }

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await PaymentService().initialize();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      name: "musee",
      options: const FirebaseOptions(
        apiKey: "AIzaSyDsdh0mRQyMiH3bgZbBDPr6h880C39al0g",
        appId: "1:985372741706:ios:80007bd7b8a5a5daff96b3",
        messagingSenderId: "985372741706",
        projectId: "musee-285eb",
        storageBucket: "gs://musee-285eb.appspot.com",
      ),
    );
  }

  await initializeFirebaseMessaging();

  // Initialize Spotify connection
  final businessLogic = BusinessLogic();

  try {
    // Only try to get/refresh token if user is logged in
    if (FirebaseAuth.instance.currentUser != null) {
      final tokenDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('tokens')
          .doc('spotify')
          .get();

      if (tokenDoc.exists) {
        // We have a token, check if it's still valid
        final lastUpdated =
            (tokenDoc.data()?['lastUpdated'] as Timestamp).toDate();
        if (DateTime.now().difference(lastUpdated).inMinutes < 50) {
          // Token still valid, use it
          accessToken = tokenDoc.data()?['tokens'];
        } else {
          // Token expired, get new one
          accessToken = await SpotifySdk.getAccessToken(
              clientId: '32a50962636143748e6779e2f604e07b',
              redirectUrl: 'com-developer-spotifyproject://callback',
              scope: 'app-remote-control '
                  'user-modify-playback-state '
                  'playlist-read-private '
                  'user-library-read '
                  'playlist-modify-public '
                  'user-read-currently-playing '
                  'user-top-read');

          // Update token in Firebase
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection('tokens')
              .doc('spotify')
              .set({
            'tokens': accessToken,
            'lastUpdated': DateTime.now(),
          });
        }
      }
      // If token doc doesn't exist, we'll get it when user navigates to search screen
    }

    // await businessLogic.connectToSpotifyRemote();
  } catch (e) {
    print('Error initializing Spotify: $e');
  }

  final subscriptionService = SubscriptionService();
  await subscriptionService.checkSubscriptionStatus();

  runApp(MyApp(businessLogic: businessLogic));
}

Future<void> initializeFirebaseMessaging() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request all permissions for notifications
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
    criticalAlert: true, // For critical notifications
    announcement: true,
  );

  // Configure foreground notification presentation options
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // Add iOS settings
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  // Combine both platform settings
  const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (details) {
      // Handle notification tap
      print('Notification clicked');
    },
  );

  // Create high-importance notification channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'chat_messages',
    'Chat Messages',
    description: 'Notifications for new chat messages',
    importance: Importance.max,
    enableVibration: true,
    playSound: true,
    showBadge: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Get initial token
  String? initialToken = await FirebaseMessaging.instance.getToken();
  print('Initial FCM Token: $initialToken');

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }

    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });

  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null) {
      final token = await FirebaseMessaging.instance.getToken();
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
      }
    }
  });

  FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
    }
  });
}

class MyApp extends StatelessWidget {
  var _currentUser = FirebaseAuth.instance.currentUser;
  final BusinessLogic businessLogic;
  MyApp({Key? key, required this.businessLogic}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(720, 1080),
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Musee',
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFFE57373),
          scaffoldBackgroundColor: const Color(0xFF121212),
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
              .apply(bodyColor: Colors.white),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFE57373),
            secondary: Color(0xFFFFD54F),
          ),
        ),
        // Check if user is signed in
        home: _currentUser != null ? MessageScreen() : LandingPage(),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({
    Key? key,
  }) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final FirestoreDatabaseService firestoreDatabaseService =
      FirestoreDatabaseService();

  @override
  void initState() {
    super.initState();

    // Dismiss keyboard when entering Home screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });

    // Add check for authentication status
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null && mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LandingPage()));
        // Alternative if you don't have named routes:
        // Navigator.of(context).pushReplacement(
        //   MaterialPageRoute(builder: (context) => LandingScreen()),
        // );
      }
    });

    firestoreDatabaseService.updateActiveStatus();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dismiss keyboard whenever Home is rebuilt
    FocusManager.instance.primaryFocus?.unfocus();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      bottomNavigationBar: BottomBar(selectedIndex: 0),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[900]!,
                Colors.black,
                Colors.grey[900]!,
              ],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05,
              vertical: MediaQuery.of(context).size.height * 0.03,
            ),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.04),
              _buildQuickMatchButton(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              FutureBuilder<bool>(
                future: SpotifySdk.isSpotifyAppActive,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.hasData && snapshot.data == true) {
                    return const BuildCurrentTrackWidget();
                  } else {
                    return Text(
                      'We see that Spotify is not installed in your phone. You can still use quick match! If you want better experience we strongly recommend installing from App Store. Have fun! /n If you think we have made a mistake and you have actually Spotify, please restart the app.',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMatchButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const QuickMatchesScreen()));
      },
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 1, end: 1),
        duration: const Duration(milliseconds: 200),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.height * 0.03,
                horizontal: MediaQuery.of(context).size.width * 0.05,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                    MediaQuery.of(context).size.width * 0.04),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF9333EA),
                    Color(0xFFEC4899),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Colors.white70],
                        ).createShader(bounds),
                        child: Text(
                          'Quick Match',
                          style: GoogleFonts.poppins(
                            fontSize: MediaQuery.of(context).size.width * 0.06,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.005),
                      Text(
                        'Find others listening to your music',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.035,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width * 0.04),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFF9333EA),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width * 0.06,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
