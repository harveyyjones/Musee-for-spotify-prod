import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:spotify_project/business/Spotify_Logic/Models/top_10_track_model.dart';
import 'package:spotify_project/business/Spotify_Logic/constants.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BusinessLogic {
  final Logger _logger = Logger(
    //filter: CustomLogFilter(), // custom logfilter can be used to have logs in release mode
    printer: PrettyPrinter(
      methodCount: 2, // number of method calls to be displayed
      errorMethodCount: 8, // number of method calls if stacktrace is provided
      lineLength: 120, // width of the output
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      printTime: true,
    ),
  );

  void setStatus(String code, {String? message}) {
    var text = message ?? '';
    _logger.i('$code$text');
  }

  Future<void> checkIfAppIsActive(BuildContext context) async {
    try {
      var isActive = await SpotifySdk.isSpotifyAppActive;
      final snackBar = SnackBar(
          content: Text(isActive
              ? 'Spotify app connection is active (currently playing)'
              : 'Spotify app connection is not active (currently not playing)'));

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  //********************************************************** AŞAĞISI YALNIZCA BUSINESS LOGIC.  ***************************************************************** */

// API'den veri çekme izni alan fonksiyon.

// 1. First get both tokens (one-time user approval)
  Future<void> getInitialTokens(
      String clientId, String clientSecret, String redirectUrl) async {
    try {
      // Check if we have tokens
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('tokens')
          .doc('spotify')
          .get();

      if (!doc.exists || doc.data()?['tokens'] == null) {
        // First time user - needs to authenticate once
        accessToken = await SpotifySdk.getAccessToken(
            clientId: dotenv.env['SPOTIFY_CLIENT_ID']!,
            redirectUrl: dotenv.env['SPOTIFY_REDIRECT_URL']!,
            scope: 'app-remote-control '
                'user-modify-playback-state '
                'playlist-read-private '
                'user-library-read '
                'playlist-modify-public '
                'user-read-currently-playing '
                'user-top-read');

        // Store token in Firebase
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
      var _existingAccesToken;
      // Get token for use
      _existingAccesToken = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('tokens')
          .doc('spotify')
          .get()
          .then((doc) => doc.data()?['tokens'] as String?);
    } catch (e) {
      print('Error initializing tokens: $e');
    }
  }

// 2. Then use this to refresh when needed
  Future<String> refreshToken(String clientId, String clientSecret) async {
    try {
      // Get refresh token from Firebase
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('tokens')
          .doc('spotify')
          .get();

      final refreshToken = doc.data()?['refreshToken'];

      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': clientId,
          'client_secret': clientSecret,
        },
      );

      if (response.statusCode == 200) {
        final tokens = jsonDecode(response.body);
        // Update access token in Firebase
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('tokens')
            .doc('spotify')
            .update({
          'accessToken': tokens['access_token'],
          'lastUpdated': DateTime.now(),
        });

        return tokens['access_token'];
      } else {
        throw Exception('Failed to refresh token');
      }
    } catch (e) {
      print('Error refreshing token: $e');
      throw e;
    }
  }

  Future<String> getValidToken(String clientId, String clientSecret) async {
    try {
      // Get tokens from Firebase
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('tokens')
          .doc('spotify')
          .get();

      print('Firebase doc data: ${doc.data()}');

      // Check if doc exists and has data
      if (!doc.exists || doc.data() == null) {
        print('No token document found in Firebase');
        await getInitialTokens(
            clientId, clientSecret, 'com-developer-spotifyproject://callback');
        throw Exception('No token document found');
      }

      final data = doc.data()!;

      // Check if we have lastUpdated and tokens fields
      if (!data.containsKey('lastUpdated') || !data.containsKey('tokens')) {
        print('Missing required fields');
        throw Exception('Invalid token document structure');
      }

      final lastUpdated = (data['lastUpdated'] as Timestamp).toDate();
      final token =
          data['tokens'] as String; // Changed from accessToken to tokens

      print('Token from Firebase: $token');
      print('Last Updated: $lastUpdated');

      // If token exists and is not expired
      if (DateTime.now().difference(lastUpdated).inMinutes < 50) {
        print('Using existing token');
        return token;
      }

      print('Token expired or null, attempting refresh');
      // If token is expired, refresh it
      return await refreshToken(clientId, clientSecret);
    } catch (e) {
      print('Error getting valid token: $e');
      throw e;
    }
  }
// Add this function to check and refresh token when needed

  Future getPlayerState() async {
    try {
      return await SpotifySdk.getPlayerState();
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future getCrossfadeState() async {
    // En sikimde olmayan fonksiyon.
    try {
      var crossfadeStateValue = await SpotifySdk.getCrossFadeState();
      // setState(() {
      //   crossfadeState = crossfadeStateValue;
      // });
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> queue() async {
    try {
      await SpotifySdk.queue(
          spotifyUri: 'spotify:track:58kNJana4w5BIjlZE2wq5m');
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> toggleRepeat() async {
    try {
      await SpotifySdk.toggleRepeat();
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> setRepeatMode(RepeatMode repeatMode) async {
    try {
      await SpotifySdk.setRepeatMode(
        repeatMode: repeatMode,
      );
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> setShuffle(bool shuffle) async {
    try {
      await SpotifySdk.setShuffle(
        shuffle: shuffle,
      );
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> toggleShuffle() async {
    try {
      await SpotifySdk.toggleShuffle();
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> play() async {
    try {
      await SpotifySdk.play(spotifyUri: 'spotify:track:58kNJana4w5BIjlZE2wq5m');
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> pause() async {
    try {
      await SpotifySdk.pause();
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> resume() async {
    try {
      await SpotifySdk.resume();
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> skipNext() async {
    try {
      await SpotifySdk.skipNext();
      print("Skip to the next song");
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> skipPrevious() async {
    try {
      await SpotifySdk.skipPrevious();
      print("Skip to the previous song.");
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  // Belirtilen dakikaya barı fırlatan fonksiyon.
  Future<void> seekTo() async {
    try {
      await SpotifySdk.seekTo(positionedMilliseconds: 20000);
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  // Belirtilen sürede barı ileri saran fonksiyon.
  Future<void> seekToRelative() async {
    try {
      await SpotifySdk.seekToRelativePosition(relativeMilliseconds: 20000);
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  Future<void> addToLibrary() async {
    try {
      await SpotifySdk.addToLibrary(
          spotifyUri: 'spotify:track:58kNJana4w5BIjlZE2wq5m');
    } on PlatformException catch (e) {
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setStatus('not implemented');
    }
  }

  bool _loading = false;
  Future<void> connectToSpotifyRemote() async {
    BusinessLogic _businessLogic = BusinessLogic();
    try {
      _loading = true;

      var result = await SpotifySdk.connectToSpotifyRemote(
        clientId: dotenv.env['SPOTIFY_CLIENT_ID']!,
        redirectUrl: dotenv.env['SPOTIFY_REDIRECT_URL']!,
        scope: 'app-remote-control '
            'user-modify-playback-state '
            'playlist-read-private '
            'user-library-read '
            'playlist-modify-public '
            'user-read-currently-playing '
            'user-top-read '
            'user-read-recently-played',
      ).timeout(Duration(seconds: 10), onTimeout: () {
        _loading = false;
        _businessLogic.setStatus('Connection timed out');
        return false; // Return false to indicate failure
      });

      _businessLogic.setStatus(result
          ? 'connect to spotify successful'
          : 'connect to spotify failed');

      // Log the connection status in Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .set({
        'hasSpotify': result,
      }, SetOptions(merge: true));

      if (result) {
        // Obtain the access token
        accessToken = await SpotifySdk.getAccessToken(
          clientId: dotenv.env['SPOTIFY_CLIENT_ID']!,
          redirectUrl: dotenv.env['SPOTIFY_REDIRECT_URL']!,
          scope: 'app-remote-control '
              'user-modify-playback-state '
              'playlist-read-private '
              'user-library-read '
              'playlist-modify-public '
              'user-read-currently-playing '
              'user-top-read '
              'user-read-recently-played',
        );

        // Store token in Firebase
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
      _loading = false;
    } on PlatformException catch (e) {
      _loading = false;
      _businessLogic.setStatus(e.code, message: e.message);
      // Log the failure in Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .set({
        'hasSpotify': false,
      }, SetOptions(merge: true));
    } on MissingPluginException {
      _loading = false;
      _businessLogic.setStatus('not implemented');
      // Log the failure in Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .set({
        'hasSpotify': false,
      }, SetOptions(merge: true));
    }
  }

  Future<List<Map<String, dynamic>>?> getTopArtistsFromFirebase(String uid,
      {bool isForProfileScreen = false}) async {
    try {
      accessToken = await SpotifySdk.getAccessToken(
          clientId: dotenv.env['SPOTIFY_CLIENT_ID']!,
          redirectUrl: dotenv.env['SPOTIFY_REDIRECT_URL']!,
          scope: 'app-remote-control '
              'user-modify-playback-state '
              'playlist-read-private '
              'user-library-read '
              'playlist-modify-public '
              'user-read-currently-playing '
              'user-top-read '
              'user-read-recently-played');
    } catch (e) {
      print('Error fetching top artists: $e');
      return null;
    }
  }

  Future<List<SpotifyTrackFromSpotify>?> getTopTracksFromFirebase(String uid,
      {bool isForProfileScreen = false}) async {
    try {
      getInitialTokens(
          dotenv.env['SPOTIFY_CLIENT_ID']!,
          dotenv.env['SPOTIFY_CLIENT_SECRET']!,
          dotenv.env['SPOTIFY_REDIRECT_URL']!);
    } catch (e) {
      print('Error fetching top tracks: $e');
      return null;
    }
  }
}
