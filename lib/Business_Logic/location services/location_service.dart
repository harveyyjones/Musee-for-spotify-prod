import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Position> getCurrentLocation(String userId) async {
    try {
      final position = await _determinePosition();

      // Update Firestore with location and visibility using merge
      await _firestore.collection('users').doc(userId).set({
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'isVisibleOnMap': true, // Set initial visibility to true
      }, SetOptions(merge: true)); // Using merge to preserve other data

      print('✅ Updated location and visibility for user: $userId');
      print('   └─ Location: (${position.latitude}, ${position.longitude})');

      return position;
    } catch (e) {
      print('❌ Error updating location and visibility: $e');
      throw e;
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied';
    }

    return await Geolocator.getCurrentPosition();
  }
}
