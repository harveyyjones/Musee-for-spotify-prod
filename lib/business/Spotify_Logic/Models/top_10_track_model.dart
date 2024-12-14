class SpotifyTrackFromSpotify {
  final String? id;
  final String? name;
  final List<ArtistOfTracks> artists;
  final Album album;
  final String? previewUrl;
  final int? duration;
  final int? popularity;
  final String? uri;
  final bool? explicit;
  final int? trackNumber;

  SpotifyTrackFromSpotify({
    this.id,
    this.name,
    required this.artists,
    required this.album,
    this.previewUrl,
    this.duration,
    this.popularity,
    this.uri,
    this.explicit,
    this.trackNumber,
  });

  factory SpotifyTrackFromSpotify.fromJson(Map<String, dynamic> json) {
    return SpotifyTrackFromSpotify(
      id: json['id'] as String?,
      name: json['name'] as String?,
      artists: (json['artists'] as List?)
              ?.map((artist) => ArtistOfTracks.fromJson(artist))
              .toList() ??
          [],
      album: Album.fromJson(json['album'] ?? {}),
      previewUrl: json['preview_url'] as String?,
      duration: json['duration_ms'] as int?,
      popularity: json['popularity'] as int?,
      uri: json['uri'] as String?,
      explicit: json['explicit'] as bool?,
      trackNumber: json['track_number'] as int?,
    );
  }
}

class ArtistOfTracks {
  final String? id;
  final String? name;
  final String? href;

  ArtistOfTracks({
    this.id,
    this.name,
    this.href,
  });

  factory ArtistOfTracks.fromJson(Map<String, dynamic> json) {
    return ArtistOfTracks(
      id: json['id'] as String?,
      name: json['name'] as String?,
      href: json['href'] as String?,
    );
  }
}

class Album {
  final String? id;
  final String? name;
  final List<ImageOfTheTrack> images;

  Album({
    this.id,
    this.name,
    required this.images,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as String?,
      name: json['name'] as String?,
      images: (json['images'] as List?)
              ?.map((image) => ImageOfTheTrack.fromJson(image))
              .toList() ??
          [],
    );
  }
}

class ImageOfTheTrack {
  final int? height;
  final String? url;
  final int? width;

  ImageOfTheTrack({
    this.height,
    this.url,
    this.width,
  });

  factory ImageOfTheTrack.fromJson(Map<String, dynamic> json) {
    return ImageOfTheTrack(
      height: json['height'] as int?,
      url: json['url'] as String?,
      width: json['width'] as int?,
    );
  }
}
