import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spotify_project/business/Spotify_Logic/Models/users_saved_tracks_model.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class SpotifyServiceForSavedTracks {
  static const String _baseUrl = 'https://api.spotify.com/v1';
  static const int _defaultLimit = 30;
  static const int _cacheDurationInDays = 2;
  String? _accessToken;

  // Singleton pattern
  static final SpotifyServiceForSavedTracks _instance =
      SpotifyServiceForSavedTracks._internal();

  factory SpotifyServiceForSavedTracks() {
    return _instance;
  }

  SpotifyServiceForSavedTracks._internal();

  Future<void> _getValidToken() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('tokens')
          .doc('spotify')
          .get();

      if (!doc.exists || doc.data()?['tokens'] == null) {
        // No token, get new one
        final newToken = await SpotifySdk.getAccessToken(
            clientId: '32a50962636143748e6779e2f604e07b',
            redirectUrl: 'com-developer-spotifyproject://callback',
            scope: 'app-remote-control '
                'user-modify-playback-state '
                'playlist-read-private '
                'user-library-read '
                'playlist-modify-public '
                'user-read-currently-playing '
                'user-top-read');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('tokens')
            .doc('spotify')
            .set({
          'tokens': newToken,
          'lastUpdated': DateTime.now(),
        });

        _accessToken = newToken;
      } else {
        final lastUpdated = (doc.data()?['lastUpdated'] as Timestamp).toDate();
        if (DateTime.now().difference(lastUpdated).inMinutes < 50) {
          _accessToken = doc.data()?['tokens'];
        } else {
          // Token expired, get new one
          await _getValidToken();
        }
      }
    } catch (e) {
      print('Error getting Spotify token: $e');
      return;
    }
  }

  Map<String, dynamic> _simplifyTrackData(SavedTrackItem item) {
    return {
      'name': item.track.name ?? 'Unknown',
      'uri': item.track.uri ?? '',
      'artistNames':
          item.track.artists.map((artist) => artist.name ?? 'Unknown').toList(),
      'albumImageUrl': item.track.album.images.isNotEmpty
          ? item.track.album.images.first.url
          : null,
    };
  }

  Future<UsersSavedTracksModel?> getSavedTracks({
    int limit = _defaultLimit,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return null;

      // Check cache if not forcing refresh
      if (!forceRefresh) {
        final cachedData = await _getCachedTracks();
        if (cachedData != null) return cachedData;
      }

      // Ensure we have a valid token
      if (_accessToken == null) {
        await _getValidToken();
        // If still null after getting token, return null
        if (_accessToken == null) return null;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/me/tracks?limit=$limit&offset=$offset'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final tracksModel = UsersSavedTracksModel.fromJson(jsonData);

        // Cache only essential data
        await _cacheTracks(tracksModel);

        return tracksModel;
      } else if (response.statusCode == 401) {
        // Token expired, get new one and retry
        await _getValidToken();
        if (_accessToken != null) {
          return getSavedTracks(limit: limit, offset: offset);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching saved tracks: $e');
      return null;
    }
  }

  Future<UsersSavedTracksModel?> _getCachedTracks() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('spotify')
          .doc('savedTracks')
          .get();

      if (!doc.exists || doc.data() == null) return null;

      final lastUpdated = (doc.data()?['lastUpdated'] as Timestamp).toDate();
      final isExpired =
          DateTime.now().difference(lastUpdated).inDays >= _cacheDurationInDays;

      if (isExpired) return null;

      final tracksList = doc.data()?['tracks'] as List<dynamic>;
      final items = tracksList.map((trackData) {
        return SavedTrackItem(
          addedAt: null,
          track: Track(
            album: Album(
              artists: [],
              availableMarkets: [],
              images: trackData['albumImageUrl'] != null
                  ? [ImageSavedTracks(url: trackData['albumImageUrl'])]
                  : [],
            ),
            artists: (trackData['artistNames'] as List<dynamic>)
                .map((name) => Artist(name: name as String))
                .toList(),
            availableMarkets: [],
            name: trackData['name'] as String,
            uri: trackData['uri'] as String,
          ),
        );
      }).toList();

      return UsersSavedTracksModel(items: items);
    } catch (e) {
      print('Error getting cached tracks: $e');
      return null;
    }
  }

  Future<void> _cacheTracks(UsersSavedTracksModel tracks) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final simplifiedTracks = tracks.items.map(_simplifyTrackData).toList();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('spotify')
          .doc('savedTracks')
          .set({
        'tracks': simplifiedTracks,
        'lastUpdated': DateTime.now(),
      });
    } catch (e) {
      print('Error caching tracks: $e');
    }
  }

  // Stream that combines Firebase cache and API data
  Stream<UsersSavedTracksModel?> streamSavedTracks() async* {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // First emit cached data
    final cachedData = await _getCachedTracks();
    if (cachedData != null) {
      yield cachedData;
    }

    // Then fetch fresh data if cache is expired
    final freshData = await getSavedTracks(forceRefresh: cachedData == null);
    if (freshData != null) {
      yield freshData;
    }
  }
}
