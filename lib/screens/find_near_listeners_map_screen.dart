import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/src/rendering/layer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spotify_project/Business_Logic/Models/user_model.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/Business_Logic/location%20services/location_service.dart';
import 'package:http/http.dart' as http;
import 'package:spotify_project/main.dart';
import 'package:spotify_project/screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spotify_project/widgets/bottom_bar.dart';

class NearListenersMapScreen extends StatefulWidget {
  const NearListenersMapScreen({super.key});

  @override
  State<NearListenersMapScreen> createState() => _NearListenersMapScreenState();
}

class _NearListenersMapScreenState extends State<NearListenersMapScreen> {
  final LocationService _locationService = LocationService();
  final FirestoreDatabaseService _firestoreService = FirestoreDatabaseService();
  Set<Annotation> _annotations = {};
  Map<String, UserModel> _usersData = {};
  static const double TAP_RADIUS = 0.005;
  bool _isVisibleOnMap = true; // Track visibility state

  @override
  void initState() {
    super.initState();
    print('\n📱 Starting Map Screen');
    _fetchAllUsersAndCreateMarkers();
    _fetchCurrentUserVisibility(); // Fetch visibility status
  }

  Future<void> _fetchAllUsersAndCreateMarkers() async {
    try {
      print('\n🔍 Fetching users from database...');
      final users = await _firestoreService.fetchUsersWithLocation();
      print('📊 Total users fetched: ${users.length}');

      // First, let's log all users with location data
      print('\n📍 Users with location data:');
      final usersWithLocation = users
          .where(
              (user) => user.hasValidLocation && user.profilePhotoURL != null)
          .toList();

      if (usersWithLocation.isEmpty) {
        print('❌ No users found with valid location data');
      } else {
        for (final user in usersWithLocation) {
          print('''
🗺️ User: ${user.name ?? 'Unknown'} (${user.userId})
   └─ Location: (${user.latitude}, ${user.longitude})
   └─ Has Profile Photo: ${user.profilePhotoURL != null}''');
        }
      }

      final Set<Annotation> newAnnotations = {};
      print('\n🎯 Creating markers for users with valid data...');

      for (final user in usersWithLocation) {
        try {
          print(
              '\n📌 Processing user: ${user.name ?? 'Unknown'} (${user.userId})');
          final Uint8List markerIcon =
              await _createCustomMarker(user.profilePhotoURL!);

          final annotation = Annotation(
            annotationId: AnnotationId('user_${user.userId}'),
            position: LatLng(user.latitude!, user.longitude!),
            icon: BitmapDescriptor.fromBytes(markerIcon),
          );

          newAnnotations.add(annotation);
          _usersData[user.userId!] = user;
          print('✅ Successfully created marker');
        } catch (e) {
          print('❌ Failed to create marker: $e');
        }
      }

      print('\n📊 Summary:');
      print('   └─ Total users with location: ${usersWithLocation.length}');
      print('   └─ Markers created: ${newAnnotations.length}');

      setState(() {
        _annotations = newAnnotations;
      });
      print('✅ Map updated with ${_annotations.length} markers');
    } catch (e) {
      print('\n❌ Error in _fetchAllUsersAndCreateMarkers:');
      print('   └─ $e');
      print('   └─ ${StackTrace.current}');
    }
  }

