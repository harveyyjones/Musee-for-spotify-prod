// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:spotify_project/Business_Logic/Models/message_model.dart';
import 'package:spotify_project/Business_Logic/Models/spotify_refresh_token_response_model.dart';
import 'package:spotify_project/business/Spotify_Logic/Models/top_10_track_model.dart';

import 'package:spotify_project/business/Spotify_Logic/Models/top_artists_of_the_user_model.dart';
import 'package:spotify_project/business/Spotify_Logic/constants.dart';
import 'package:spotify_project/business/Spotify_Logic/services/fetch_artists_of_the_user.dart';
import 'package:spotify_project/business/Spotify_Logic/services/fetch_top_10_tracks_of_the_user.dart';
import 'package:spotify_project/business/business_logic.dart';
import 'package:spotify_project/screens/register_page.dart';
import 'package:spotify_sdk/models/image_uri.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'Models/user_model.dart';
import 'package:http/http.dart' as http;

List allClinicOwnersList = [];

class FirestoreDatabaseService extends BusinessLogic {
  final _fireStore = FirebaseFirestore.instance;
  var collection = FirebaseFirestore.instance.collection('users');

  late final FirebaseFirestore _instance = FirebaseFirestore.instance;
  var currentUserUID;
  // O anki aktif kullanıcının bilgilerini alıp nesneye çeviren metod.
  Future<UserModel> getUserData() async {
    User? user = await FirebaseAuth.instance.currentUser;

    DocumentSnapshot<Map<String, dynamic>> okunanUser =
        await FirebaseFirestore.instance.doc("users/${user?.uid}").get();
    Map<String, dynamic>? okunanUserbilgileriMap = okunanUser.data();
    UserModel okunanUserBilgileriNesne =
        UserModel.fromMap(okunanUserbilgileriMap!);
    print(okunanUserBilgileriNesne.toString());
    return okunanUserBilgileriNesne;
  }

  Future<UserModel> getUserDataForDetailPage([uid]) async {
    // Başkasının profilini incelerken veri çekmeye yarıyor.
    DocumentSnapshot<Map<String, dynamic>> okunanUser =
        await FirebaseFirestore.instance.doc("users/${uid}").get();
    Map<String, dynamic>? okunanUserbilgileriMap = okunanUser.data();
    UserModel okunanUserBilgileriNesne =
        UserModel.fromMap(okunanUserbilgileriMap!);
    print(okunanUserBilgileriNesne.name.toString());
    return okunanUserBilgileriNesne;
  }

  Future<UserModel?> getUserDataForMessageBox(uid) async {
    // Mesaj kutusunda konuştuğum insanların ID'lerini alarak kişisel bilgilerini döndüren metod.
    DocumentSnapshot<Map<String, dynamic>> okunanUser =
        await FirebaseFirestore.instance.doc("users/${uid}").get();
    Map<String, dynamic>? okunanUserbilgileriMap = await okunanUser.data();
    if (okunanUserbilgileriMap != null) {
      UserModel okunanUserBilgileriNesne =
          UserModel.fromMap(okunanUserbilgileriMap);
      print(" Fotolar :${okunanUserBilgileriNesne.name.toString()}");

      return okunanUserBilgileriNesne;
    }
    return null;
  }

  Future<List<UserModel>> getAllUsersData({required String filterType}) async {
    switch (filterType) {
      case "never see the unliked again":
// First get all users
        QuerySnapshot querySnapshot =
            await FirebaseFirestore.instance.collection("users").get();
// Get previously swiped users
        var previousMatchesRef = await _instance
            .collection("matches")
            .doc(currentUser!.uid)
            .collection("quickMatchesList")
            .get();
// Create set of previously unliked user IDs
        Set<String> unlikedUserIds = {};
        for (var doc in previousMatchesRef.docs) {
          if (doc.data()["isLiked"] == false) {
            unlikedUserIds.add(doc.data()["uid"] as String);
          }
        }
// Filter out previously unliked users
        List<UserModel> userList = querySnapshot.docs
            .where((doc) => !unlikedUserIds.contains(doc.id))
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
        return userList;
      case "show the swiped again later":
        QuerySnapshot querySnapshot =
            await FirebaseFirestore.instance.collection("users").get();
        List<UserModel> userList = querySnapshot.docs.map((doc) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }).toList();
        return userList;
      default:
        throw ArgumentError('Invalid filter type provided');
    }
  }

  getAllSharedPosts() {
    // Tüm paylaşılan postları çeker, tabi kendi paylaştıkları.
    print("Tıklandı");
    return _instance
        .collection("users")
        .doc(currentUser!.uid)
        .collection("sharedPosts")
        .orderBy("timeStamp", descending: true)
        .snapshots();
  }

  getAllSharedPostsOfSomeone(uid) {
    // Tüm paylaşılan postları çeker, ancak başka bir kullanıcının.
    print("Tıklandı");
    return _instance
        .collection("users")
        .doc(uid)
        .collection("sharedPosts")
        .orderBy("timeStamp", descending: true)
        .snapshots();
  }

  getAllSharedPostsForCardDetails(uid) {
    print("Tıklandı");
    return _instance
        .collection("users")
        .doc(uid)
        .collection("sharedPosts")
        .orderBy("timeStamp", descending: true)
        .snapshots();
  }

