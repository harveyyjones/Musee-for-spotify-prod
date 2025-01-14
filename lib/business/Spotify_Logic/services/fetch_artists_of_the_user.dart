import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/business/Spotify_Logic/Models/top_artists_of_the_user_model.dart';

class SpotifyServiceForTopArtists {
  SpotifyServiceForTopArtists();

  Future<SpotifyArtistsResponse> fetchArtists(
      {required String accessToken}) async {
    if (accessToken.isEmpty) {
      throw Exception('Access token is null or empty');
    }

    print('Fetching artists with token: $accessToken');
    String url =
        'https://api.spotify.com/v1/me/top/artists?limit=10&time_range=short_term';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      var artists = SpotifyArtistsResponse.fromJson(data).items;
      await updateTopArtistsInFirebase(artists);
      return SpotifyArtistsResponse.fromJson(data);
    } else {
      print('Failed to fetch artists. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to fetch artists');
    }
  }

  updateTopArtistsInFirebase(List<Artist> artists) async {
    //Every time the data is fetched, we update the firebase with the new top artists.
    //This is to make sure that the top artists are always up to date.
    try {
      await FirestoreDatabaseService()
          .updateTopArtistsOrCreateIfDoesntExist(artists)
          .whenComplete(() => print(
              '✅ Top artists updated in firebase for the user with the ID of ${FirebaseAuth.instance.currentUser?.uid}'));
    } catch (e) {
      print('❌ Error updating top artists in firebase: $e');
    }
  }
}
