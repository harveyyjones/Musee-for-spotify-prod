import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? userId;
  String? eMail;
  String? name;
  String? biography;
  String? gender;
  String? phoneNumber;
  String? profilePhotoURL;
  List<String> profilePhotos;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? songName;
  bool? isUserListening;
  int? age;
  List<String> interestedIn;
  String? fcmToken;
  List<TopArtist>? topArtists;
  Map<String, double>? location;
  bool? isVisibleOnMap;

  UserModel({
    this.userId = '',
    this.name = '',
    this.eMail = '',
    this.profilePhotoURL = '',
    List<String>? profilePhotos,
    this.biography = '',
    this.gender = '',
    this.createdAt,
    this.updatedAt,
    this.phoneNumber = '',
    this.songName = '',
    this.isUserListening = false,
    this.age = 0,
    this.interestedIn = const [],
    this.fcmToken = '',
    this.topArtists,
    this.location,
    this.isVisibleOnMap = true,
  }) : this.profilePhotos = (profilePhotos?.isEmpty ?? true) ||
                (profilePhotos?.first.trim().isEmpty ?? true)
            ? [
                'https://c4.wallpaperflare.com/wallpaper/436/55/826/abstract-black-wallpaper-preview.jpg'
              ]
            : profilePhotos!;

  Map<String, dynamic> toMap() {
    return {
      "biography": biography ?? "",
      "createdAt": createdAt ?? FieldValue.serverTimestamp(),
      "eMail": eMail ?? "",
      "name": name ?? "",
      "userId": userId ?? "",
      "profilePhotoURL": profilePhotoURL ?? "",
      "profilePhotos": profilePhotos,
      "updatedAt": updatedAt ?? FieldValue.serverTimestamp(),
      "phoneNumber": phoneNumber ?? "",
      "songName": songName ?? "",
      "isUserListening": isUserListening ?? false,
      "gender": gender ?? "",
      "age": age ?? 0,
      "interestedIn": interestedIn,
      "fcmToken": fcmToken ?? "",
      "topArtists": topArtists?.map((artist) => artist.toMap()).toList() ?? [],
      "location": location,
      "isVisibleOnMap": isVisibleOnMap ?? true,
    };
  }

  UserModel.fromMap(Map<String, dynamic> map)
      : userId = map["userId"] as String? ?? '',
        eMail = map["eMail"] as String? ?? '',
        name = map["name"] as String? ?? '',
        profilePhotoURL = map["profilePhotoURL"] as String? ?? '',
        topArtists = map["topArtists"] != null
            ? List<TopArtist>.from((map["topArtists"] as List)
                .map((item) => TopArtist.fromMap(item as Map<String, dynamic>)))
            : null,
        profilePhotos =
            ((map["profilePhotos"] as List<dynamic>?)?.isEmpty ?? true) ||
                    ((map["profilePhotos"] as List<dynamic>?)
                            ?.first
                            .toString()
                            .trim()
                            .isEmpty ??
                        true)
                ? [
                    'https://c4.wallpaperflare.com/wallpaper/436/55/826/abstract-black-wallpaper-preview.jpg'
                  ]
                : (map["profilePhotos"] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [
                      'https://c4.wallpaperflare.com/wallpaper/436/55/826/abstract-black-wallpaper-preview.jpg'
                    ],
        biography = map["biography"] as String? ?? '',
        createdAt = (map["createdAt"] as Timestamp?)?.toDate(),
        updatedAt = (map["updatedAt"] as Timestamp?)?.toDate(),
        phoneNumber = map["phoneNumber"] as String? ?? '',
        songName = map["songName"] as String? ?? '',
        isUserListening = map["isUserListening"] as bool? ?? false,
        gender = map["gender"] as String? ?? '',
        age = map["age"] as int? ?? 0,
        interestedIn = List<String>.from(map["interestedIn"] ?? []),
        fcmToken = map["fcmToken"] as String? ?? '',
        location = map["location"] != null
            ? {
                'latitude': (map["location"]["latitude"] as num).toDouble(),
                'longitude': (map["location"]["longitude"] as num).toDouble(),
              }
            : null,
        isVisibleOnMap = map["isVisibleOnMap"] as bool? ?? true;
}

class UserWithCommonSongs {
  final UserModel user;
  final List<Map<String, dynamic>> commonSongs;
  final int commonSongsCount;
  final List<String> hobbies;

  UserWithCommonSongs({
    required this.user,
    required this.commonSongs,
    required this.commonSongsCount,
    required this.hobbies,
  });
}

class TopArtist {
  final String id;
  final String name;
  final String imageUrl;
  final int popularity;
  final List<String> genres;

  TopArtist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.popularity,
    required this.genres,
  });

  factory TopArtist.fromMap(Map<String, dynamic> map) {
    return TopArtist(
      id: map['id'] as String,
      name: map['name'] as String,
      imageUrl: map['imageUrl'] as String,
      popularity: map['popularity'] as int,
      genres: List<String>.from(map['genres'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'popularity': popularity,
      'genres': genres,
    };
  }
}

extension LocationHelper on UserModel {
  double? get latitude => location?['latitude'];
  double? get longitude => location?['longitude'];

  bool get hasValidLocation =>
      location != null &&
      location!['latitude'] != null &&
      location!['longitude'] != null;
}