// Burada ilk kez register sayfasından aldığımız verileri veritabanına yolluyoruz. Öncesinde modelden geçirip map'e dönüştürüyoruz.
  Future<List<String>> uploadProfileImages(List<File> images) async {
    List<String> imageUrls = [];
    for (var i = 0; i < images.length; i++) {
      String fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(
          'users/${FirebaseAuth.instance.currentUser!.uid}/profile_images/$fileName');
      UploadTask uploadTask = ref.putFile(images[i]);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }
    return imageUrls;
  }

  Future<UserModel> saveUser({
    String? biography,
    List<String>? profilePhotos,
    String? name,
    String? majorInfo,
    String? clinicLocation,
    String? clinicName,
    String? phoneNumber,
    bool? clinicOwner,
    String? uid,
    int? age,
    String? gender,
    List<String>? interestedIn,
    String? fcmToken,
  }) async {
    final userId = uid ?? FirebaseAuth.instance.currentUser?.uid;
    final userRef = FirebaseFirestore.instance.collection("users").doc(userId);

    // Get existing user data
    final userDoc = await userRef.get();
    Map<String, dynamic> existingData = userDoc.data() ?? {};

    // Create merged user data
    UserModel mergedUser = UserModel(
      biography: biography ?? existingData['biography'] ?? "",
      eMail: FirebaseAuth.instance.currentUser?.email ??
          existingData['eMail'] ??
          "",
      majorInfo: majorInfo ?? existingData['majorInfo'] ?? "",
      profilePhotoURL: profilePhotos?.isNotEmpty == true
          ? profilePhotos!.first
          : existingData['profilePhotoURL'],
      profilePhotos: profilePhotos ?? existingData['profilePhotos'] ?? [],
      name: name ?? existingData['name'] ?? "",
      clinicLocation: clinicLocation ?? existingData['clinicLocation'] ?? "",
      userId: userId,
      clinicName: clinicName ?? existingData['clinicName'] ?? "",
      clinicOwner: clinicOwner ?? existingData['clinicOwner'] ?? false,
      phoneNumber: phoneNumber ?? existingData['phoneNumber'],
      age: age ?? existingData['age'],
      gender: gender ?? existingData['gender'],
      interestedIn: interestedIn ?? existingData['interestedIn'] ?? [],
      fcmToken: fcmToken ?? existingData['fcmToken'],
    );

    // Save merged data
    await userRef.set(mergedUser.toMap(), SetOptions(merge: true));

    return mergedUser;
  }

  updateProfilePhoto(String imageURL) async {
    DocumentReference userRef =
        _instance.collection("users").doc(currentUser!.uid);

    // First, get the current profilePhotos array
    DocumentSnapshot userDoc = await userRef.get();
    List<String> profilePhotos =
        List<String>.from(userDoc['profilePhotos'] ?? []);

    // Update the first item if it exists, otherwise add the new URL
    if (profilePhotos.isNotEmpty) {
      profilePhotos[0] = imageURL;
    } else {
      profilePhotos.add(imageURL);
    }

    // Update both profilePhotos and profilePhotoURL
    await userRef
        .update({"profilePhotos": profilePhotos, "profilePhotoURL": imageURL});

    print("Profile photo updated successfully");
  }

  updateName(newName) {
    _instance
        .collection("users")
        .doc(currentUser!.uid)
        .update({"name": newName});
  }

  updateBiography(newBiography) {
    _instance
        .collection("users")
        .doc(currentUser!.uid)
        .update({"biography": newBiography});
  }

  getName() async {
    String? name = "deafult";
    await getProfileData().forEach((element) {
      name = element.data()!["name"];
    });
    return name.toString();
  }

  void updatePhoneNumber(String phoneNumber) {
    _instance
        .collection("users")
        .doc(currentUser!.uid)
        .update({"phoneNumber": phoneNumber});
  }

  void updateCaption(
    String newCaption,
  ) async {
    // Burada önce kaçıncı postu güncelleyeceiğini anlamak için toplam kaç post atılıdığını çekiyoruz.
    //Sonrasında (Son postu aldığımız için) güncelleme işlemi realtime olarak gerçekleşiyor.
    var postNumber = await getSharedPostNumber();
    _instance
        .collection("users")
        .doc(currentUser!.uid)
        .collection("sharedPosts")
        .doc("post$postNumber")
        .update(
      {"caption": newCaption, "uid": currentUser!.uid},
    );
  }

  Future<File?> cropImage(File imageFile) async {
    // TODO: Fotoyu kırpmadan çıkınca null hatası veriyor. Onu bir ara düzelt.
    CroppedFile? croppedImage = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatioPresets: [CropAspectRatioPreset.square],
    );
    return File(croppedImage!.path);
  }

  getSharedPostNumber() async {
    final QuerySnapshot docs = await _instance
        .collection("users")
        .doc(currentUser!.uid)
        .collection("sharedPosts")
        .get();

    final int docs0 = docs.docs.length;
    print("Paylaşılan foto sayısı: $docs0");

    return docs0;
  }

// Çıkış yaparken
  signOut(context) async {
    await FirebaseAuth.instance.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Signed Out'),
        backgroundColor: Colors.green,
      ),
    );
  }

// Ana sayfadaki selamlama mesajlarında kullanmak için.
  String greeting() {
    var hour = DateTime.now().hour;
    if (hour < 12 && hour > 5) {
      return 'Morning';
    }
    if (hour < 17 && hour > 12) {
      return 'Afternoon';
    }
    return 'Evening';
  }

