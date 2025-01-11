import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spotify_project/Business_Logic/Models/user_model.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/business/Spotify_Logic/constants.dart';
import 'package:spotify_project/business/business_logic.dart';
import 'package:spotify_project/business/payment_service/payment_screen.dart';
import 'package:spotify_project/business/subscription_service.dart';
import 'package:spotify_project/business/payment_service/payment_service.dart';
import 'package:spotify_project/god%20mode/firebase_god_mode.dart';
import 'package:spotify_project/screens/find_near_listeners_map_screen.dart';
import 'package:spotify_project/screens/landing_screen.dart';
import 'package:spotify_project/screens/message_box.dart';
import 'package:spotify_project/screens/own_profile_screens_for_clients.dart';
import 'package:spotify_project/screens/premium_subscription_screen.dart';
import 'package:spotify_project/screens/profile_settings.dart';
import 'package:spotify_project/screens/register_page.dart';
import 'package:spotify_project/screens/steppers.dart';
import 'package:spotify_project/screens/test_screens/test_screen_for_search.dart';
import 'package:spotify_project/widgets/bottom_bar.dart';
import 'package:spotify_project/widgets/build_current_track_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screens/quick_match_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final businessLogic = BusinessLogic();

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
      options: FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY']!,
        appId: dotenv.env['FIREBASE_APP_ID']!,
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
        projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
      ),
    );
  }

  await initializeFirebaseMessaging();

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
  String? initialToken = await FirebaseMessaging.instance.getAPNSToken();
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
      final token = await FirebaseMessaging.instance.getAPNSToken();
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
  Future<bool> _getIfSteppersFinished() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return false; // Return false if there is no current user
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (userDoc.exists && userDoc.data() != null) {
      final data = userDoc.data();
      if (data != null && data.containsKey('isSteppersFinished')) {
        return data['isSteppersFinished'];
      }
    }
    return false;
  }

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
        home: FutureBuilder<bool>(
          future: _getIfSteppersFinished(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final isSteppersFinished = snapshot.data ?? false;
              if (FirebaseAuth.instance.currentUser == null) {
                return RegisterPage();
              } else if (isSteppersFinished) {
                return Home();
              } else {
                return OnboardingSlider();
              }
            }
          },
        ),
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

  // Use ValueNotifier for each playlist
  final Map<String, ValueNotifier<int>> _currentListeners = {
    'playlist1': ValueNotifier<int>(10),
    'playlist2': ValueNotifier<int>(8),
    'playlist3': ValueNotifier<int>(15),
  };

  Timer? _modalTimer;
  int _modalShowCount = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null && mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LandingPage()));
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

    _startRandomUpdates();

    _modalTimer = Timer.periodic(const Duration(hours: 12), (timer) {
      if (mounted && _modalShowCount < 2) {
        _showModalBottomSheetForHelp();
        _modalShowCount++;
      }
    });

    FirebaseFirestore.instance
        .collection('remote_handle')
        .doc('spotify')
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        bool connectToRemote = documentSnapshot.get('connectToRemote');
        if (connectToRemote) {
          businessLogic.connectToSpotifyRemote();
        }
      } else {
        print('Document does not exist on the database');
      }
    }).catchError((error) {
      print('Error checking remote handle: $error');
    });
  }

  void _startRandomUpdates() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _currentListeners['playlist1']!.value = Random().nextInt(15) + 5;
        print('Updated playlist1: ${_currentListeners['playlist1']!.value}');
      }
    });

    Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted) {
        _currentListeners['playlist2']!.value = Random().nextInt(15) + 5;
        print('Updated playlist2: ${_currentListeners['playlist2']!.value}');
      }
    });

    Timer.periodic(const Duration(seconds: 7), (timer) {
      if (mounted) {
        _currentListeners['playlist3']!.value = Random().nextInt(15) + 5;
        print('Updated playlist3: ${_currentListeners['playlist3']!.value}');
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _modalTimer?.cancel();
    firestoreDatabaseService.updateActiveStatus();
    super.dispose();
  }

  void _showModalBottomSheetForHelp() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Container(
              height: 500.h,
              color: const Color.fromARGB(255, 0, 0, 0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Having issues with Spotify integration?',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Add your onPressed code here
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Try to refresh here',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(
                            width: 30.w,
                          ),
                          Image.network(
                            'https://storage.googleapis.com/pr-newsroom-wp/1/2023/05/Spotify_Full_Logo_RGB_Green.png',
                            height: 60.w, // Adjust the height as needed
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                    SizedBox(height: 30.h),
                    const Text(
                      'or',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 30.h),
                    const Text(
                      'Reach out to us on Instagram:',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 5),
                    const Text(
                      '@imharveyjones',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      // ********************************* DRAWER *************************************
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            SizedBox(
              height: 100.h,
            ),
            ListTile(
              leading: Image.network(
                'https://storage.googleapis.com/pr-newsroom-wp/1/2023/05/Spotify_Primary_Logo_RGB_Green.png',
                width: 30,
                height: 30,
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Sync Now.',
                    style: GoogleFonts.poppins(
                      fontSize: 33.sp,
                    ),
                  ),
                  SizedBox(width: 20.w),
                ],
              ),
              onTap: () {
                businessLogic.connectToSpotifyRemote();
              },
            ),
            ListTile(
              leading: Icon(Icons.message),
              title: Text(
                'Messages',
                style: GoogleFonts.poppins(fontSize: 33.sp),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => MessageScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text(
                'Settings',
                style: GoogleFonts.poppins(fontSize: 33.sp),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => ProfileSettings()),
                );
              },
            ),
            ListTile(
              leading: Image.network(
                'https://img.icons8.com/?size=100&id=16713&format=png&color=000000',
                height: 47.h,
              ),
              title: Text(
                'Contact.',
                style: GoogleFonts.poppins(fontSize: 33.sp),
              ),
              onTap: () {
                launchURL() async {
                  const url = 'https://wa.me/48578115474';
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                }

                launchURL();
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(
          'Musee',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
      ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 50.w,
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              Row(
                children: [
                  Expanded(child: _buildQuickMatchButton()),
                  SizedBox(width: 16),
                  Expanded(child: _buildBoostButton()),
                ],
              ),
              SizedBox(height: 15.h),
              _buildCarouselSlider(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              _buildPlaylistContainer(
                  'Arctic Monkeys',
                  'Rock your match.',
                  'https://i.scdn.co/image/ab6761610000e5eb7da39dea0a72f581535fb11f',
                  _currentListeners['playlist2']!,
                  '1cXjwobmSdiIuVvUnctPgV?si=874760cf1c59448f',
                  'https://open.spotify.com/playlist/1cXjwobmSdiIuVvUnctPgV?si=874760cf1c59448f'),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              _buildPlaylistContainer(
                  'The Strokes',
                  'Find the tempo.',
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/The_Strokes_by_Roger_Woolman.jpg/1200px-The_Strokes_by_Roger_Woolman.jpg',
                  _currentListeners['playlist3']!,
                  '7eWCtUruTVp5uRFLgzDMEz?si=0c6857aa9a98415b',
                  'https://open.spotify.com/playlist/7eWCtUruTVp5uRFLgzDMEz?si=0c6857aa9a98415b'),
              FutureBuilder<bool>(
                future: SpotifySdk.isSpotifyAppActive,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  if (snapshot.hasData && snapshot.data == true) {
                    return const BuildCurrentTrackWidget();
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMatchButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
        border: Border.all(
          color: const Color(0xFF6366F1),
          width: 2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withOpacity(0.2),
            const Color(0xFF9333EA).withOpacity(0.2),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const QuickMatchesScreen()));
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height * 0.03,
              horizontal: MediaQuery.of(context).size.width * 0.05,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
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
                    ],
                  ),
                ),
                Icon(
                  Icons.music_note,
                  color: const Color(0xFF6366F1),
                  size: MediaQuery.of(context).size.width * 0.06,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoostButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700).withOpacity(0.2),
            const Color(0xFFFFA500).withOpacity(0.2),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SubscribePremiumScreen()));
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height * 0.05 + 2,
              horizontal: MediaQuery.of(context).size.width * 0.05,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ).createShader(bounds),
                        child: Text(
                          'Boost',
                          style: GoogleFonts.poppins(
                            fontSize: MediaQuery.of(context).size.width * 0.06,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.flash_on,
                  color: const Color(0xFFFFD700),
                  size: MediaQuery.of(context).size.width * 0.06,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistContainer(String title, String subtitle, String imageUrl,
      ValueNotifier<int> listeners, String spotifyUri, String playlistURL) {
    return FutureBuilder(
      future: firestoreDatabaseService.hasSpotify(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        return GestureDetector(
          onTap: () async {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final tokenDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('tokens')
                  .doc('spotify')
                  .get();

              if (tokenDoc.exists) {
                // User has a Spotify token, attempt to play the URI
                try {
                  bool isConnected = await SpotifySdk.isSpotifyAppActive;
                  if (snapshot.data == true) {
                    await SpotifySdk.connectToSpotifyRemote(
                      clientId: '32a50962636143748e6779e2f604e07b',
                      redirectUrl: 'com-developer-spotifyproject://callback',
                    );
                    await SpotifySdk.play(
                      spotifyUri: spotifyUri,
                    );
                  } else {
                    // No token, launch the URL
                    if (await canLaunch(playlistURL)) {
                      await launch(playlistURL);
                    } else {
                      throw 'Could not launch $playlistURL';
                    }
                  }
                } catch (error) {
                  print('Error playing Spotify URI: $error');
                }
              }
            }
          },
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 1, end: 1),
            duration: const Duration(milliseconds: 200),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.25,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                        MediaQuery.of(context).size.width * 0.04),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        MediaQuery.of(context).size.width * 0.04),
                    child: Stack(
                      children: [
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: MediaQuery.of(context).size.height * 0.02,
                          left: MediaQuery.of(context).size.width * 0.04,
                          right: MediaQuery.of(context).size.width * 0.04,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width * 0.03),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: EdgeInsets.all(
                                    MediaQuery.of(context).size.width * 0.04),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      MediaQuery.of(context).size.width * 0.03),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.06,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.005),
                                    Text(
                                      subtitle,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.04,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Listener Count Circle
                        Positioned(
                          bottom: 35.h,
                          right: 65.w,
                          child: ValueListenableBuilder<int>(
                            valueListenable: listeners,
                            builder: (context, value, child) {
                              return Container(
                                width: MediaQuery.of(context).size.width * 0.07,
                                height:
                                    MediaQuery.of(context).size.width * 0.07,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255)
                                          .withOpacity(0.2),
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    '$value',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.03,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeadPlaylistContainer(
      String title,
      String subtitle,
      String imageUrl,
      ValueNotifier<int> listeners,
      String spotifyUri,
      String playlistURL) {
    return FutureBuilder(
        future: firestoreDatabaseService.hasSpotify(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }
          return GestureDetector(
            onTap: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final tokenDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('tokens')
                    .doc('spotify')
                    .get();

                if (tokenDoc.exists) {
                  // User has a Spotify token, attempt to play the URI
                  try {
                    bool isConnected = await SpotifySdk.isSpotifyAppActive;
                    if (isConnected) {
                      await SpotifySdk.connectToSpotifyRemote(
                        clientId: '32a50962636143748e6779e2f604e07b',
                        redirectUrl: 'com-developer-spotifyproject://callback',
                      );
                      await SpotifySdk.play(
                        spotifyUri: spotifyUri,
                      );
                    }
                  } catch (error) {
                    print('Error playing Spotify URI: $error');
                  }
                } else {
                  // No token, launch the URL
                  if (await canLaunch(playlistURL)) {
                    await launch(playlistURL);
                  } else {
                    throw 'Could not launch $playlistURL';
                  }
                }
              }
            },
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 1, end: 1),
              duration: const Duration(milliseconds: 200),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    height: MediaQuery.of(context).size.height *
                        0.25, // Responsive height
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width * 0.04),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width * 0.04),
                      child: Stack(
                        children: [
                          // Background Image
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          // Gradient Overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                          // Frosted Glass Info Container
                          Positioned(
                            bottom: MediaQuery.of(context).size.height * 0.02,
                            left: MediaQuery.of(context).size.width * 0.04,
                            right: MediaQuery.of(context).size.width * 0.04,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  MediaQuery.of(context).size.width * 0.03),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: EdgeInsets.all(
                                      MediaQuery.of(context).size.width * 0.04),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                        MediaQuery.of(context).size.width *
                                            0.03),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.06,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.005),
                                      Text(
                                        subtitle,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.04,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Listener Count and Profile Circles
                          Positioned(
                            bottom: 35.h,
                            right: 65.w,
                            child: ValueListenableBuilder<int>(
                              valueListenable: listeners,
                              builder: (context, value, child) {
                                return Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.07,
                                  height:
                                      MediaQuery.of(context).size.width * 0.07,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        const Color.fromARGB(255, 255, 255, 255)
                                            .withOpacity(0.2),
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$value',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.03,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        });
  }

  Widget _buildCarouselSlider() {
    return Column(
      children: [
        // Add the chip button here
        SizedBox(height: 15.h), // Space between carousel and button
        CarouselSlider(
          options: CarouselOptions(
            height: MediaQuery.of(context).size.height * 0.3,
            autoPlay: false,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            viewportFraction: 0.8,
          ),
          items: [
            _buildHeadPlaylistContainer(
              'Sanah',
              'Listen and match now.',
              'https://lh3.googleusercontent.com/2Bj5TXHtxa_4cwpwXcX_7gk01u5j75DF3wHfkwVxjlbtZiqqU6MWBMeviAJZnwS7TKEZA32xl12oXhI=w2880-h1200-p-l90-rj',
              _currentListeners['playlist3']!,
              '37i9dQZF1DZ06evO0t5nsR',
              'https://open.spotify.com/playlist/37i9dQZF1DZ06evO0t5nsR',
            ),
            _buildHeadPlaylistContainer(
              'Sobel',
              'Feel the heat.',
              'https://i.wpimg.pl/1200x/filerepo.grupawp.pl/api/v1/display/embed/3307d813-3714-41c9-9663-83cf69ccdd09',
              _currentListeners['playlist3']!,
              '56VhOZOF6hwqrbNYwkmcsH',
              'https://open.spotify.com/artist/56VhOZOF6hwqrbNYwkmcsH',
            ),
            _buildHeadPlaylistContainer(
              "90's Indie",
              'Find the tempo.',
              'https://media.npr.org/assets/img/2014/04/04/42-16783402_custom-5d1259268e5d2bc96bc5aec1dc07a17917937ef8.jpg',
              _currentListeners['playlist3']!,
              '7pDYHhlAulEmE68iW83zU1',
              'https://open.spotify.com/playlist/7pDYHhlAulEmE68iW83zU1',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNearbyListenersButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => const NearListenersMapScreen()),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 5.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.purpleAccent, Color.fromARGB(255, 154, 191, 255)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'Near me',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.map,
              color: Colors.white,
              size: 40.sp,
            ),
          ],
        ),
      ),
    );
  }
}