  Future<void> _fetchCurrentUserVisibility() async {
    try {
      final userData = await _firestoreService.getUserData();
      if (userData != null) {
        if (userData.isVisibleOnMap == null) {
          // If isVisibleOnMap doesn't exist, set it to true and merge
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userData.userId)
              .set({'isVisibleOnMap': true}, SetOptions(merge: true));
          print(
              '🔄 Updated isVisibleOnMap to true for user: ${userData.userId}');
        }
        setState(() {
          _isVisibleOnMap = userData.isVisibleOnMap ?? true;
        });
      }
    } catch (e) {
      print('Error fetching user visibility: $e');
    }
  }

  Future<void> _updateVisibility(bool newValue) async {
    try {
      // Get current user ID from your auth service
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Update Firestore using set with merge
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
        'isVisibleOnMap': newValue,
      }, SetOptions(merge: true));

      setState(() {
        _isVisibleOnMap = newValue;
        // Refresh the state of the screen
        _fetchAllUsersAndCreateMarkers(); // Refresh markers based on new visibility
      });
    } catch (e) {
      print('Error updating visibility: $e');
    }
  }

  void _handleMapTap(LatLng tapLocation) {
    print('Map tapped at: ${tapLocation.latitude}, ${tapLocation.longitude}');

    // Check each annotation to see if tap is within radius
    for (final annotation in _annotations) {
      if (isWithinMarkerRadius(tapLocation, annotation.position)) {
        // Extract userId from annotationId (remove 'user_' prefix)
        final userId = annotation.annotationId.value.substring(5);
        final user = _usersData[userId];

        if (user != null) {
          print('Found matching marker for user: ${user.userId}');
          _showProfileBottomSheet(context, user);
        }
        break; // Exit after finding the first matching marker
      }
    }
  }

  bool isWithinMarkerRadius(LatLng tapLocation, LatLng markerLocation) {
    final latDiff = (tapLocation.latitude - markerLocation.latitude).abs();
    final lngDiff = (tapLocation.longitude - markerLocation.longitude).abs();
    final distance = sqrt(latDiff * latDiff + lngDiff * lngDiff);
    print('Distance from marker: $distance');
    return distance < TAP_RADIUS;
  }

  Future<void> _showProfileBottomSheet(
      BuildContext context, UserModel user) async {
    if (!mounted) return;

    print('Opening modal bottom sheet for user: ${user.userId}');
    await showModalBottomSheet<dynamic>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext bc) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: ProfileScreen(
            key: UniqueKey(),
            uid: user.userId!,
          ),
        );
      },
    ).whenComplete(() {
      print('Modal bottom sheet closed');
    });
  }

  Future<Uint8List> _createCustomMarker(String imageUrl) async {
    print('🎨 Starting to create custom marker from URL: $imageUrl');
    final Completer<Uint8List> completer = Completer();

    try {
      print('📥 Fetching image from URL');
      final http.Response response = await http.get(Uri.parse(imageUrl));
      final Uint8List bytes = response.bodyBytes;
      print('✅ Image downloaded successfully');

      print('🔄 Processing image');
      final ui.Codec codec = await ui.instantiateImageCodec(bytes,
          targetWidth: 150, targetHeight: 150);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      print('✅ Image processed successfully');

      print('🎨 Drawing custom marker');
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = const Size(150, 150);

      final painter = _ImagePainter(image);
      painter.paint(canvas, size);

      final picture = recorder.endRecording();
      final img =
          await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      print('✅ Custom marker created successfully');

      completer.complete(byteData!.buffer.asUint8List());
    } catch (e) {
      print('❌ Error creating custom marker: $e');
      print('Stack trace: ${StackTrace.current}');
      completer.completeError(e);
    }

    return completer.future;
  }

  void _showVisibilityBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Be Visible on Map',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: _isVisibleOnMap,
                      onChanged: (bool value) {
                        setState(() {
                          _isVisibleOnMap = value;
                        });
                        _updateVisibility(value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _isVisibleOnMap
                      ? 'Other users can see your location on the map'
                      : 'Your location is hidden from other users',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🔄 Build called, annotations count: ${_annotations.length}');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Listeners near you',
          style: GoogleFonts.poppins(),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.of(context)
                .push(CupertinoPageRoute(builder: (context) => Home()));
          },
        ),
      ),
      body: Stack(
        children: [
          _annotations.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : AppleMap(
                  initialCameraPosition: CameraPosition(
                    target: _annotations.first.position,
                    zoom: 13.0,
                  ),
                  annotations: _annotations,
                  zoomGesturesEnabled: true,
                  onTap: _handleMapTap,
                ),
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: _showVisibilityBottomSheet,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.visibility,
                  color: _isVisibleOnMap ? Colors.blue : Colors.grey,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(selectedIndex: 2),
    );
  }
}

class _ImagePainter extends CustomPainter {
  final ui.Image image;

  _ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final borderPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw shadow
    canvas.drawCircle(center, radius, shadowPaint);

    // Draw border
    canvas.drawCircle(center, radius, borderPaint);

    // Draw image
    final rect = Rect.fromCircle(center: center, radius: radius - 2);
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rect,
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
