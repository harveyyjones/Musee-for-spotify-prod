class ArtistFromSearch {
  final String id;
  final String name;
  final String uri;

  ArtistFromSearch({
    required this.id,
    required this.name,
    required this.uri,
  });

  factory ArtistFromSearch.fromJson(Map<String, dynamic> json) {
    return ArtistFromSearch(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      uri: json['uri'] ?? '',
    );
  }
}
