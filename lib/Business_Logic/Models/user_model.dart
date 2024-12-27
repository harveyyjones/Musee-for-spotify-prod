import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? userId;
  String? eMail;
  String? name;
  String? biography;
  String? gender;
  String? phoneNumber;
  String? profilePhotoURL; // New property for single profile photo URL
  List<String> profilePhotos; // List to store multiple profile photos
  DateTime? createdAt;
  DateTime? updatedAt;
  String? songName;
  bool? isUserListening;
  int? age;
  List<String> interestedIn;
  String? fcmToken;

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
    };
  }

  UserModel.fromMap(Map<String, dynamic> map)
      : userId = map["userId"] as String? ?? '',
        eMail = map["eMail"] as String? ?? '',
        name = map["name"] as String? ?? '',
        profilePhotoURL = map["profilePhotoURL"] as String? ?? '',
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
        fcmToken = map["fcmToken"] as String? ?? '';
}

class UserWithCommonSongs {
  final UserModel user;
  final List<Map<String, dynamic>> commonSongs;
  final int commonSongsCount;

  UserWithCommonSongs({
    required this.user,
    required this.commonSongs,
    required this.commonSongsCount,
  });
}
