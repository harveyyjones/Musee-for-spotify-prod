class SpotifyArtistsResponse {
  final String href;
  final int limit;
  final String? next;
  final int offset;
  final String? previous;
  final int total;
  final List<Artist> items;

  SpotifyArtistsResponse({
    required this.href,
    required this.limit,
    this.next,
    required this.offset,
    this.previous,
    required this.total,
    required this.items,
  });

  factory SpotifyArtistsResponse.fromJson(Map<String, dynamic> json) {
    return SpotifyArtistsResponse(
      href: json['href'],
      limit: json['limit'],
      next: json['next'],
      offset: json['offset'],
      previous: json['previous'],
      total: json['total'],
      items:
          List<Artist>.from(json['items'].map((item) => Artist.fromJson(item))),
    );
  }
}

class Artist {
  final ExternalUrls externalUrls;
  final Followers followers;
  final List<String> genres;
  final String href;
  final String id;
  final List<ImageOfTheArtist> images;
  final String name;
  final int popularity;
  final String type;
  final String uri;

  Artist({
    required this.externalUrls,
    required this.followers,
    required this.genres,
    required this.href,
    required this.id,
    required this.images,
    required this.name,
    required this.popularity,
    required this.type,
    required this.uri,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    print("Parsing artist: ${json['name']}");
    return Artist(
      externalUrls: ExternalUrls.fromJson(json['external_urls'] ?? {}),
      followers: Followers.fromJson(json['followers'] ?? {}),
      genres: List<String>.from(json['genres'] ?? []),
      href: json['href'] ?? '',
      id: json['id'] ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((image) => ImageOfTheArtist.fromJson(image))
              .toList() ??
          [],
      name: json['name'] ?? '',
      popularity: json['popularity'] ?? 0,
      type: json['type'] ?? '',
      uri: json['uri'] ?? '',
    );
  }
}

class ExternalUrls {
  final String spotify;

  ExternalUrls({required this.spotify});

  factory ExternalUrls.fromJson(Map<String, dynamic> json) {
    return ExternalUrls(spotify: json['spotify']);
  }
}

class Followers {
  final String? href;
  final int total;

  Followers({this.href, required this.total});

  factory Followers.fromJson(Map<String, dynamic> json) {
    return Followers(
      href: json['href'],
      total: json['total'],
    );
  }
}

class ImageOfTheArtist {
  final String url;
  final int height;
  final int width;

  ImageOfTheArtist(
      {required this.url, required this.height, required this.width});

  factory ImageOfTheArtist.fromJson(Map<String, dynamic> json) {
    return ImageOfTheArtist(
      url: json['url'],
      height: json['height'],
      width: json['width'],
    );
  }
}