// Mesajları stream veri tipinde çekerken.
  Stream<List<Message>> getMessagesFromStream(
      String currentUserID, String userIDOfOtherUser) {
    var snapshot = _fireStore
        .collection("conversations")
        .doc("$currentUserID--$userIDOfOtherUser")
        .collection("messages")
        .orderBy("date")
        .snapshots();
    // Önce d��kümanları sırayla ele almak için 1. map() metodunu çağırdık, sonra her bir dökümanı fromMap() metoduna yollamak için ikinci map metodunu çağırdık.
    return snapshot.map((event) =>
        event.docs.map((message) => Message.fromMap(message.data())).toList());
  }

  Future<void> deleteAccount(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete user account
        await user.delete();

        // Sign out and show success message
        // await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Handle authentication errors
      String message = 'An error occurred while deleting account';
      if (e.code == 'requires-recent-login') {
        message = 'Please log in again before deleting your account';
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    } catch (e) {
      print('Error deleting account: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while deleting account'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _deleteUserMatches(String userId, WriteBatch batch) async {
    try {
      // Delete matches where user is the creator
      final userMatchesRef = _fireStore.collection('matches').doc(userId);

      // Delete quick matches
      final quickMatchesQuery =
          await userMatchesRef.collection('quickMatchesList').get();
      for (var doc in quickMatchesQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete previous matches
      final previousMatchesQuery =
          await userMatchesRef.collection('previousMatchesList').get();
      for (var doc in previousMatchesQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete the matches document itself
      batch.delete(userMatchesRef);

      // Delete matches where user is matched with others
      final allMatchesQuery = await _fireStore.collection('matches').get();
      for (var matchDoc in allMatchesQuery.docs) {
        // Check quick matches
        final quickMatches = await matchDoc.reference
            .collection('quickMatchesList')
            .where('uid', isEqualTo: userId)
            .get();
        for (var doc in quickMatches.docs) {
          batch.delete(doc.reference);
        }

        // Check previous matches
        final previousMatches = await matchDoc.reference
            .collection('previousMatchesList')
            .where('uid', isEqualTo: userId)
            .get();
        for (var doc in previousMatches.docs) {
          batch.delete(doc.reference);
        }
      }
    } catch (e) {
      print('Error deleting matches: $e');
      throw e;
    }
  }

  Future<void> _deleteUserConversations(String userId, WriteBatch batch) async {
    try {
      // Get all conversations where user is involved (using the composite ID format from your code)
      final QuerySnapshot conversationsQuery =
          await _fireStore.collection('conversations').get();

      for (var doc in conversationsQuery.docs) {
        String docId = doc.id;
        // Check if the conversation involves the user (based on your ID format: "uid1--uid2")
        if (docId.contains(userId)) {
          // Delete all messages in the conversation
          final messagesQuery =
              await doc.reference.collection('messages').get();
          for (var messageDoc in messagesQuery.docs) {
            batch.delete(messageDoc.reference);
          }

          // Delete the conversation document itself
          batch.delete(doc.reference);
        }
      }
    } catch (e) {
      print('Error deleting conversations: $e');
      throw e;
    }
  }

  Future<void> _deleteUserStorageFiles(String userId) async {
    try {
      final Reference storageRef = FirebaseStorage.instance.ref();
      final String userPath = 'users/$userId';

      // List all files in user's directory
      final ListResult result = await storageRef.child(userPath).listAll();

      // Delete all files
      await Future.forEach(result.items, (Reference ref) async {
        try {
          await ref.delete();
        } catch (e) {
          print('Error deleting file ${ref.fullPath}: $e');
          // Continue with other deletions even if one fails
        }
      });

      // Delete all subdirectories (including profile_images and posts)
      await Future.forEach(result.prefixes, (Reference ref) async {
        final ListResult subResult = await ref.listAll();
        await Future.forEach(subResult.items, (Reference fileRef) async {
          try {
            await fileRef.delete();
          } catch (e) {
            print('Error deleting file ${fileRef.fullPath}: $e');
          }
        });
      });
    } catch (e) {
      print('Error deleting storage files: $e');
      throw e;
    }
  }

  Future<void> updateIsUserListening(bool isPlaying, String songName) async {
    if (currentUser == null) return;

    try {
      await _instance.collection("users").doc(currentUser!.uid).update({
        "isUserListening": isPlaying,
        "songName": songName,
        "lastUpdated": FieldValue.serverTimestamp()
      });
    } catch (e) {
      print('Error updating user listening status: $e');
    }
  }

  Stream<Map<String, dynamic>> getUserListeningStream() {
    // Returns the stream of the currently listening music, or last listened music.
    return _instance
        .collection("users")
        .doc(currentUser!.uid)
        .snapshots()
        .map((snapshot) => {
              'isListening': snapshot.data()?['isUserListening'] ?? false,
              'songName': snapshot.data()?['songName'] ?? '',
            });
  }

  Future<void> getUserDatasToMatch({
    required String songName,
    required bool amIListeningNow,
    String? spotifyUri,
    String? image,
  }) async {
    print("Şu method tetiklendi: ${getUserDatasToMatch}");
    // Anlık olarak sürekli olarak o anda eşleşilen kişinin bilgilerini kullanıma hazır tutuyor.
    try {
      // Get previously unliked users
      final previousMatchesRef = await _instance
          .collection("matches")
          .doc(currentUser!.uid)
          .collection("previousMatchesList")
          .get();

      Set<String> unlikedUserIds = {};
      for (var doc in previousMatchesRef.docs) {
        if (doc.data()["isLiked"] == false) {
          unlikedUserIds.add(doc.data()["uid"] as String);
        }
      }

      // Get all users
      QuerySnapshot<Map<String, dynamic>> _okunanUser =
          await FirebaseFirestore.instance.collection("users").get();

      for (var item in _okunanUser.docs) {
        // Skip if user was previously unliked
        if (unlikedUserIds.contains(item["userId"])) {
          continue;
        }

        // Check if the document contains the 'songName' field and matches
        if (item.data().containsKey('songName') &&
            songName == item["songName"]) {
          sendMatchesToDatabase(
              item["userId"], songName, songName, spotifyUri, image);
          print("Eşleşilen kişi: ${item["name"]}");
          print("Eşleşilen kişinin uid: ${item["userId"]}");
        }
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  sendMatchesToDatabase(uid, musicUrl, title, spotifyUri, image) async {
    final previousMatchesRef = _instance.doc("matches/${currentUser!.uid}");

    // Check if collection exists
    final collectionRef = previousMatchesRef.collection("previousMatchesList");
    final collectionSnapshot = await collectionRef.limit(1).get();

    if (!collectionSnapshot.docs.isNotEmpty) {
      // Create collection if it doesn't exist
      await previousMatchesRef.set({
        'createdAt': DateTime.now(),
      });
    }

    final matchDoc = collectionRef.doc(uid);

    // Check if we matched the user before
    final likes = await getLikedPeople();
    final hasMatchedBefore = likes.any((like) => like.userId == uid);

    // Don't update if matching with self
    // if (uid == currentUser!.uid) {
    //   print("Skipping match with self");
    //   return;
    // }

    // Check if document exists first
    final docSnapshot = await matchDoc.get();

    if (hasMatchedBefore) {
      if (docSnapshot.exists) {
        // Update existing match
        await matchDoc.update({
          "timeStamp": DateTime.now(),
          "url": musicUrl,
          "titleOfTheSong": title,
          "spotifyUri": spotifyUri,
          // FIXME: Handle image later, it is an instance.
          "image": image.toString(),
        });
        print("Existing match updated successfully");
      } else {
        print("Match document does not exist");
      }
    } else {
      // Create new match
      await matchDoc.set({
        "uid": uid,
        "timeStamp": DateTime.now(),
        "url": musicUrl,
        "titleOfTheSong": title,
        "spotifyUri": spotifyUri,
        "image": image,
        "isLiked": null
      });
      print("New match added successfully");
    }
  }

  updateIsLiked(value, uidOfTheMatch) async {
    // Updates if liked to use later in the notification screen. (Or to not to show the swipe cards.)
    await _instance
        .collection("matches")
        .doc(currentUser!.uid)
        .collection("previousMatchesList")
        .doc(uidOfTheMatch)
        .update({"isLiked": value}).then(
            (value) => print("Update isLiked succesfull."));
  }

  updateIsLikedAsQuickMatch(value, uidOfTheMatch) async {
    // Check if uidOfTheMatch is empty before executing
    if (uidOfTheMatch == null || uidOfTheMatch.isEmpty) {
      print("uidOfTheMatch is empty, no action taken");
      return;
    }

    // Updates if liked to use later in the notification screen. (Or to not to show the swipe cards.)
    final previousMatchesRef = _instance.doc("matches/${currentUser!.uid}");
    previousMatchesRef.collection("quickMatchesList").doc(uidOfTheMatch).set({
      "uid": uidOfTheMatch,
      "timeStamp": DateTime.now(),
      "isLiked": value
    }).then((value) => print("İşlem başarılı"));
  }

  getMatchesIds() async {
    print("Şu method tetiklendi getMatchesIds().");
    // Tüm eşleşmelerin Id'lerini döndürür. Daha sonra bilgileri çekmek için kullanılacak.
    List tumEslesmelerinIdsi = [];
    var previousMatchesRef = await _instance
        .collection("matches")
        .doc(currentUser!.uid)
        .collection("previousMatchesList")
        .get();
    for (var item in previousMatchesRef.docs) {
      print(item["uid"]);
      tumEslesmelerinIdsi.add(item["uid"]);
      print("Tüm eşleşmelerin olduğu kişilerin idleri: ${tumEslesmelerinIdsi}");
      return tumEslesmelerinIdsi;
    }
  }

  Future<UserModel?> getTheCurrentMatchesInTheListeningSong(
      String currentTrackName) async {
    // when user is listening actively and match at that time with someone or in the past in the same song. They will be returned here.
    try {
      final currentMatch = await _instance
          .collection("matches")
          .doc(currentUser!.uid)
          .collection("previousMatchesList")
          .doc(currentUser!.uid)
          .get();

      if (currentTrackName ==
          await getTheMutualSongViaUIdOfTheMatch(
              currentUser!.uid)["titleOfTheSong"]) {
        var userData = await getUserDataForDetailPage(
            currentMatch.data()?["uid"].toString());
        print(
            "********************* CURRENT MATCHES: ********************************");
        print(userData.toMap());
        return userData;
      }
    } catch (e) {
      print('Error getting current matches: $e');
      return null;
    }
    return null;
  }

  Future<List> getPreviousMatchesList() async {
    List usersList = [];

    var previousMatchesRef = await _instance
        .collection("matches")
        .doc(currentUser!.uid)
        .collection("previousMatchesList")
        .where("isLiked", isNull: true)
        .get();
    for (var item in previousMatchesRef.docs) {
      DocumentSnapshot<Map<String, dynamic>> okunanUser =
          await FirebaseFirestore.instance.doc("users/${item["uid"]}").get();
      Map<String, dynamic>? okunanUserbilgileriMap = okunanUser.data();
      UserModel okunanUserBilgileriNesne =
          UserModel.fromMap(okunanUserbilgileriMap!);
      print(okunanUserBilgileriNesne.toString());

      usersList.add(okunanUserBilgileriNesne);
    }
    return usersList;
  }

  getTheMutualSongViaUIdOfTheMatch(uid) async {
    // Ortak bir şey dinlediğimiz kişilerle hangi şarkıda eşleştiğimizi ve metadatasini döndüren metod.
    Map<String, dynamic> mutualSongData = {};
    List tumEslesmelerinParcalari = [];
    final previousMatchesRef = await _instance
        .collection("matches")
        .doc(currentUser!.uid)
        .collection("previousMatchesList")
        .orderBy("timeStamp", descending: false)
        .get();
    for (var item in previousMatchesRef.docs) {
      if (uid == item["uid"]) {
        mutualSongData["titleOfTheSong"] = item["titleOfTheSong"];
        mutualSongData["spotifyUri"] = item["spotifyUri"];
        mutualSongData["image"] = item["image"];
      }
      print(
          "Tüm eşleşmelerin olduğu kişilerin Şarkıları: ${tumEslesmelerinParcalari}");
    }
    return mutualSongData;
  }

  returnCurrentlyListeningMusicName() async {
    try {
      var isActive = false;
      var songName;
      isActive = await SpotifySdk.isSpotifyAppActive;

      var _name = SpotifySdk.subscribePlayerState();

      _name.listen((event) async {
        print("*****************************************************");
        songName = event.track!.name;
      });
      return songName.toString();
    } catch (e) {
      print("Spotify is not active or disconnected: $e");
    }
  }

  Future<List<UserModel>> getLikedPeople() async {
    List<UserModel> likedPeople = [];

    // Get liked people from quickMatchesList
    final quickMatchesRef = await _instance
        .collection("matches")
        .doc(currentUser!.uid)
        .collection("quickMatchesList")
        .where("isLiked", isEqualTo: true)
        .get();

    // Get liked people from previousMatchesList
    final previousMatchesRef = await _instance
        .collection("matches")
        .doc(currentUser!.uid)
        .collection("previousMatchesList")
        .where("isLiked", isEqualTo: true)
        .get();

    // Process quickMatchesList
    for (var item in quickMatchesRef.docs) {
      UserModel userModel = await getUserDataForDetailPage(item["uid"]);
      // Check if user with this ID already exists in the set
      if (!likedPeople
          .any((existingUser) => existingUser.userId == userModel.userId)) {
        likedPeople.add(userModel);
      }
    }

    // Process previousMatchesList
    for (var item in previousMatchesRef.docs) {
      UserModel userModel = await getUserDataForDetailPage(item["uid"]);
      // Check if user with this ID already exists in the set
      if (!likedPeople
          .any((existingUser) => existingUser.userId == userModel.userId)) {
        likedPeople.add(userModel);
      }
    }

    return likedPeople;
  }

  Future<List<UserModel>> getPeopleWhoLikedMe() async {
    List<UserModel> peopleWhoLikedMe = [];

    // Get all users
    QuerySnapshot usersSnapshot = await _instance.collection("users").get();

    for (var userDoc in usersSnapshot.docs) {
      String userId = userDoc.id;

      // Check if this user has liked the current user in quickMatchesList
      DocumentSnapshot quickMatchDoc = await _instance
          .collection("matches")
          .doc(userId)
          .collection("quickMatchesList")
          .doc(currentUser!.uid)
          .get();

      // Check if this user has liked the current user in previousMatchesList
      DocumentSnapshot previousMatchDoc = await _instance
          .collection("matches")
          .doc(userId)
          .collection("previousMatchesList")
          .doc(currentUser!.uid)
          .get();

      if ((quickMatchDoc.exists && quickMatchDoc.get('isLiked') == true) ||
          (previousMatchDoc.exists &&
              previousMatchDoc.get('isLiked') == true)) {
        UserModel userModel = await getUserDataForDetailPage(userId);
        peopleWhoLikedMe.add(userModel);
      }
    }

    return peopleWhoLikedMe;
  }

  void updateActiveStatus() async {
    try {
      var isActive = await SpotifySdk.isSpotifyAppActive;

      if (isActive) {
        SpotifySdk.subscribePlayerState().listen(
          (playerState) {
            if (playerState?.track != null) {
              final isPlaying = playerState?.isPaused == false;
              final songName = playerState?.track?.name;
              final spotifyUri = playerState?.track?.uri;
              final image = playerState!.track!.imageUri.raw;

              print("*****************************************************");
              print("Song Name: $songName");
              print("Is Playing: $isPlaying");
              print("Spotify URI: $spotifyUri");
              print("Image of the album: $image");

              if (songName != null) {
                updateIsUserListening(isPlaying, songName);
                getUserDatasToMatch(
                    songName: songName,
                    amIListeningNow: isPlaying,
                    spotifyUri: spotifyUri,
                    image: image);
              }
            }
          },
          onError: (e) => print('Error in Spotify subscription: $e'),
        );
      }
    } catch (e) {
      print('Error checking Spotify status: $e');
    }
  }

  Future<void> updateUserProfileImages({
    required List<String> profilePhotos,
  }) async {
    await _fireStore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .update({
      'profilePhotos': profilePhotos,
    });
  }

  Future<void> updateUserInfo({
    required String name,
    required String biography,
    required String majorInfo,
    required String clinicLocation,
  }) async {
    await _fireStore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .update({
      'name': name,
      'biography': biography,
      'majorInfo': majorInfo,
      'clinicLocation': clinicLocation,
    });
  }

  Future<void> updateTopArtistsOrCreateIfDoesntExist(
      List<Artist> artists) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('No user is currently signed in');
    }

    List<Map<String, dynamic>> topArtists = artists.map((artist) {
      return {
        'name': artist.name,
        'id': artist.id,
        'popularity': artist.popularity,
        'genres': artist.genres,
        'imageUrl': artist.images.isNotEmpty ? artist.images[0].url : null,
      };
    }).toList();

    // Get reference to user document
    DocumentReference userRef =
        _fireStore.collection('users').doc(currentUser.uid);

    // Get current document
    DocumentSnapshot doc = await userRef.get();

    if (doc.exists) {
      // Merge with existing data
      await userRef.set({
        'topArtists': topArtists,
      }, SetOptions(merge: true));
    } else {
      // Create new document
      await userRef.set({
        'topArtists': topArtists,
      });
    }
  }

  Future<void> updateTopTracksOrCreateIfDoesntExist(
      List<SpotifyTrackFromSpotify> tracks) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('No user is currently signed in');
    }

    List<Map<String, dynamic>> topTracks = tracks.map((track) {
      return {
        'id': track.id,
        'name': track.name,
        'artists': track.artists
            .map((artist) => {
                  'id': artist.id,
                  'name': artist.name,
                  'href': artist.href,
                })
            .toList(),
        'album': {
          'id': track.album.id,
          'name': track.album.name,
          'images': track.album.images
              .map((image) => {
                    'height': image.height,
                    'url': image.url,
                    'width': image.width,
                  })
              .toList(),
        },
        'previewUrl': track.previewUrl,
      };
    }).toList();

    // Get reference to user document
    DocumentReference userRef =
        _fireStore.collection('users').doc(currentUser.uid);

    // Get current document
    DocumentSnapshot doc = await userRef.get();

    if (doc.exists) {
      // Merge with existing data
      await userRef.set({
        'topTracks': topTracks,
      }, SetOptions(merge: true));
    } else {
      // Create new document
      await userRef.set({
        'topTracks': topTracks,
      });
    }
  }

  Future<List<Map<String, dynamic>>?> getTopArtistsFromFirebase(String uid,
      {bool isForProfileScreen = false}) async {
    try {
      print("Fetching top artists for user from firebase: $uid");
      DocumentSnapshot docSnapshot =
          await _fireStore.collection('users').doc(uid).get();

      // First check if document exists and has data
      if (docSnapshot.exists && docSnapshot.data() != null) {
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

        // Then check if topArtists field exists and is not null
        if (data.containsKey('topArtists') && data['topArtists'] != null) {
          print('User has topArtists field confirmed.');
          // Filter out null values and ensure correct type casting
          var topArtists = List<Map<String, dynamic>>.from(
              (data['topArtists'] as List)
                  .where((item) => item != null)
                  .map((item) => item as Map<String, dynamic>));
          print("Top artists found: ${topArtists.length}");
          return topArtists;
        } else if (!isForProfileScreen) {
          print("User document does not exist from firebase: $uid");
          print("No top artists found for user: $uid");
          print(
              "Attempting to fetch top artists from spotify to update or set the firebase top artists...");
          if (accessToken == null) {
            SpotifyServiceForTopArtists().fetchArtists();
          } else {
            print(
                'To fetch the top artists acessToken is required, attempting to obtain acces token and trying to fetch the top artists from spotify...');
            try {
              accessToken = await SpotifySdk.getAccessToken(
                  clientId: '32a50962636143748e6779e2f604e07b',
                  redirectUrl: 'com-developer-spotifyproject://callback',
                  scope: 'app-remote-control '
                      'user-modify-playback-state '
                      'playlist-read-private '
                      'user-library-read '
                      'playlist-modify-public '
                      'user-read-currently-playing '
                      'user-top-read');
              // Update token in Firebase
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('tokens')
                  .doc('spotify')
                  .set({
                'tokens': accessToken,
                'lastUpdated': DateTime.now(),
              }).then((value) {
                SpotifyServiceForTopArtists().fetchArtists();
              });
            } catch (e) {}
          }
        }
      }
    } catch (e) {
      print('Error fetching top artists: $e');
      return null;
    }
  }

  Future<List<SpotifyTrackFromSpotify>?> getTopTracksFromFirebase(String uid,
      {bool isForProfileScreen = false}) async {
    try {
      print("Fetching top tracks for user from firebase: $uid");
      DocumentSnapshot docSnapshot =
          await _fireStore.collection('users').doc(uid).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

        if (data.containsKey('topTracks') && data['topTracks'] != null) {
          print('User has topTracks field confirmed.');
          var tracksData = List<Map<String, dynamic>>.from(
              (data['topTracks'] as List)
                  .where((item) => item != null)
                  .map((item) => item as Map<String, dynamic>));

          return tracksData
              .map((track) => SpotifyTrackFromSpotify.fromJson(track))
              .toList();
        } else if (!isForProfileScreen) {
          print(
              "No top tracks found for user: $uid in firebase, we will try to fetch from the spotify...");
          getInitialTokens(
                  '32a50962636143748e6779e2f604e07b',
                  '72608d299ea045af87417092fc46c5fb',
                  'com-developer-spotifyproject://callback')
              .then((value) async {
            var tracks =
                await SpotifyServiceForTracks(accessToken).fetchTracks();
            await updateTopTracksOrCreateIfDoesntExist(tracks);
            return tracks;
          });
        }
      }
      return null;
    } catch (e) {
      print('Error fetching top tracks: $e');
      return null;
    }
  }

  List<String> prepareGenres(List<Map<String, dynamic>> artists) {
    // Print the number of artists being processed
    print("Preparing genres from ${artists.length} artists");

    Set<String> uniqueGenres = {};

    // Process only the first 4 artists
    for (var artist in artists.take(4)) {
      if (artist['genres'] != null && artist['genres'] is List) {
        // Print debug information for each artist
        print("Artist: ${artist['name']}, Genres: ${artist['genres']}");

        // Add all genres from this artist to the set
        uniqueGenres.addAll((artist['genres'] as List).cast<String>());
      }
    }

    // Take only the first 8 unique genres
    var result = uniqueGenres.take(8).toList();

    // Print the final list of prepared genres
    print("Prepared genres: $result");

    return result;
  }

  // New methods for user preferences
  void updateAge(int age) {
    if (age < 18 || age > 100) {
      throw Exception('Age must be between 18 and 100');
    }
    _instance.collection("users").doc(currentUser!.uid).update({"age": age});
  }

  void updateGender(String gender) {
    if (!['male', 'female'].contains(gender.toLowerCase())) {
      throw Exception('Gender must be either male or female');
    }
    _instance
        .collection("users")
        .doc(currentUser!.uid)
        .update({"gender": gender.toLowerCase()});
  }

  void updateInterestedIn(List<String> interestedIn) {
    // Validate that all values are either 'male' or 'female'
    if (!interestedIn
        .every((gender) => ['male', 'female'].contains(gender.toLowerCase()))) {
      throw Exception('Invalid gender preference');
    }

    // Remove duplicates and convert to lowercase
    final cleanedList =
        interestedIn.map((e) => e.toLowerCase()).toSet().toList();

    _instance
        .collection("users")
        .doc(currentUser!.uid)
        .update({"interestedIn": cleanedList});
  }

  Future<void> updateUserPreferences({
    required int age,
    required String gender,
    required List<String> interestedIn,
  }) async {
    if (currentUser == null) {
      throw Exception('No user is currently signed in');
    }

    // Input validation
    if (age < 18 || age > 100) {
      throw Exception('Age must be between 18 and 100');
    }

    if (!['male', 'female'].contains(gender.toLowerCase())) {
      throw Exception('Gender must be either male or female');
    }

    // Validate and clean interested_in list
    final cleanedInterests = interestedIn
        .map((e) => e.toLowerCase())
        .where((e) => ['male', 'female'].contains(e))
        .toSet()
        .toList();

    if (cleanedInterests.isEmpty) {
      throw Exception('Must select at least one gender preference');
    }

    try {
      await _instance.collection("users").doc(currentUser!.uid).update({
        "age": age,
        "gender": gender.toLowerCase(),
        "interestedIn": cleanedInterests,
        "preferencesCompleted": true,
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user preferences: $e');
      throw Exception('Failed to update preferences');
    }
  }

  Future<bool> hasCompletedPreferences() async {
    try {
      final doc =
          await _instance.collection("users").doc(currentUser!.uid).get();
      return doc.data()?['preferencesCompleted'] ?? false;
    } catch (e) {
      print('Error checking preferences status: $e');
      return false;
    }
  }

// Helper method to batch update multiple preferences at once
  Future<void> updatePreferences({
    int? age,
    String? gender,
    List<String>? interestedIn,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (age != null) {
        if (age < 18 || age > 99) {
          throw Exception('Age must be between 18 and 99');
        }
        updates['age'] = age;
      }

      if (gender != null) {
        String normalizedGender = gender.toLowerCase();
        if (!['male', 'female'].contains(normalizedGender)) {
          throw Exception('Invalid gender value');
        }
        updates['gender'] = normalizedGender;
      }

      if (interestedIn != null) {
        List<String> normalizedInterests = interestedIn
            .map((e) => e.toLowerCase())
            .where((e) => ['male', 'female'].contains(e))
            .toList();

        if (normalizedInterests.isEmpty) {
          throw Exception(
              'At least one valid gender interest must be selected');
        }
        updates['interestedIn'] = normalizedInterests;
      }

      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await _instance
            .collection("users")
            .doc(currentUser!.uid)
            .update(updates);
        print("Preferences updated successfully");
      }
    } catch (e) {
      print("Error updating preferences: $e");
      throw Exception('Failed to update preferences: $e');
    }
  }

  Future<void> updatePaymentDuration() async {
    try {
      final subDoc = await _fireStore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('subscription')
          .doc('status')
          .get();

      if (!subDoc.exists) {
        // First time premium purchase
        await _fireStore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('subscription')
            .doc('status')
            .set({
          'endDate':
              DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'isActive': true
        });
      } else {
        // Extend existing premium
        DateTime currentEndDate = DateTime.parse(subDoc.data()!['endDate']);
        DateTime newEndDate = currentEndDate.add(Duration(days: 30));

        await _fireStore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('subscription')
            .doc('status')
            .update(
                {'endDate': newEndDate.toIso8601String(), 'isActive': true});
      }
    } catch (e) {
      print('Error updating subscription: $e');
      throw Exception('Failed to update subscription');
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getProfileData() {
    return _instance.collection("users").doc(currentUser!.uid).snapshots();
  }

  // Add this function to your authentication service
  Future<void> saveUserFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Get FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();

      // Save it to user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': fcmToken,
      });
    }
  }

// Call this when user logs in or app starts
  void initializeNotifications() async {
    // Request permission
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  List<String> prepareGenresForProfiles(List<dynamic>? topArtistsOfTheUser) {
    if (topArtistsOfTheUser == null) return [];

    Set<String> uniqueGenres = {};
    for (var artist in topArtistsOfTheUser) {
      if (artist['genres'] != null) {
        uniqueGenres.addAll((artist['genres'] as List).cast<String>());
      }
    }

    return uniqueGenres.toList()..sort();
  }

  Future<Map<String, dynamic>?> getCommonSongInfoBasedOnUid(String uid) async {
    try {
      var matchDoc = await _instance
          .collection("matches")
          .doc(currentUser!.uid)
          .collection("previousMatchesList")
          .doc(uid)
          .get();

      if (matchDoc.exists) {
        return {
          'titleOfTheSong': matchDoc.data()?['titleOfTheSong'] ?? '',
          'image': matchDoc.data()?['image'] ?? '',
        };
      }
      return null;
    } catch (e) {
      print('Error getting song details: $e');
      return null;
    }
  }

  ImageUri convertSpotifyStringToImageUri(String spotifyUriString) {
    // Remove the 'spotify:image:' prefix if it exists
    final cleanUri = spotifyUriString.replaceFirst('spotify:image:', '');
    return ImageUri(cleanUri);
  }

  String getSpotifyImageUrl(String spotifyImageId) {
    // Remove any prefixes if they exist
    final cleanId = spotifyImageId.replaceFirst('spotify:image:', '');

    // Construct the full Spotify CDN URL
    return 'https://i.scdn.co/image/$cleanId';
  }

  Future<bool> getIfSheLikedMeInQuickMatchScreen(String userId) async {
    try {
      var quickMatchDoc = await _instance
          .collection("matches")
          .doc(userId)
          .collection("quickMatchesList")
          .doc(currentUser!.uid)
          .get();

      if (quickMatchDoc.exists && quickMatchDoc.data()?['isLiked'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking if user liked me: $e');
      return false;
    }
  }

  Future<String?> getSpotifyAccessTokenFromFirestore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('No user is currently signed in');
    }

    try {
      final docSnapshot = await _instance
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc('spotify')
          .get();

      if (docSnapshot.exists) {
        final token = docSnapshot.data()?['tokens'] as String?;
        if (token != null) {
          print('Spotify access token retrieved from Firestore: $token');
          return token;
        }
      } else {
        print('Spotify token document does not exist for user: $userId');
      }
    } catch (e) {
      print('Error fetching Spotify access token: $e');
    }

    throw Exception('Failed to retrieve Spotify access token');
  }

  Future<String> refreshSpotifyToken({
    required String clientId,
    required String clientSecret,
    required String existingRefreshToken,
  }) async {
    try {
      // Create base64 encoded auth string in correct format
      final authString = base64.encode(utf8.encode('$clientId:$clientSecret'));

      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic $authString',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': existingRefreshToken,
          // Removed client_id and client_secret from body
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final tokenResponse =
            SpotifyTokenResponse.fromJson(jsonDecode(response.body));
        return tokenResponse.accessToken;
      } else {
        return existingRefreshToken;
        throw Exception('Failed to refresh token: ${response.statusCode}');
      }
    } catch (e) {
      return existingRefreshToken;
      print('Exception during token refresh: $e');
      throw e;
    }
  }

  Future<List> getCommonSongsForProfileScreen(
      String userId1, String userId2) async {
    try {
      // Get savedTracks for first user
      final doc1 = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId1)
          .collection('spotify')
          .doc('savedTracks')
          .get();

      // Get savedTracks for second user
      final doc2 = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId2)
          .collection('spotify')
          .doc('savedTracks')
          .get();

      // If either user doesn't have saved tracks, return empty list
      if (!doc1.exists || !doc2.exists) {
        return [];
      }

      // Get tracks lists from documents
      final tracks1 = (doc1.data()?['tracks'] as List<dynamic>?) ?? [];
      final tracks2 = (doc2.data()?['tracks'] as List<dynamic>?) ?? [];

      // Create sets of URIs for efficient comparison
      final uris1 = tracks1.map((track) => track['uri'] as String).toSet();
      final uris2 = tracks2.map((track) => track['uri'] as String).toSet();

      // Find common URIs
      final commonUris = uris1.intersection(uris2);

      // Get full track data for common songs from first user's tracks
      // (since they're the same songs, we can take from either user)
      final commonSongs = tracks1
          .where((track) => commonUris.contains(track['uri']))
          .take(12)
          .toList();

      return commonSongs;
    } catch (e) {
      print('Error getting common songs: $e');
      return [];
    }
  }
}
