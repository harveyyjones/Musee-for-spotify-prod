import 'package:spotify_project/business/Spotify_Logic/Models/track_from_search_model.dart';

class SearchResponse {
  final List<TrackFromSearch> tracks;
  final int total;
  final int limit;
  final int offset;
  final String? next;
  final String? previous;

  SearchResponse({
    required this.tracks,
    required this.total,
    required this.limit,
    required this.offset,
    this.next,
    this.previous,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    final tracksJson = json['tracks'] ?? {};
    return SearchResponse(
      tracks: (tracksJson['items'] as List<dynamic>?)
              ?.map((track) => TrackFromSearch.fromJson(track))
              .toList() ??
          [],
      total: tracksJson['total'] ?? 0,
      limit: tracksJson['limit'] ?? 0,
      offset: tracksJson['offset'] ?? 0,
      next: tracksJson['next'] ?? '',
      previous: tracksJson['previous'] ?? '',
    );
  }
}
