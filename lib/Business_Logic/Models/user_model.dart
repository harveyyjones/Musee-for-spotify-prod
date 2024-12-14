import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? userId;
  String? eMail;
  String? name;
  String? majorInfo;
  String? biography;
  String? clinicLocation;
  String? gender;
  String? clinicName;
  String? phoneNumber;
  bool? clinicOwner;
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
    this.majorInfo = '',
    this.clinicLocation = '',
    this.profilePhotoURL = '',
    List<String>? profilePhotos,
    this.biography = '',
    this.clinicName = '',
    this.gender = '',
    this.createdAt,
    this.updatedAt,
    this.phoneNumber = '',
    this.clinicOwner = false,
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
      "majorInfo": majorInfo ?? "",
      "clinicLocation": clinicLocation ?? "",
      "name": name ?? "",
      "clinicName": clinicName ?? "",
      "userId": userId ?? "",
      "profilePhotoURL": profilePhotoURL ?? "",
      "profilePhotos": profilePhotos,
      "updatedAt": updatedAt ?? FieldValue.serverTimestamp(),
      "phoneNumber": phoneNumber ?? "",
      "clinicOwner": clinicOwner ?? false,
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
        majorInfo = map["majorInfo"] as String? ?? '',
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
        clinicLocation = map["clinicLocation"] as String? ?? '',
        biography = map["biography"] as String? ?? '',
        createdAt = (map["createdAt"] as Timestamp?)?.toDate(),
        updatedAt = (map["updatedAt"] as Timestamp?)?.toDate(),
        phoneNumber = map["phoneNumber"] as String? ?? '',
        clinicName = map["clinicName"] as String? ?? '',
        clinicOwner = map["clinicOwner"] as bool? ?? false,
        songName = map["songName"] as String? ?? '',
        isUserListening = map["isUserListening"] as bool? ?? false,
        gender = map["gender"] as String? ?? '',
        age = map["age"] as int? ?? 0,
        interestedIn = List<String>.from(map["interestedIn"] ?? []),
        fcmToken = map["fcmToken"] as String? ?? '';
}
