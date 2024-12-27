class RecentlyPlayedTracks {
  final List<Item> items;
  final String? next;
  final Cursors? cursors;
  final int? limit;
  final String? href;

  RecentlyPlayedTracks({
    required this.items,
    this.next,
    this.cursors,
    this.limit,
    this.href,
  });

  factory RecentlyPlayedTracks.fromJson(Map<String, dynamic> json) {
    return RecentlyPlayedTracks(
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => Item.fromJson(item))
              .toList() ??
          [],
      next: json['next'] as String?,
      cursors:
          json['cursors'] != null ? Cursors.fromJson(json['cursors']) : null,
      limit: json['limit'] as int?,
      href: json['href'] as String?,
    );
  }
}

class Item {
  final Track? track;
  final String? playedAt;
  final dynamic context;

  Item({
    this.track,
    this.playedAt,
    this.context,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      track: json['track'] != null ? Track.fromJson(json['track']) : null,
      playedAt: json['played_at'] as String?,
      context: json['context'],
    );
  }
}

class Track {
  final Album? album;
  final List<Artist> artists;
  final List<String> availableMarkets;
  final int? discNumber;
  final int? durationMs;
  final bool? explicit;
  final ExternalIds? externalIds;
  final ExternalUrls? externalUrls;
  final String? href;
  final String? id;
  final bool? isLocal;
  final String? name;
  final int? popularity;
  final String? previewUrl;
  final int? trackNumber;
  final String? type;
  final String? uri;

  Track({
    this.album,
    required this.artists,
    required this.availableMarkets,
    this.discNumber,
    this.durationMs,
    this.explicit,
    this.externalIds,
    this.externalUrls,
    this.href,
    this.id,
    this.isLocal,
    this.name,
    this.popularity,
    this.previewUrl,
    this.trackNumber,
    this.type,
    this.uri,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      album: json['album'] != null ? Album.fromJson(json['album']) : null,
      artists: (json['artists'] as List<dynamic>?)
              ?.map((artist) => Artist.fromJson(artist))
              .toList() ??
          [],
      availableMarkets: (json['available_markets'] as List<dynamic>?)
              ?.map((market) => market as String)
              .toList() ??
          [],
      discNumber: json['disc_number'] as int?,
      durationMs: json['duration_ms'] as int?,
      explicit: json['explicit'] as bool?,
      externalIds: json['external_ids'] != null
          ? ExternalIds.fromJson(json['external_ids'])
          : null,
      externalUrls: json['external_urls'] != null
          ? ExternalUrls.fromJson(json['external_urls'])
          : null,
      href: json['href'] as String?,
      id: json['id'] as String?,
      isLocal: json['is_local'] as bool?,
      name: json['name'] as String?,
      popularity: json['popularity'] as int?,
      previewUrl: json['preview_url'] as String?,
      trackNumber: json['track_number'] as int?,
      type: json['type'] as String?,
      uri: json['uri'] as String?,
    );
  }
}

class Album {
  final String? albumType;
  final List<Artist> artists;
  final List<String> availableMarkets;
  final ExternalUrls? externalUrls;
  final String? href;
  final String? id;
  final List<Image> images;
  final String? name;
  final String? releaseDate;
  final String? releaseDatePrecision;
  final int? totalTracks;
  final String? type;
  final String? uri;

  Album({
    this.albumType,
    required this.artists,
    required this.availableMarkets,
    this.externalUrls,
    this.href,
    this.id,
    required this.images,
    this.name,
    this.releaseDate,
    this.releaseDatePrecision,
    this.totalTracks,
    this.type,
    this.uri,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      albumType: json['album_type'] as String?,
      artists: (json['artists'] as List<dynamic>?)
              ?.map((artist) => Artist.fromJson(artist))
              .toList() ??
          [],
      availableMarkets: (json['available_markets'] as List<dynamic>?)
              ?.map((market) => market as String)
              .toList() ??
          [],
      externalUrls: json['external_urls'] != null
          ? ExternalUrls.fromJson(json['external_urls'])
          : null,
      href: json['href'] as String?,
      id: json['id'] as String?,
      images: (json['images'] as List<dynamic>?)
              ?.map((image) => Image.fromJson(image))
              .toList() ??
          [],
      name: json['name'] as String?,
      releaseDate: json['release_date'] as String?,
      releaseDatePrecision: json['release_date_precision'] as String?,
      totalTracks: json['total_tracks'] as int?,
      type: json['type'] as String?,
      uri: json['uri'] as String?,
    );
  }
}

class Artist {
  final ExternalUrls? externalUrls;
  final String? href;
  final String? id;
  final String? name;
  final String? type;
  final String? uri;

  Artist({
    this.externalUrls,
    this.href,
    this.id,
    this.name,
    this.type,
    this.uri,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      externalUrls: json['external_urls'] != null
          ? ExternalUrls.fromJson(json['external_urls'])
          : null,
      href: json['href'] as String?,
      id: json['id'] as String?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      uri: json['uri'] as String?,
    );
  }
}

class ExternalUrls {
  final String? spotify;

  ExternalUrls({this.spotify});

  factory ExternalUrls.fromJson(Map<String, dynamic> json) {
    return ExternalUrls(
      spotify: json['spotify'] as String?,
    );
  }
}

class ExternalIds {
  final String? isrc;

  ExternalIds({this.isrc});

  factory ExternalIds.fromJson(Map<String, dynamic> json) {
    return ExternalIds(
      isrc: json['isrc'] as String?,
    );
  }
}

class Image {
  final int? height;
  final String? url;
  final int? width;

  Image({this.height, this.url, this.width});

  factory Image.fromJson(Map<String, dynamic> json) {
    return Image(
      height: json['height'] as int?,
      url: json['url'] as String?,
      width: json['width'] as int?,
    );
  }
}

class Cursors {
  final String? after;
  final String? before;

  Cursors({this.after, this.before});

  factory Cursors.fromJson(Map<String, dynamic> json) {
    return Cursors(
      after: json['after'] as String?,
      before: json['before'] as String?,
    );
  }
}
