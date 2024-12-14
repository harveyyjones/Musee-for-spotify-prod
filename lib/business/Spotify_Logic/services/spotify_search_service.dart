import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spotify_project/business/Spotify_Logic/Models/search_response.dart';

class SpotifySearchService {
  final String _baseUrl = 'https://api.spotify.com/v1';
  final String _bearerToken;

  SpotifySearchService(this._bearerToken);

  Future<SearchResponse> searchTracks(String query,
      {int limit = 20, int offset = 0}) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/search?q=$encodedQuery&type=track&limit=$limit&offset=$offset'),
        headers: {
          'Authorization': 'Bearer $_bearerToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return SearchResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to search tracks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching tracks: $e');
    }
  }
}

Future<SearchResponse> searchSpotifyTracks({
  required String query,
  required String token,
  int limit = 20,
  int offset = 0,
  String market = 'US',
}) async {
  try {
    // Construct query parameters
    final queryParams = {
      'q': query,
      'type': 'track',
      'limit': limit.toString(),
      'offset': offset.toString(),
      'market': market,
    };

    // Create URL with encoded parameters
    final uri = Uri.https(
      'api.spotify.com',
      '/v1/search',
      queryParams,
    );

    // Make the request
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    // Check response status
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch data: ${response.statusCode}');
    }

    // Parse and return response
    final jsonResponse = json.decode(response.body);
    return SearchResponse.fromJson(jsonResponse);
  } on FormatException {
    throw Exception('Invalid response format');
  } on http.ClientException {
    throw Exception('Network error occurred');
  } catch (e) {
    throw Exception('Error during search: $e');
  }
}
