// services/spotify_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spotify_project/business/Spotify_Logic/Models/top_10_track_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpotifyServiceForTracks {
  final String accessToken;

  SpotifyServiceForTracks(this.accessToken);

  Future<List<SpotifyTrackFromSpotify>> fetchTracks() async {
    if (accessToken.isEmpty) {
      throw Exception('Access token is empty');
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.spotify.com/v1/me/top/tracks?limit=10&time_range=short_term'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body)['items'];
        final tracks = data
            .map((track) => SpotifyTrackFromSpotify.fromJson(track))
            .toList();
        print('Fetched ${tracks.length} tracks successfully');

        // Store tracks in Firebase
        await _updateFirebaseTopTracks(tracks);

        return tracks;
      } else {
        print(
            'Failed to load top tracks: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load top tracks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchTracks: $e');
      throw e;
    }
  }

  Future<void> _updateFirebaseTopTracks(
      List<SpotifyTrackFromSpotify> tracks) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      List<Map<String, dynamic>> topTracks = tracks.map((track) {
        return {
          'id': track.id,
          'name': track.name,
          'artists': track.artists
              .map((artist) => {
                    'id': artist.id,
                    'name': artist.name,
                    'href': artist.href,
                  })
              .toList(),
          'album': {
            'id': track.album.id,
            'name': track.album.name,
            'images': track.album.images
                .map((image) => {
                      'height': image.height,
                      'url': image.url,
                      'width': image.width,
                    })
                .toList(),
          },
          'previewUrl': track.previewUrl,
          'duration': track.duration,
          'popularity': track.popularity,
          'uri': track.uri,
          'explicit': track.explicit,
          'trackNumber': track.trackNumber,
        };
      }).toList();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'topTracks': topTracks,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('Successfully updated top tracks in Firebase');
    } catch (e) {
      print('Error updating Firebase top tracks: $e');
      throw e;
    }
  }
}
