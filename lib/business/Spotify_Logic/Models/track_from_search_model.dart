import 'package:spotify_project/business/Spotify_Logic/Models/artist_from_search_model.dart';
import 'package:spotify_project/business/Spotify_Logic/Models/album_from_search_model.dart';

class TrackFromSearch {
  final String id;
  final String name;
  final String uri;
  final int duration;
  final bool explicit;
  final int popularity;
  final String previewUrl;
  final AlbumFromSearch album;
  final List<ArtistFromSearch> artists;

  TrackFromSearch({
    required this.id,
    required this.name,
    required this.uri,
    required this.duration,
    required this.explicit,
    required this.popularity,
    required this.previewUrl,
    required this.album,
    required this.artists,
  });

  factory TrackFromSearch.fromJson(Map<String, dynamic> json) {
    return TrackFromSearch(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      uri: json['uri'] ?? '',
      duration: json['duration_ms'] ?? 0,
      explicit: json['explicit'] ?? false,
      popularity: json['popularity'] ?? 0,
      previewUrl: json['preview_url'] ?? '',
      album: AlbumFromSearch.fromJson(json['album'] ?? {}),
      artists: (json['artists'] as List<dynamic>?)
              ?.map((artist) => ArtistFromSearch.fromJson(artist))
              .toList() ??
          [],
    );
  }
}
