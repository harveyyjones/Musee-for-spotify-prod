import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spotify_project/business/Spotify_Logic/constants.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_project/business/Spotify_Logic/Models/recently_played_tracks_model.dart';

class SpotifyServiceForRecentlyPlayedTracks {
  static const String _baseUrl = 'https://api.spotify.com/v1';
  // String? _accessToken;

  // Singleton pattern
  static final SpotifyServiceForRecentlyPlayedTracks _instance =
      SpotifyServiceForRecentlyPlayedTracks._internal();

  factory SpotifyServiceForRecentlyPlayedTracks() {
    return _instance;
  }

  SpotifyServiceForRecentlyPlayedTracks._internal();

  Future<void> _getValidToken() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('Error: User ID is null.');
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc('spotify')
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['tokens'] != null) {
          final lastUpdated = (data['lastUpdated'] as Timestamp).toDate();
          print('Token last updated: $lastUpdated');
          if (DateTime.now().difference(lastUpdated).inMinutes < 30) {
            accessToken = data['tokens'];
            print('Using existing token.');
            return;
          }
        }
      }

      // Fetch a new token if it doesn't exist or is outdated
      print('Fetching a new access token.');
      final newToken = await SpotifySdk.getAccessToken(
        clientId: '32a50962636143748e6779e2f604e07b',
        redirectUrl: 'com-developer-spotifyproject://callback',
        scope: 'app-remote-control '
            'user-modify-playback-state '
            'playlist-read-private '
            'user-library-read '
            'playlist-modify-public '
            'user-read-currently-playing '
            'user-top-read '
            'user-read-recently-played',
      );

      if (newToken != null) {
        accessToken = newToken;
        print('New token obtained.');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('tokens')
            .doc('spotify')
            .set({
          'tokens': newToken,
          'lastUpdated': DateTime.now(),
        });
        print('New token saved to Firebase.');
      } else {
        print('Error: Failed to obtain a new access token.');
      }
    } catch (e) {
      print('Error getting Spotify token: $e');
    }
  }

  Future<RecentlyPlayedTracks?> getRecentlyPlayedTracksFromSpotify({
    int limit = 50,
    int after = 0,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      // Use the global accessToken directly
      if (accessToken == null) {
        print('Error: Access token is null.');
        return null;
      }
      print('Access token obtained.');

      // Fetch data from Spotify
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/me/player/recently-played?limit=$limit&after=$after'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final recentlyPlayedTracks = RecentlyPlayedTracks.fromJson(jsonData);

        // Save to Firebase
        final tracksData = recentlyPlayedTracks.items.map((item) {
          return {
            'name': item.track?.name ?? 'Unknown',
            'artistName': item.track?.artists.isNotEmpty == true
                ? item.track!.artists.first.name ?? 'Unknown'
                : 'Unknown',
            'playedAt': item.playedAt,
            'uri': item.track?.uri ?? '',
            'albumImageUrl': item.track?.album!.images.isNotEmpty == true
                ? item.track!.album!.images.first.url
                : null,
          };
        }).toList();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('spotify')
            .doc('recentlyPlayedTracks')
            .set({
          'tracks': tracksData,
          'lastUpdated': DateTime.now(),
        });

        return RecentlyPlayedTracks(items: recentlyPlayedTracks.items);
      } else {
        print(
            'Error: Failed to fetch recently played tracks. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching recently played tracks: $e');
      return null;
    }
  }
}
