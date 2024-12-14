class UsersSavedTracksModel {
  final String? href;
  final List<SavedTrackItem> items;
  final int? limit;
  final String? next;
  final int? offset;
  final String? previous;
  final int? total;

  UsersSavedTracksModel({
    this.href,
    required this.items,
    this.limit,
    this.next,
    this.offset,
    this.previous,
    this.total,
  });

  factory UsersSavedTracksModel.fromJson(Map<String, dynamic> json) {
    return UsersSavedTracksModel(
      href: json['href'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((item) => SavedTrackItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      limit: json['limit'] as int?,
      next: json['next'] as String?,
      offset: json['offset'] as int?,
      previous: json['previous'] as String?,
      total: json['total'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'href': href,
      'items': items.map((item) => item.toJson()).toList(),
      'limit': limit,
      'next': next,
      'offset': offset,
      'previous': previous,
      'total': total,
    };
  }
}

class SavedTrackItem {
  final String? addedAt;
  final Track track;

  SavedTrackItem({
    this.addedAt,
    required this.track,
  });

  factory SavedTrackItem.fromJson(Map<String, dynamic> json) {
    return SavedTrackItem(
      addedAt: json['added_at'] as String?,
      track: Track.fromJson(json['track'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'added_at': addedAt,
      'track': track.toJson(),
    };
  }
}

class Track {
  final Album album;
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
  final bool? isPlayable;
  final String? name;
  final int? popularity;
  final String? previewUrl;
  final int? trackNumber;
  final String? type;
  final String? uri;

  Track({
    required this.album,
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
    this.isPlayable,
    this.name,
    this.popularity,
    this.previewUrl,
    this.trackNumber,
    this.type,
    this.uri,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      album: Album.fromJson(json['album'] as Map<String, dynamic>),
      artists: (json['artists'] as List<dynamic>)
          .map((artist) => Artist.fromJson(artist as Map<String, dynamic>))
          .toList(),
      availableMarkets: (json['available_markets'] as List<dynamic>)
          .map((market) => market as String)
          .toList(),
      discNumber: json['disc_number'] as int?,
      durationMs: json['duration_ms'] as int?,
      explicit: json['explicit'] as bool?,
      externalIds: json['external_ids'] != null
          ? ExternalIds.fromJson(json['external_ids'] as Map<String, dynamic>)
          : null,
      externalUrls: json['external_urls'] != null
          ? ExternalUrls.fromJson(json['external_urls'] as Map<String, dynamic>)
          : null,
      href: json['href'] as String?,
      id: json['id'] as String?,
      isLocal: json['is_local'] as bool?,
      isPlayable: json['is_playable'] as bool?,
      name: json['name'] as String?,
      popularity: json['popularity'] as int?,
      previewUrl: json['preview_url'] as String?,
      trackNumber: json['track_number'] as int?,
      type: json['type'] as String?,
      uri: json['uri'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'album': album.toJson(),
      'artists': artists.map((artist) => artist.toJson()).toList(),
      'available_markets': availableMarkets,
      'disc_number': discNumber,
      'duration_ms': durationMs,
      'explicit': explicit,
      'external_ids': externalIds?.toJson(),
      'external_urls': externalUrls?.toJson(),
      'href': href,
      'id': id,
      'is_local': isLocal,
      'is_playable': isPlayable,
      'name': name,
      'popularity': popularity,
      'preview_url': previewUrl,
      'track_number': trackNumber,
      'type': type,
      'uri': uri,
    };
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
  final bool? isPlayable;
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
    this.isPlayable,
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
      artists: (json['artists'] as List<dynamic>)
          .map((artist) => Artist.fromJson(artist as Map<String, dynamic>))
          .toList(),
      availableMarkets: (json['available_markets'] as List<dynamic>)
          .map((market) => market as String)
          .toList(),
      externalUrls: json['external_urls'] != null
          ? ExternalUrls.fromJson(json['external_urls'] as Map<String, dynamic>)
          : null,
      href: json['href'] as String?,
      id: json['id'] as String?,
      images: (json['images'] as List<dynamic>)
          .map((image) => Image.fromJson(image as Map<String, dynamic>))
          .toList(),
      isPlayable: json['is_playable'] as bool?,
      name: json['name'] as String?,
      releaseDate: json['release_date'] as String?,
      releaseDatePrecision: json['release_date_precision'] as String?,
      totalTracks: json['total_tracks'] as int?,
      type: json['type'] as String?,
      uri: json['uri'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'album_type': albumType,
      'artists': artists.map((artist) => artist.toJson()).toList(),
      'available_markets': availableMarkets,
      'external_urls': externalUrls?.toJson(),
      'href': href,
      'id': id,
      'images': images.map((image) => image.toJson()).toList(),
      'is_playable': isPlayable,
      'name': name,
      'release_date': releaseDate,
      'release_date_precision': releaseDatePrecision,
      'total_tracks': totalTracks,
      'type': type,
      'uri': uri,
    };
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
          ? ExternalUrls.fromJson(json['external_urls'] as Map<String, dynamic>)
          : null,
      href: json['href'] as String?,
      id: json['id'] as String?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      uri: json['uri'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'external_urls': externalUrls?.toJson(),
      'href': href,
      'id': id,
      'name': name,
      'type': type,
      'uri': uri,
    };
  }
}

class Image {
  final int? height;
  final int? width;
  final String? url;

  Image({
    this.height,
    this.width,
    this.url,
  });

  factory Image.fromJson(Map<String, dynamic> json) {
    return Image(
      height: json['height'] as int?,
      width: json['width'] as int?,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'height': height,
      'width': width,
      'url': url,
    };
  }
}

class ExternalUrls {
  final String? spotify;

  ExternalUrls({
    this.spotify,
  });

  factory ExternalUrls.fromJson(Map<String, dynamic> json) {
    return ExternalUrls(
      spotify: json['spotify'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spotify': spotify,
    };
  }
}

class ExternalIds {
  final String? isrc;

  ExternalIds({
    this.isrc,
  });

  factory ExternalIds.fromJson(Map<String, dynamic> json) {
    return ExternalIds(
      isrc: json['isrc'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isrc': isrc,
    };
  }
}
