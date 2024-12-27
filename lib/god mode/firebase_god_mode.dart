import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:spotify_project/Business_Logic/Models/user_model.dart';

class MuseeAnalyticsAndGodMode extends StatefulWidget {
  @override
  _MuseeAnalyticsAndGodModeState createState() =>
      _MuseeAnalyticsAndGodModeState();
}

class _MuseeAnalyticsAndGodModeState extends State<MuseeAnalyticsAndGodMode> {
  int _userCount = 0;
  int _noUserIdCount = 0;
  int _emptyUserIdCount = 0;
  List<String> _noUserIdEmails = [];
  List<String> _noUserIdNoEmailDocIds = [];
  List<UserModel> _usersWithRecentTracks = [];

  @override
  void initState() {
    super.initState();
    _fetchUserCount();
    _fetchUsersWithRecentlySavedTracks();
  }

  Future<void> _fetchUserCount() async {
    try {
      final usersCollection = FirebaseFirestore.instance.collection('users');
      final userSnapshot = await usersCollection.get();

      int noUserId = 0;
      int emptyUserId = 0;
      List<String> noUserIdEmails = [];
      List<String> noUserIdNoEmailDocIds = [];

      for (var doc in userSnapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('userId')) {
          noUserId++;
          if (data.containsKey('email')) {
            noUserIdEmails.add(data['email']);
          } else {
            noUserIdNoEmailDocIds.add(doc.id);
          }
        } else if (data['userId'] == '') {
          emptyUserId++;
        }
      }

      setState(() {
        _userCount = userSnapshot.docs.length;
        _noUserIdCount = noUserId;
        _emptyUserIdCount = emptyUserId;
        _noUserIdEmails = noUserIdEmails;
        _noUserIdNoEmailDocIds = noUserIdNoEmailDocIds;
      });
    } catch (e) {
      print('Error fetching user count: $e');
    }
  }

  Future<void> _fetchUsersWithRecentlySavedTracks() async {
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      List<UserModel> usersWithRecentTracks = [];

      for (var userDoc in usersSnapshot.docs) {
        String userId = userDoc.id;

        // Fetch the savedTracks document for each user
        DocumentSnapshot<Map<String, dynamic>> savedTracksDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('spotify')
                .doc('savedTracks')
                .get();

        if (savedTracksDoc.exists) {
          // Check if the user has recently saved tracks
          List<dynamic> tracks = savedTracksDoc.data()?['tracks'] ?? [];
          if (tracks.isNotEmpty) {
            // Add user to the list if they have saved tracks
            UserModel userModel =
                UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
            usersWithRecentTracks.add(userModel);
          }
        }
      }

      setState(() {
        _usersWithRecentTracks = usersWithRecentTracks;
      });
    } catch (e) {
      print('Error fetching users with recently saved tracks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debugging Screen'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUserCount,
        child: ListView(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Total Users: $_userCount',
                    style: TextStyle(fontSize: 24),
                  ),
                  Text(
                    'Users without userId: $_noUserIdCount',
                    style: TextStyle(fontSize: 24),
                  ),
                  Text(
                    'Users with empty userId: $_emptyUserIdCount',
                    style: TextStyle(fontSize: 24),
                  ),
                  if (_noUserIdEmails.isNotEmpty) ...[
                    SizedBox(height: 20),
                    Text(
                      'Emails of users without userId:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    for (var email in _noUserIdEmails)
                      Text(
                        email,
                        style: TextStyle(fontSize: 16),
                      ),
                  ],
                  if (_noUserIdNoEmailDocIds.isNotEmpty) ...[
                    SizedBox(height: 20),
                    Text(
                      'Doc IDs of users without userId and email:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    for (var docId in _noUserIdNoEmailDocIds)
                      Text(
                        docId,
                        style: TextStyle(fontSize: 16),
                      ),
                  ],
                  if (_usersWithRecentTracks.isNotEmpty) ...[
                    SizedBox(height: 20),
                    Text(
                      'Users with Recently Saved Tracks:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    for (var user in _usersWithRecentTracks)
                      Text(
                        user.name.toString(),
                        style: TextStyle(fontSize: 16),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
