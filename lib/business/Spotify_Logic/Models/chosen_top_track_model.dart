class ChosenTopTrack {
  final String name;
  final String artist;
  final String albumImage;
  final String uri;
  final String? url;

  ChosenTopTrack({
    required this.name,
    required this.artist,
    required this.albumImage,
    required this.uri,
    this.url,
  });

  factory ChosenTopTrack.fromJson(Map<String, dynamic> json) {
    return ChosenTopTrack(
      name: json['name'] as String,
      artist: json['artist'] as String,
      albumImage: json['albumImage'] as String,
      uri: json['uri'] as String,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'artist': artist,
      'albumImage': albumImage,
      'uri': uri,
      'url': url,
    };
  }
}
