class AlbumFromSearch {
  final String id;
  final String name;
  final String releaseDate;
  final int totalTracks;
  final List<String> images;

  AlbumFromSearch({
    required this.id,
    required this.name,
    required this.releaseDate,
    required this.totalTracks,
    required this.images,
  });

  factory AlbumFromSearch.fromJson(Map<String, dynamic> json) {
    return AlbumFromSearch(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      releaseDate: json['release_date'] ?? '',
      totalTracks: json['total_tracks'] ?? 0,
      images: (json['images'] as List<dynamic>?)
              ?.map((image) => image['url'] as String)
              .toList() ??
          [],
    );
  }
}
